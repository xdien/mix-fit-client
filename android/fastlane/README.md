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

### android increment_build

```sh
[bundle exec] fastlane android increment_build
```

Increment build number

### android update_version

```sh
[bundle exec] fastlane android update_version
```

Update version name

### android increment_patch

```sh
[bundle exec] fastlane android increment_patch
```

Increment patch version

### android increment_minor

```sh
[bundle exec] fastlane android increment_minor
```

Increment minor version

### android increment_major

```sh
[bundle exec] fastlane android increment_major
```

Increment major version

### android create_tag

```sh
[bundle exec] fastlane android create_tag
```

Create Git tag for current version

### android show_version

```sh
[bundle exec] fastlane android show_version
```

Show current version information

### android version_history

```sh
[bundle exec] fastlane android version_history
```

Show version history

### android version_stats

```sh
[bundle exec] fastlane android version_stats
```

Show version statistics

### android generate_changelog

```sh
[bundle exec] fastlane android generate_changelog
```

Generate changelog from version history

### android export_version_history

```sh
[bundle exec] fastlane android export_version_history
```

Export version history

### android cleanup_version_history

```sh
[bundle exec] fastlane android cleanup_version_history
```

Clean up old version history

### android encrypt_credentials

```sh
[bundle exec] fastlane android encrypt_credentials
```

Encrypt credentials file

### android decrypt_credentials

```sh
[bundle exec] fastlane android decrypt_credentials
```

Decrypt credentials file

### android validate_keystore

```sh
[bundle exec] fastlane android validate_keystore
```

Validate keystore integrity

### android security_report

```sh
[bundle exec] fastlane android security_report
```

Generate security report

### android comprehensive_cert_validation

```sh
[bundle exec] fastlane android comprehensive_cert_validation
```

Comprehensive certificate validation

### android setup_ci_credentials

```sh
[bundle exec] fastlane android setup_ci_credentials
```

Setup CI/CD credentials

### android list_builds

```sh
[bundle exec] fastlane android list_builds
```

List recent builds for environment

### android latest_build

```sh
[bundle exec] fastlane android latest_build
```

Show latest build information

### android cleanup_builds

```sh
[bundle exec] fastlane android cleanup_builds
```

Clean up old build artifacts

### android validate_artifacts

```sh
[bundle exec] fastlane android validate_artifacts
```

Validate build artifacts

### android artifact_report

```sh
[bundle exec] fastlane android artifact_report
```

Generate artifact report

### android security_audit

```sh
[bundle exec] fastlane android security_audit
```

Security audit for signing process

### android build_with_version

```sh
[bundle exec] fastlane android build_with_version
```

Build with version increment and tag creation

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
