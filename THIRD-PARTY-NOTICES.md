# Third-party notices

This repository previously vendored a compiled third-party library directly in
`CustomSearchJSON/code/`. It no longer does. Everything the sketches need at
runtime is now resolved from a declared version at build time.

## Removed: Gson 2.2.4 (vendored jar)

- Was: `CustomSearchJSON/code/gson-2.2.4.jar`, 190418 bytes,
  SHA-256 `08a99b852eafa908f76b1f4c8723c47c3399cbdc682ba9106a7556f1c06bf167`
- Published: 2014, and the 2.2.x line is no longer maintained.
- Why it was removed:
  - a binary in the repository cannot be audited by review, cannot be checked
    against a published checksum by tooling, and cannot be rebuilt;
  - there was no provenance: no POM, no signature, and no record of where the
    jar came from;
  - it is superseded.

The replacement version is pinned in `pom.xml` and copied into the sketch's
`code/` folder by the `package` phase.

## Current runtime dependencies

| Component | Version | License | Scope |
| --- | --- | --- | --- |
| [Gson](https://github.com/google/gson) | 2.11.0 | Apache-2.0 | `CustomSearchJSON` only |

Resolved from Maven Central. Verify the artifact before you trust it; the
checksums Maven records in `~/.m2/repository` are the authoritative ones.

## Build-time dependencies

Declared in `pom.xml` with exact versions:

| Component | Version | License | Scope |
| --- | --- | --- | --- |
| JUnit Jupiter | 5.10.2 | EPL-2.0 | test only |

## Libraries the sketches need from the IDE

The sketches that reach for hardware, audio, camera or physics import libraries
that are installed through the Processing IDE (Sketch > Add Library), not
through this build:

- Minim (audio analysis)
- Peasy (camera control)
- oscP5 / netP5 (OSC)
- Traer Physics (InteractiveWords)

None of those are used by `core`, so nothing in this repository depends on them
at build time. Processing's bundled `serial`, `video` and `sound` packages are
part of Processing itself and carry its licence.

## Licenses

- Processing (the sketches and the core library): LGPL-2.1
- Checkstyle (build-time lint only): LGPL-2.1
- Maven and the plugins used at build time: Apache-2.0