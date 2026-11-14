# Technical Spec: Build Sure iOS App in TestFlight

Task ID: `8fac-build-sure-ios-a`

## Objective

Provide a reliable, auditable release path that produces a signed Sure iOS IPA
from the Flutter application and uploads it to App Store Connect/TestFlight. The
path must be usable manually and from the mobile release workflow, must not expose
signing material, and must fail clearly when a release cannot reach TestFlight.

## Existing System

- The Flutter application lives in `mobile/`, with its Xcode project in
  `mobile/ios/`.
- `.github/workflows/ios-testflight.yml` already contains signing, archiving, and
  App Store Connect upload steps.
- `.github/workflows/mobile-release.yml` calls the TestFlight workflow during a
  mobile release.
- Release documentation is in `mobile/docs/iOS_TESTFLIGHT.md`.
- The target repository currently exposes no Actions secrets through the GitHub
  API. Apple signing and App Store Connect credentials are therefore an external
  release prerequisite and cannot be manufactured or committed by this task.

## Required Behavior

1. A manual workflow run can select the ref/version to distribute and provide
   release notes.
2. A mobile release invokes the same reusable TestFlight path with a valid iOS
   marketing version and a unique build number.
3. The workflow validates all required signing and App Store Connect inputs before
   spending time on a macOS build.
4. Missing release credentials produce an explicit failed release, not a green run
   that silently omitted TestFlight.
5. The workflow installs Flutter dependencies and CocoaPods, generates app assets,
   archives with the configured bundle identifier/team/profile, exports an IPA,
   uploads it using App Store Connect API-key authentication, and retains the IPA
   as a workflow artifact.
6. Signing certificates, provisioning profiles, private keys, and passwords remain
   in GitHub Actions secrets and temporary runner files only; cleanup runs even
   after failure.
7. Documentation names the exact repository variables/secrets, trigger procedure,
   observable success state, and common failure modes.
8. Workflow structure and scripts have automated static tests where practical so
   regressions can be detected without Apple credentials or a macOS runner.

## Implementation Boundaries

- Keep the Flutter client and Rails API behavior unchanged unless validation
  reveals a build-blocking defect.
- Do not add signing assets or credentials to the repository.
- Do not create an App Store Connect application, Apple Developer identity, or
  provisioning profile on the user's behalf without those external credentials.
- Use the existing GitHub Actions release architecture and pinned actions.

## Validation

- Run workflow syntax/static contract tests and applicable mobile analysis/tests.
- Run repository-required pre-PR checks, recording environmental exceptions.
- Obtain an independent Codex review with no significant findings.
- Open and merge a PR after CI passes.
- After merge, dispatch the TestFlight workflow and verify that its upload step
  succeeds. If credentials remain unavailable, report that concrete external
  blocker rather than claiming a TestFlight build exists.

## Acceptance Criteria

- The merged default branch contains the validated TestFlight release path and
  accurate operator documentation.
- A credentialed run uploads a signed IPA and exposes a successful upload result
  and retained artifact.
- The resulting build becomes visible for processing in App Store Connect
  TestFlight; Apple's processing/review timing is external to this repository.
