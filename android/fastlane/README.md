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

### android build

```sh
[bundle exec] fastlane android build
```

Build and deploy Android app with environment configuration

### android dev

```sh
[bundle exec] fastlane android dev
```

Build development version

### android staging

```sh
[bundle exec] fastlane android staging
```

Build staging version

### android prod

```sh
[bundle exec] fastlane android prod
```

Build production version

### android test

```sh
[bundle exec] fastlane android test
```

Run tests

### android clean

```sh
[bundle exec] fastlane android clean
```

Clean build artifacts

### android validate_config

```sh
[bundle exec] fastlane android validate_config
```

Validate environment configuration

### android validate_certificates

```sh
[bundle exec] fastlane android validate_certificates
```

Validate signing certificates

### android validate_all_certificates

```sh
[bundle exec] fastlane android validate_all_certificates
```

Validate all environment certificates

### android setup_credentials

```sh
[bundle exec] fastlane android setup_credentials
```

Setup signing credentials

### android load_credentials

```sh
[bundle exec] fastlane android load_credentials
```

Load credentials from file

### android generate_debug_keystore

```sh
[bundle exec] fastlane android generate_debug_keystore
```

Generate debug keystore

### android audit_signing

```sh
[bundle exec] fastlane android audit_signing
```

Audit signing access

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
