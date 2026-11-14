# Research: Sure iOS TestFlight Release

## Existing path

The repository already has a complete conceptual path: Flutter dependencies and
icons, CocoaPods, temporary keychain/certificate import, provisioning-profile
installation, Xcode archive/export, App Store Connect upload, artifact retention,
and cleanup. Replacing it with Fastlane or another dependency would add operational
surface without solving the observed truthfulness/configuration defect.

## Decisions

### Validate before macOS allocation

GitHub makes reusable-workflow secrets available to jobs. A Linux preflight can
check presence without printing values. Failing there is faster and cheaper than
starting macOS, and makes the workflow conclusion accurate.

### Require explicit version for manual releases

`mobile/pubspec.yaml` intentionally contains `0.0.0-dev+0`. Falling back to it is
not a valid distribution contract. Tag and reusable callers already carry release
intent; manual dispatch should do so explicitly.

### Preserve configurable bundle identifier

The existing `IOS_APP_BUNDLE_ID` repository variable supports forks while the
default preserves Sure's primary identifier. It belongs in preflight output so all
downstream signing/export steps use one normalized value.

### No new release dependency

Native `security`, `xcodebuild`, and App Store Connect tooling are already present
on the selected runner. Adding Fastlane would introduce Ruby/plugin maintenance and
credential behavior without a demonstrated need.

### Static contract test plus credentialed end-to-end proof

Linux tests can verify triggers, validation, secret names, failure semantics,
cleanup, artifact retention, and upload command wiring. Only a credentialed macOS
run can prove Apple signing/export/upload; the two layers are complementary.

## Alternatives rejected

- Keep silent skip: contradicts the workflow name and makes successful releases
  misleading.
- Commit signing assets: violates repository security rules.
- Build locally and upload manually: not reproducible and cannot satisfy the
  requested repository release/PR workflow.
- Generate credentials automatically: impossible without Apple account authority
  and inappropriate for repository code.
