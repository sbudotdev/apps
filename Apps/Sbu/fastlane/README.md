fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios internal_testers

```sh
[bundle exec] fastlane ios internal_testers
```

Internal TestFlight group with every build, with SBU_TESTER_EMAIL (default matteogiuditta@gmail.com) in it

### ios test

```sh
[bundle exec] fastlane ios test
```

Unit and UI tests on the simulator

### ios create_app

```sh
[bundle exec] fastlane ios create_app
```

Register the bundle ID and create the App Store Connect record, Italian primary language

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload to TestFlight, internal group only

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
