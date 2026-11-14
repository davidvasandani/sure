# Implementation verification guide: dbc7

These are future verification steps, not checks already run. This planning turn
changes only artifacts under `specs/vk/dbc7`.

1. Read [plan](plan.md) and [contract](contracts/chat-errors.md). Use existing
   synthetic provider stubs and Minitest fixtures. Do not call a paid provider.
2. Add the incident regression and confirm it fails on the current code because
   no safe exhausted-credit category reaches the chat.
3. Implement the bounded changes, then run focused provider, chat, assistant,
   responder and controller/render tests. Include custom-provider and Anthropic
   coverage and the partial-failure retry/reload scenario. Run API chat Minitest
   coverage using `X-Api-Key` for the shared error presenter. Update documentation-only
   rswag and the shared error description, then regenerate OpenAPI with
   `RAILS_ENV=test bundle exec rake rswag:specs:swaggerize`. Keep the existing
   nullable-string API shape. Follow the post-commit API consistency checklist.
4. Run all required pre-PR checks in a configured development environment:

   ```sh
   bin/rails test
   DISABLE_PARALLELIZATION=true bin/rails test:system
   bin/rubocop -f github -a
   bundle exec erb_lint ./app/**/*.erb -a
   npm run lint
   bin/brakeman --no-pager
   ```

   Inspect autocorrections. Run `npm run format:check` if formatting changes apply.
   Record any unavailable runtime/tool prerequisites as blockers, not passes.
   Do not run setup, database preparation/migrations, or start a Rails server
   without authorization for environment work.
5. Verify in the test browser that a synthetic credit failure appears after the
   job, survives reload, contains no raw diagnostic text with debug enabled, and
   retains Retry. Retry once with a failing stub and once with a successful stub.
   Confirm original question/model, earlier history and final saved answer.
   Capture a sanitized screenshot for the eventual UI PR.
6. Obtain the implementation-stage independent diff review requested by the earlier
   task artifact, resolve confirmed findings, and satisfy repository PR/CI rules.
   This document does not initiate release actions.

Operational verification is separate. An authorized operator must restore provider
capacity, then retry the saved question and verify a persisted answer. If choosing
another provider, account for the saved message model and existing selection rules.
Do not report production recovery from mocked test success or open the health page
under the assumption that it is read-only.
