fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android internal

```sh
[bundle exec] fastlane android internal
```

Build AAB + upload to Play Store internal testing (bumps build number)

### android production

```sh
[bundle exec] fastlane android production
```

Build AAB + upload to Play Store production (bumps build number)

### android upload_only

```sh
[bundle exec] fastlane android upload_only
```

Upload existing AAB to Play Store (no build, no bump) — for re-uploads

----


## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build IPA + upload to TestFlight (bumps build number)

### ios store

```sh
[bundle exec] fastlane ios store
```

Build IPA + upload to App Store (bumps build number, does not submit)

### ios upload_only

```sh
[bundle exec] fastlane ios upload_only
```

Upload existing IPA to TestFlight (no build, no bump) — for re-uploads

### ios meta

```sh
[bundle exec] fastlane ios meta
```

Upload metadata only to App Store (no binary, no screenshots)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
