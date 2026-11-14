# Prior Knowledge: Sure iOS TestFlight Delivery

Task ID: `8fac-build-sure-ios-a`

## Knowledge-base search

No project WikiLLM knowledge-base pages or knowledge-base index are available in
this workspace, and no project knowledge-base search tool is connected. This is
treated as an empty/first-task knowledge base; there were no pages to distill.

## Relevant repository knowledge

The repository itself contains useful prior implementation context:

- `mobile/README.md` identifies the client as Flutter and states that mobile
  release tags should drive TestFlight through the shared release pipeline.
- `mobile/docs/iOS_BUILD.md` documents CocoaPods as required for native Flutter
  plugins and distinguishes unsigned validation builds from signed distribution
  archives.
- `mobile/docs/iOS_TESTFLIGHT.md` lists the current signing and App Store Connect
  secret contract.
- `.github/workflows/ios-testflight.yml` already attempts a signed archive and
  upload. Its credential check currently marks the build successful while skipping
  every distribution step if secrets are absent, so a green workflow is not proof
  that TestFlight received a build.
- `.github/workflows/mobile-release.yml` reuses the TestFlight workflow after the
  shared mobile build and passes a selected release version.
- Git history shows repeated fixes to this path, including mobile release wiring,
  bundle-ID propagation, workflow syntax, upload fixes, and CalVer tag handling.
  This argues for contract-level regression tests around the workflow rather than
  another untested shell-only edit.
- The repository currently reports no GitHub Actions secrets through `gh secret
  list`. A real upload remains impossible until an operator configures Apple
  signing and App Store Connect credentials.

## Constraints carried into specification and planning

1. Treat “successful TestFlight release” as the upload step succeeding, not merely
   the workflow completing.
2. Preserve the reusable workflow used by mobile releases and manual dispatches.
3. Keep all Apple credentials outside git and clean temporary key material.
4. Validate missing configuration early and loudly.
5. Prefer tests that can run on Linux without Apple credentials; reserve the final
   signed archive/upload proof for a credentialed GitHub-hosted macOS run.
