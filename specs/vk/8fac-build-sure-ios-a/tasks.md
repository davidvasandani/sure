# Tasks: Sure iOS TestFlight Release

**Plan**: `./plan.md`

Tasks are ordered by dependency. Tasks marked **[P]** touch independent files
and may run in parallel within their group. Each task names the file(s) it changes.

## Phase 1: Contract baseline

- [x] T001 Add credential-independent workflow contract tests in
  `test/workflows/ios_testflight_workflow_test.rb`.
- [x] T002 Run T001 against the current workflow and record the concrete failures
  that require implementation (no file change; depends on T001).

## Phase 2: Release implementation

- [x] T003 Refactor preflight/version/configuration validation and release result
  semantics in `.github/workflows/ios-testflight.yml` (depends on T002).
- [x] T004 Verify the coordinated caller still satisfies the reusable workflow
  contract and adjust `.github/workflows/mobile-release.yml` only if required
  (depends on T003).

## Phase 3: Documentation and focused validation

- [x] T005 [P] Update TestFlight setup, trigger, failure, success, and verification
  guidance in `mobile/docs/iOS_TESTFLIGHT.md` (depends on T003).
- [x] T006 [P] Update the mobile CI/CD summary if necessary in `mobile/README.md`
  (depends on T003).
- [x] T007 Run workflow contract tests and syntax/static checks; fix failures in
  `test/workflows/ios_testflight_workflow_test.rb` and
  `.github/workflows/ios-testflight.yml` (depends on T004, T005, T006).
- [ ] T008 Run Flutter analysis/tests and the repository pre-PR checklist; inspect
  and limit any autocorrection changes to relevant files (depends on T007).

## Phase 4: Review and delivery

- [x] T009 Run independent Codex review, address confirmed findings in affected
  implementation/tests/docs, and repeat focused verification (depends on T008).
- [x] T010 Record reusable project knowledge or explicitly record that no writable
  project knowledge base exists (depends on T009).
- [ ] T011 Commit and push the cohesive task branch, create a Vibe Kanban PR against
  `main`, wait for required CI, resolve failures, and merge (depends on T010).
- [ ] T012 Dispatch the merged TestFlight workflow and verify successful upload and
  artifact; if Apple credentials are absent, record that precise external blocker
  without claiming success (depends on T011).
