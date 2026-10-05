# Security Policy

## Reporting a vulnerability

Please report suspected vulnerabilities privately. Do not open a public issue
for anything exploitable.

- Email: security@precog.security
- Encrypt the report if you prefer; request the key in your first message.

Include the sketch or module, the reproduction steps, and the impact you
believe it has. We aim to acknowledge within two business days and to send a
remediation plan within ten.

There is no bug bounty programme for this repository.

## Supported versions

The `.pde` sketches are demonstrations and receive best-effort fixes. The
`core` library is the part the CI pipeline builds and tests, and is what any
downstream code should depend on.

## Threat model

What is in scope:

- `core/`, which processes untrusted input from third-party HTTP responses.
- `CustomSearchJSON/`, which calls the Google Custom Search API, downloads
  whatever images that API points at, and persists the results to `data/*.xml`.

What is explicitly out of scope: the sketches that only read files from their
own `data/` folder or render local assets.

## Known issue: rotate the committed API key

**Action required from the repository owner. This cannot be fixed by a code
change.**

`CustomSearchJSON/Search.pde` contained a live Google Custom Search API key in
a commented-out URL. It was committed on 2015-06-23 in commit `248fda5` and is
therefore still in the git history, and it was also visible in a public
repository, which means it should be treated as public.

A comment is not a secret store. Git keeps it, forks keep it, and anyone who
clones the repository has it.

The literal has been removed from the working tree and the value is now read
from `GOOGLE_CUSTOM_SEARCH_API_KEY` (see `.env.example`). That stops the leak
from spreading; it does not invalidate the credential.

Do the following:

1. **Revoke the key now**, in the Google Cloud console: APIs and Services >
   Credentials > select the key > Delete. Do this before anything else.
2. Create a replacement key, restrict it to the Custom Search API, and
   restrict it to your own IP ranges if you can.
3. Export it as `GOOGLE_CUSTOM_SEARCH_API_KEY`; never commit it.
4. Optionally scrub the blob from the history so that cloning the repository no
   longer yields a usable string:

   ```sh
   # Back up the repository first and coordinate the rewrite with anyone who
   # has a clone; this rewrites every commit SHA.
   git filter-repo --sensitive-data-removal --invert-paths
   git push --force --all
   git push --force --tags
   ```

   History rewriting is destructive and changes every commit hash. It is a
   decision for the repository owner, not for a contributor.

5. Once the key is revoked and the history is scrubbed, tighten
   `.gitleaks.toml`: remove the allowlist entry for commit `248fda5` and switch
   the history scan in `.github/workflows/ci.yml` from
   `continue-on-error: true` to a required step.

Step 1 is the one that actually removes the exposure. Steps 4 and 5 are hygiene.

## What is enforced in CI

`.github/workflows/ci.yml` fails the build when any of the following fails:

- `mvn verify`: compiles `core`, runs the JUnit 5 suite, and fails on any
  Checkstyle violation (`checkstyle.xml`, wired into the `verify` phase).
- Maven Enforcer: requires Java 17+ and Maven 3.8.6+, and fails if a transitive
  dependency outranks a pinned version.
- Secret scan of the working tree: high-confidence credential patterns, so a
  re-introduced key cannot be committed.

Dependency versions are pinned exactly in `pom.xml`. Do not add a version range
or a `SNAPSHOT`.

## Handling credentials in this repository

- Credentials come from the environment. Never from source, never from a
  committed `.env`.
- `SafeLog` masks credential-shaped strings before anything is printed, so a
  URL that still contains a key cannot leak through the console.
- `SearchQuery.toString()` returns a redacted URL. Use `toUrl()` only where the
  credential must actually go on the wire.