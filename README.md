# Processing-Sketch

A collection of Processing sketches, and the plain-Java core that carries the
logic worth testing.

The sketches are demonstrations: audio analysis, GLSL shaders, OSC control, a
serial graph. They run in the Processing IDE. What runs in CI is `core/`, the
module that holds the security-relevant logic — untrusted HTTP input, remote
filenames, XML parsing — extracted from those sketches so that it can be unit
tested without a display.

---

## What this repository is for

Reading the history of this repository, the pattern is a set of working
demonstrations rather than a library. This build makes the parts that touch
untrusted input verifiable and makes a fresh clone reproducible:

| Area | Before | Now |
| --- | --- | --- |
| Credentials | A live Google API key committed in `Search.pde` | Read from the environment; masked in all logs |
| Remote filenames | Last URL segment written straight under `data/` | Sanitized; a canonical-path check fails closed |
| Outbound HTTP | No timeouts, no status check, leaked sockets | HTTPS enforced, both timeouts set, size-capped, redirects re-validated |
| Query building | Raw string concatenation | Percent-encoded, validated, clamped |
| XML parsing | Parser defaults | DOCTYPE, external entities and XInclude disabled |
| Error handling | `println`, `catch (Error)` | Structured, redacted logging; typed exceptions |
| Tests | None | JUnit 5, run on every push |
| CI | None | Build, test, lint, secret scan |

---

## Prerequisites

| Tool | Version | Why |
| --- | --- | --- |
| JDK | 17 or newer | Processing 4.x runs on 17; `core` targets 17 |
| Maven | 3.8.6 or newer (CI pins 3.9.9) | Builds and tests `core` |
| Processing IDE | 4.x | Runs the `.pde` sketches |

Check:

```sh
java -version
mvn -version
```

Maven Enforcer fails the build if the JDK or Maven is too old rather than
emitting a confusing compile error.

---

## Install

```sh
git clone https://github.com/PreCogSecurity/Processing-Sketch.git
cd Processing-Sketch
mvn -B package
```

That single command is the whole install. It compiles `core`, runs the test
suite, and stages the sketch libraries into `CustomSearchJSON/code/`, which is
where Processing looks for them:

```
CustomSearchJSON/code/processing-sketch-core-1.0.0.jar
CustomSearchJSON/code/gson-2.11.0.jar
```

`CustomSearchJSON/code/` is generated and git-ignored. It is not checked in.

### Reproducibility

There is no lockfile, deliberately. Maven resolves transitive dependencies by
coordinate, and every dependency and plugin version in `pom.xml` is pinned to an
exact release with no ranges and no `SNAPSHOT`s. `requireUpperBoundDeps` in the
Enforcer rules fails the build if the resolved tree ever outranks what is
declared, so a build either resolves to exactly what the `pom` says or it fails.
That is the property a lockfile provides, enforced rather than recorded.

CI additionally pins the JDK and the Maven version, so a rerun of the same
commit resolves byte-identical artifacts.

### Dependencies

| Component | Version | Used by | Scope |
| --- | --- | --- | --- |
| Gson | 2.11.0 | `CustomSearchJSON` | runtime |
| JUnit Jupiter | 5.10.2 | tests | test |

