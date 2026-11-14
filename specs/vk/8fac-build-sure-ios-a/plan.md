# Implementation Plan: Sure iOS TestFlight Release

**Spec**: `./spec.md`
**Status**: Ready for tasks

## Technical Context

- GitHub Actions YAML and Bash orchestrate the release.
- Flutter 3.32.4/Dart build the application in `mobile/`.
- Xcode 26 and CocoaPods build/archive the iOS target under `mobile/ios/`.
- App Store Connect API-key authentication performs a non-interactive upload.
- No application data model changes or Rails behavior changes are required.
- The repository has no configured Actions secrets visible at planning time, so
  credential-independent checks can validate structure while the final upload
  requires external Apple configuration.

## Architecture & Approach

1. Extract preflight validation into the Ubuntu `validate-release` job in
   `.github/workflows/ios-testflight.yml`. Validate event eligibility, explicit or
   tag-derived version, bundle identifier, and all required secrets there. Export
   normalized version/bundle values only after validation.
2. Make missing configuration a failing preflight with a useful step summary.
   This prevents macOS allocation and prevents a green no-op TestFlight release.
3. Keep signing, Flutter/CocoaPods setup, archive/export, App Store upload, artifact
   retention, and unconditional cleanup in the existing macOS job. Consume only
   the validated preflight outputs.
4. Replace fragile inline project mutation where practical with explicit build
   settings passed to Xcode. If project mutation remains necessary, constrain and
   test it.
5. Add a lightweight repository test under `test/` that parses the workflow as
   text/YAML-safe structure and enforces the critical release contract without
   requiring credentials or macOS.
6. Update `mobile/docs/iOS_TESTFLIGHT.md` and the mobile README so their trigger,
   configuration, failure, success, and verification instructions match the
   executable workflow.

## Data Model

See `./data-model.md`. This feature changes release metadata only, not persisted
application data.

## Contracts

See `./contracts/testflight-workflow.md` for workflow inputs, configuration,
outputs, and result semantics.

## Research Notes

See `./research.md`. No new dependency is planned.

## Constitution Check

- Domain/tenancy: no Rails domain behavior changes.
- Observable contracts: preflight and upload outcomes are explicit and tested.
- Focus: changes remain within the existing workflow, tests, and docs.
- Truthful releases: missing credentials fail instead of silently succeeding.
- Secret boundary: only Actions secrets and temporary files hold key material;
  cleanup remains unconditional.
- UI/design: no UI changes.

No constitution deviations are required.

## Risks & Dependencies

- A successful upload depends on repository owners supplying valid Apple
  credentials, an App Store distribution profile, agreements, and an existing App
  Store Connect app record.
- Xcode/export option changes can break archive export; retain clear logs and an
  IPA artifact on successful export.
- App Store Connect may accept an upload but continue asynchronous processing or
  reject metadata later; workflow success proves upload acceptance, not tester
  availability.
- GitHub-hosted macOS/Xcode versions evolve. Keep runner and Flutter choices
  explicit and cover repository-controlled workflow invariants in tests.
