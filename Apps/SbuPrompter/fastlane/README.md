fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### create_app

```sh
[bundle exec] fastlane create_app
```

Register the bundle ID and create the App Store Connect record for macOS and iOS, Italian primary language

### metadata

```sh
[bundle exec] fastlane metadata
```

Upload only the metadata (no build, no screenshots) to the macOS and iOS listings, without submitting

### screenshots

```sh
[bundle exec] fastlane screenshots
```

Upload the framed screenshots: screenshots/ to iOS, screenshots-mac/ to macOS, without submitting

### upload

```sh
[bundle exec] fastlane upload
```

Build the Mac app and the iPhone remote and upload both to App Store Connect, without submitting

Only one: fastlane upload platform:osx (or ios)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