`CustomSearchJSON` previously vendored `gson-2.2.4.jar`, a 2014 build, directly
in the repository. It has been removed. See [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

---

## Test

```sh
mvn -B test
```

Runs the JUnit 5 suite in `core`. Every test is offline and needs no display, no
API key and no hardware. The suite is deliberately adversarial: it asserts the
path-traversal, XXE, parameter-injection and credential-leak behaviours stay
fixed, and it also asserts that ordinary documents and ordinary filenames still
work, so a hardening change cannot quietly break the application.

To run one class or one method:

```sh
mvn -B test -Dtest=XmlPolicyTest
mvn -B test -Dtest=SafePathTest#defeatsPercentEncodedTraversal
```

### Lint

```sh
mvn -B checkstyle:check
```

Style is enforced by [checkstyle.xml](checkstyle.xml), which runs in the
`verify` phase and fails the build on any violation. It covers
`core/src/main/java`; the `.pde` sketches are compiled by the Processing IDE and
are outside what a Maven linter can see.

---

## Run a sketch

1. Open the Processing IDE.
2. `File > Open`, and select the sketch folder — the one containing the
   `.pde` file whose name matches the folder.
3. Press Run.

### `CustomSearchJSON`

The only sketch that needs configuration. It calls the Google Custom Search
JSON API, downloads the images it returns, and writes an index to `data/`.

It needs two environment variables, and it refuses to start without them:

```sh
export GOOGLE_CUSTOM_SEARCH_API_KEY=...    # or the PowerShell equivalent
export GOOGLE_CUSTOM_SEARCH_ENGINE_ID=...
```

See [.env.example](.env.example) for a template and for the PowerShell and shell
incantations.

Controls:

| Key | Action |
| --- | --- |
| `a` / `s` | Previous / next image on the current page |
| `m` | Print the persisted search cursor |
| `n` | Move the persisted cursor to a random valid page |

This sketch is also the one that holds the credentials. A Google API key was
committed to this repository in 2015 and is still in the git history. If you own
this repository, **revoke that key** — see [SECURITY.md](SECURITY.md). Removing
the string from the file did not invalidate it.

### `GraphArduino`

Needs an Arduino on a serial port. If no device is found the sketch says so and
keeps its window open instead of throwing.

| Variable | Purpose |
| --- | --- |
| `ARDUINO_PORT` | Device to open, e.g. `COM3` or `/dev/ttyUSB0`. Blank uses the first device found. |

### Library requirements for the media sketches

Several sketches import libraries that are installed through the IDE
(Sketch > Add Library), not through Maven. None of them affect the build or the
tests:

| Sketch | Library |
| --- | --- |
| `audioAnalyzerFFT`, `audioAnalyzerHrz`, `audioAnalyzerMIDI` | Minim |
| `GLSLDisplacement` | Peasy |
| `Graphs`, `GraphsTimeline` | oscP5 (netP5) |
| `InteractiveWords` | Traer Physics |
| `GraphArduino` | Serial (bundled) |
| `Glitch` | Video (bundled) |

`Graphs` and `GraphsTimeline` ship their own slider and graph components, so
they need no ControlP5.

---

## Sketch catalogue

| Sketch | What it demonstrates |
| --- | --- |
| `audioAnalyzerAudios` | Audio folder sample files; the main `.pde` is currently empty, the samples are the point |
| `audioAnalyzerFFT` | FFT analysis of a playing file, waveform and spectrum |
| `audioAnalyzerHrz` | Pitch detection over time, plus sample triggering |
| `audioAnalyzerMIDI` | Mapping analysis output to MIDI note numbers |
| `CustomSearchJSON` | Custom Search API client: paginated HTTPS with timeouts, size-capped image download, XML index persistence |
| `DisplacemetMap` | Displacement mapping with custom GLSL vertex and fragment shaders |
| `GLSLDisplacement` | Shader-based displacement over a particle sphere and torus |
| `Glitch` | Glitch effect driven by a live camera capture |
| `GraphArduino` | Live graph of values arriving over a serial port |
| `Graphs` | Hand-rolled slider and bar graph components, driven by OSC |
| `GraphsTimeline` | Timeline and bar graph components, driven by OSC |
| `InteractiveWords` | Verlet-simulated word cloth driven from a word list |
| `MultiJFrameRender` | An offscreen `PGraphics` rendered into a separate window |
| `SecondWindowTransparent` | A second, transparent window |
| `TimerEvent` | Timer events on a background schedule |
| `TransparentWindow` | A transparent, undecorated main window |

---

## Repository layout

```
core/                                  plain-Java core, built and tested by Maven
  pom.xml
  src/main/java/com/precog/processing/core/
    SafePath.java                      untrusted remote name -> safe local file name
    SearchQuery.java                   validated, encoded API request; redacts toString
    SearchResults.java                 bounds-safe view over one result page
    SecureFetch.java                   HTTPS enforcement, timeouts, redirect and size limits
    SafeLog.java                       structured, redacting logger
    XmlPolicy.java                     XML parsers with entity resolution disabled
  src/test/java/...                    JUnit 5 suite
checkstyle.xml                         lint configuration, enforced in CI
pom.xml                                aggregator; every version pinned
.github/workflows/ci.yml               build, test, lint, secret scan
.gitleaks.toml                         secret-scan policy, with the one known finding
.env.example                           required environment variables
SECURITY.md                            vulnerability reporting, and the rotation to-do
THIRD-PARTY-NOTICES.md                 dependency inventory and licences
```

---

## Contributing

- One change per commit, with the test that proves it in the same commit. The
  commit history is the product a buyer reads; a bulk reformat hides the real
  work.
- A change that touches `core` needs a test that fails without it.
- `mvn -B verify` must pass before you push.
- Do not commit a credential, not even a placeholder that looks real. CI fails
  the build if you do. `.env.example` is the place to name a variable.
- Do not add a dependency version range or a `SNAPSHOT`.

## License

LGPL-2.1, matching Processing. See [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).