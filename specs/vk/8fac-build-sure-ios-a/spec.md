# Feature Specification: Sure iOS TestFlight Release

**Feature dir**: `specs/vk/8fac-build-sure-ios-a/`
**Status**: Draft

## Summary

Enable maintainers to release the existing Sure mobile application to TestFlight
through a dependable repository workflow. The release must be honest about whether
an upload occurred, protect Apple credentials, support both manual and coordinated
mobile releases, and provide enough evidence for an operator to verify the build.

## User Stories

- As a Sure maintainer, I want to start an iOS beta release manually so that I can
  distribute a selected version to TestFlight without building on a local Mac.
- As a release maintainer, I want coordinated mobile releases to upload the same
  selected version to TestFlight so that Android, GitHub, and iOS distribution use
  one release intent.
- As an operator, I want missing or invalid release configuration to fail clearly
  before the expensive build so that a green workflow never implies an upload that
  did not happen.
- As a security owner, I want signing and App Store credentials to remain secret
  and ephemeral so that beta distribution does not weaken release security.
- As a maintainer diagnosing a release, I want a retained IPA and clear workflow
  evidence so that I can distinguish build, signing, export, upload, and App Store
  processing failures.

## Functional Requirements

- FR-1: The release system must support an operator-initiated iOS beta release and
  require the operator to supply its marketing version explicitly.
- FR-2: The release system must support invocation by the coordinated mobile
  release and accept its selected release version.
- FR-3: Every release must use a valid iOS marketing version and a unique,
  monotonically usable build number.
- FR-4: Before allocating a macOS build, the system must validate that every
  required signing and App Store Connect value is present and non-empty.
- FR-5: A missing required value must fail the named TestFlight release with a list
  of missing configuration names; it must not produce a successful skipped release.
- FR-6: A configured release must produce a signed, App Store-distribution IPA for
  the repository-configured application identity, defaulting to `am.sure.mobile`
  when no repository variable overrides it.
- FR-7: A configured release must upload that IPA to App Store Connect using
  non-interactive authentication suitable for CI.
- FR-8: A successful upload must retain the exact IPA as a workflow artifact and
  expose an explicit successful upload state in the workflow.
- FR-9: Credentials and signing assets must not be committed, printed, or retained
  beyond the release job's temporary storage.
- FR-10: Cleanup of temporary key material must run after both successful and failed
  release attempts.
- FR-11: Operator documentation must define prerequisites, configuration names,
  trigger procedures, success evidence, and diagnosis for common failures.
- FR-12: The release contract must have automated checks that do not require Apple
  credentials wherever the behavior can be verified statically.

## Out of Scope

- Creating or purchasing an Apple Developer membership.
- Creating an App Store Connect application record or accepting Apple agreements.
- Generating private certificates, profiles, or API keys without owner-provided
  Apple access.
- Automatically adding external testers or bypassing App Store beta review.
- Redesigning Sure mobile features or changing Rails API behavior.
- Guaranteeing Apple's processing time after a successful upload.

## Acceptance Criteria

- [ ] A manual invocation with complete valid configuration builds, signs, exports,
  and uploads a Sure IPA, and retains that IPA as an artifact.
- [ ] A coordinated mobile release invokes the same release contract with the
  selected version.
- [ ] An invocation missing any required credential fails before a macOS runner is
  allocated and identifies all missing configuration names.
- [ ] Workflow checks reject empty/invalid version input before build work begins.
- [ ] Logs and committed files contain no private signing or App Store key material.
- [ ] Cleanup is configured to run regardless of build/upload outcome.
- [ ] Documentation matches the executable trigger and configuration contract.
- [ ] Credential-independent tests cover the critical workflow contract and pass.
- [ ] Repository-required checks and independent review report no significant
  issues before merge.
- [ ] After merge and credential configuration, the GitHub release run shows a
  successful upload and the build appears in App Store Connect for processing.

## Clarifications

- Manual releases require an explicit marketing version. The checked-in Flutter
  version is a development placeholder, and silently deriving from an arbitrary
  branch would make the distributed version ambiguous.
- The bundle identifier remains repository-configurable through the existing
  release variable, with `am.sure.mobile` as the documented default. This preserves
  current self-host/fork flexibility without weakening the primary identity.
- A coordinated mobile release fails when its TestFlight distribution cannot run.
  Android or GitHub artifacts may still complete independently, but the overall
  release must not be green when one of its named distribution targets was omitted.

## Open Questions

None.
