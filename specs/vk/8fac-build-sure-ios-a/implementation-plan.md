# Implementation Plan: Build Sure iOS App in TestFlight

Task ID: `8fac-build-sure-ios-a`

1. Establish the SpecKit constitution from repository guidance and existing
   architecture, testing, mobile, and release conventions.
2. Specify user-visible release outcomes, including manual and reusable workflow
   scenarios, explicit credential failures, secret handling, and proof of upload.
3. Clarify ambiguities from repository evidence and GitHub state, especially the
   distinction between building an unsigned app, producing a signed IPA, and
   uploading a build to TestFlight.
4. Produce the SpecKit technical plan, research notes, release input model, and
   workflow contract.
5. Generate dependency-ordered implementation tasks and analyze all SpecKit
   artifacts for gaps or constitution violations.
6. Add credential-independent contract tests for the TestFlight workflow and run
   them against the current implementation to identify concrete defects.
7. Refactor the release workflow only where the tests or analysis establish a
   defect: fail fast for missing credentials, validate version/signing inputs,
   preserve cleanup, and expose an auditable upload result.
8. Update operator documentation to match the exact trigger, secret/variable
   contract, validation behavior, and post-upload verification steps.
9. Run focused workflow/mobile checks, followed by all repository-required pre-PR
   checks that are applicable and executable in this environment.
10. Run an independent Codex diff review, address confirmed findings, and repeat
    verification until no significant findings remain.
11. Distill reusable TestFlight release knowledge into the project knowledge base
    if a writable project knowledge base becomes available; otherwise record that
    no knowledge-base facility exists rather than creating filler.
12. Commit the cohesive change, push the task branch, create a Vibe Kanban pull
    request against `main`, monitor CI, resolve failures, and merge after CI passes.
13. Dispatch the merged TestFlight workflow and verify the signed IPA upload. If
    GitHub Actions still has no Apple credentials, report the precise external
    prerequisite and do not misrepresent the skipped/failed run as a TestFlight
    build.
