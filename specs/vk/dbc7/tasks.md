# Tasks: Actionable chat credit errors

**Task**: `dbc7`
**Specification**: [Clarified spec](spec.md)
**Plan**: [Technical plan](plan.md)
**Contract**: [Chat errors and recovery](contracts/chat-errors.md)

All tasks below are future work. Creating this checklist does not execute or
authorize implementation, commits, PR creation, merge, or production operations
in this planning-only turn. `plan.md` and the incident clarification supersede
the speculative compatibility changes in the earlier task artifacts.

The incident is native OpenAI `credit_balance_exhausted`. Product acceptance is
safe, actionable error reporting and manual recovery. A restored production
answer requires a separate operator correction. Preserve provider/model selection,
tools, streaming, accounting, authorization, and existing timeout controls. Add no
dependencies, migrations, automatic fallback, or new diagnostics.

Tasks use stable IDs and explicit dependencies. `[P]` marks only independent file
work within the named group, after its prerequisites finish. All other tasks run
serially. Story labels refer to the clarified spec; US3 is the implementation
focus, while US1, US2, and US4 remain compatibility requirements.

## Phase 1: Establish the implementation baseline

- [x] T001 Read `AGENTS.md`, `docs/llm-guides/architecture.md`, `docs/llm-guides/testing.md`, `docs/llm-guides/development.md`, `docs/llm-guides/ui.md`, `docs/llm-guides/design-system.md`, `docs/llm-guides/api-endpoint-consistency.md`, and the dbc7 spec, plan, research, data model, contract, and quickstart. Confirm the task branch and preserve existing workspace changes. Inspect Faraday error shapes in `Gemfile.lock` and `app/models/provider/openai.rb`, existing locale fallback configuration, and `app/components/DS/` alert/button APIs. Record sanitized findings and runtime availability in `specs/vk/dbc7/verification.md`. No live probes, health-page visit, server startup, credentials access, or database setup. Missing prerequisites block verification rather than count as a pass. Dependencies: none.

## Phase 2: Reproduce the contracts

The following two test-authoring tasks form parallel group A. They use separate
files and synthetic fixtures. Run their tests serially in T004 to avoid shared
test-database interference.

- [x] T002 [P] [US3] Add provider regressions in `test/models/provider/openai_test.rb` for the exact structured credit code in a parsed stream failure and HTTP Hash/JSON-object error bodies with nested `error.code`, in both native Responses and native Chat Completions with Responses disabled. Use invented text and secret-like canaries. Cover missing, unknown, malformed, and non-object bodies, message-only mentions, ordinary 429, and custom endpoints in both endpoint modes with the same code. Assert the native-only failure code and unchanged error/usage behavior. Do not record live VCR traffic. Depends on T001.
- [x] T003 [P] [US3] Add Chat contract regressions in `test/models/chat_test.rb` for allowlisted credit codes, safe persisted payloads, localized read-time copy, legacy Hash/JSON/plain-string formats, malformed JSON, non-object JSON, non-string fields, hostile stored messages, locale changes for `DeliveryTimeout`, and existing generic/rate-limit/auth/temporary/timeout categories. Cover retry after one or several trailing failed assistant records, empty history, pending/completed tails, original question/model reuse, no duplicate question, and error clearing only for an eligible enqueue. Depends on T001.
- [x] T004 Run the new provider and Chat tests against unchanged application code. Record exact commands and expected behavioral failures in `specs/vk/dbc7/verification.md`; distinguish them from environment failures. Confirm credit classification and partial-output retry regressions fail for the intended reasons before implementation. Depends on T002, T003.

## Phase 3: Implement classification and recovery

T005 and T006 form parallel group B. The existing `failure_code` contract makes
the provider and Chat changes independent. T007 follows T006 because both Chat
changes share the same model and test file.

- [x] T005 [P] [US3] In `app/models/provider/openai.rb`, map exact structured `credit_balance_exhausted` to `:openai_credits_exhausted` only when `custom_provider?` is false. Carry the code from stream errors and add a chat-scoped HTTP error transformer in both `native_chat_response` and `generic_chat_response`, guarded by native provider identity, with defensive Hash/JSON-object parsing. Preserve unknown-error transformation and the original exception through usage-recording rescue. Leave shared provider transformation, non-chat operations, request parameters, and provider selection unchanged. Adjust only `test/models/provider/openai_test.rb` as required by this implementation. Depends on T004.
- [x] T006 [P] [US3] In `app/models/chat.rb`, allowlist the credit code before existing safe classifications, store only application-owned code/text/type for recognized credit errors, and resolve recognized codes through I18n on reads. Map recognized legacy copy to a fixed category and translate in the current locale; otherwise use safe classification or generic text. Preserve `DeliveryTimeout` by type across locale changes and handle non-string fields and non-object JSON without raising. Preserve timeout handling, serialization, and other errors' internal technical storage. Add `chat.errors.openai_credits_exhausted` in `config/locales/models/chat/en.yml` and corresponding files under `config/locales/models/chat/` as required by verified locale conventions. Check an explicit non-English translation and English fallback behavior in `test/models/chat_test.rb`. Depends on T004.
- [x] T007 [US3] Implement Chat-owned retry selection in `app/models/chat.rb` and complete `test/models/chat_test.rb`: skip only trailing failed assistant attempts, stop at pending/completed assistant records, and reuse the unresolved saved user question through `ask_assistant_later` with its saved `ai_model`. Preserve history and error state when no eligible question exists. Keep `needs_assistant_response?`, response pointers, and late-output guards unchanged unless evidence requires a scoped correction. Depends on T005, T006.

## Phase 4: Present the error and document recovery

T008 and T009 form parallel group C. UI and operator documentation touch separate
files and depend on the same established model behavior.

- [x] T008 [P] [US3] Update `app/views/chats/_error.html.erb` to use `DS::Alert`, `DS::Button`, functional tokens, and localized public copy while retaining the error DOM target and Retry route. Remove all rendering of `technical_error_message`, including debug mode. Update `app/views/chats/show.html.erb` to render a persisted error regardless of the last message's role. Add HTML/Turbo coverage in `test/controllers/chats_controller_test.rb` for debug on/off, hostile legacy payloads, failed-assistant reload, unchanged user-scoped show/retry authorization, and AI consent guards. Assert canaries never appear in rendered errors. No stylesheet or new component changes. Depends on T007.
- [x] T009 [P] [US4] Add exhausted-credit troubleshooting to `docs/hosting/ai.md`: restore credits for the configured account and manually retry; repeated unfunded attempts retain the explanation. An explicitly chosen alternative must support the saved message model, and changing the default does not rewrite existing questions. Explain that this code change cannot fund the account and that the health page performs live probes. Include no credentials or production conversation content. Depends on T007.

## Phase 5: Verify the complete behavior

- [x] T010 [US1] [US2] [US3] Extend `test/models/assistant_test.rb` with synthetic end-to-end provider-error propagation through responder/builtin to Chat, failure before text, partial failure, repeated rejected retry, and a successful manual retry. Assert preserved original question/model, ordered completed history, failed/pending history exclusion, cleared error after success, and a nonempty persisted answer. Retain existing late-output, tool-loop, usage, and authorization assertions; add targeted coverage in `test/models/assistant_message_test.rb` or `test/models/assistant/responder_test.rb` only where a concrete gap exists. Depends on T008, T009.
- [x] T011 [US3] Add or adapt one critical stubbed browser scenario in `test/system/chats_test.rb` for broadcast error visibility, reload with failed partial output, debug-mode privacy, failed Retry, then successful Retry with persistence after reload. Capture a sanitized screenshot at `specs/vk/dbc7/evidence/chat-credit-error.png` for the eventual PR. Use an authorized test environment and no paid provider calls. Depends on T010.
- [x] T022 [US3] [US4] Cover the shared presenter's API impact in `test/controllers/api/v1/chats_controller_test.rb` using the established `X-Api-Key` helpers: safe credit error, hostile legacy payload, null when clear, and unchanged cross-user authorization. Update documentation-only `spec/requests/api/v1/chats_spec.rb` and `ChatResource.error` in `spec/swagger_helper.rb` to describe localized safe public copy with unchanged nullable-string shape. Regenerate `docs/api/openapi.yaml` using `RAILS_ENV=test bundle exec rake rswag:specs:swaggerize`; inspect generated changes and retain no raw diagnostics. Keep behavioral assertions in Minitest. Record commands/results in `specs/vk/dbc7/verification.md`. Depends on T011.

- [x] T012 Run focused Minitest coverage for `test/models/provider/openai_test.rb`, `test/models/provider/openai/chat_stream_parser_test.rb`, `test/models/provider/openai/generic_chat_parser_test.rb`, `test/models/provider/openai/usage_cost_test.rb`, `test/models/provider/anthropic_test.rb`, `test/models/assistant_test.rb`, `test/models/assistant/responder_test.rb`, `test/models/assistant/provided_test.rb`, `test/models/assistant_message_test.rb`, `test/models/chat_test.rb`, `test/controllers/chats_controller_test.rb`, and `test/controllers/api/v1/chats_controller_test.rb`. Run the focused chat system scenario with parallelization disabled. Record commands and results in `specs/vk/dbc7/verification.md`. Confirm direct answers, synchronous custom endpoints, native streaming/history, parallel and successive tool rounds, limits, whitespace/empty handling, interrupted output, handled tool errors, daily capture, and per-call usage remain covered and green. Fix scoped failures before continuing. Depends on T022.
- [x] T013 Run all required pre-PR checks: `bin/rails test`, `DISABLE_PARALLELIZATION=true bin/rails test:system`, `bin/rubocop -f github -a`, `bundle exec erb_lint ./app/**/*.erb -a`, `npm run lint`, and `bin/brakeman --no-pager`. Run `npm run format:check` when formatting changes apply. Inspect autocorrections and keep edits limited to the affected implementation/test files. Record outcomes in `specs/vk/dbc7/verification.md`; rerun affected checks after corrections. Full Rails tests must be green before any push, and every required check must pass before PR creation. Depends on T012.

## Phase 6: Independent review and knowledge capture

- [x] T014 Obtain an independent Codex review of the complete implementation, tests, docs, and evidence. Review against `spec.md`, `plan.md`, and `contracts/chat-errors.md`, including native-only classification, historical payload privacy, retry boundaries, tenancy, accounting, DS/localization compliance, and absence of unrelated behavior changes. Record findings and disposition in `specs/vk/dbc7/review.md`. Review occurs on the completed diff, not concurrently with implementation. Depends on T013.
- [x] T015 Address confirmed significant findings in the affected files, update `specs/vk/dbc7/review.md`, and obtain follow-up review where needed. Repeat focused tests and required full checks for code changes or invalidated verification, recording results in `specs/vk/dbc7/verification.md`. No unresolved significant findings or failed required checks may advance to delivery. Depends on T014.
- [x] T016 Record reusable findings in an available project knowledge base and link the page in `specs/vk/dbc7/prior-knowledge.md`. If none is writable, explicitly record that no knowledge page could be stored and retain the sanitized findings there: structured native credit classification, safe public copy versus internal diagnostics, saved-model retry behavior, and separate operational recovery. Do not copy prompts, tool results, upstream payloads, or identifiers. Depends on T015.

## Phase 7: PR, CI, and merge

- [ ] T017 Inspect the final diff and evidence, confirm the task branch is current with `main`, and resolve any conflicts without absorbing unrelated workspace changes. Repeat required verification if integration changes invalidate it. Commit the cohesive task change with an imperative subject of at most 72 characters. After every commit affecting API error behavior, perform `docs/llm-guides/api-endpoint-consistency.md` checks for Minitest coverage, documentation-only rswag, and shared `X-Api-Key` authentication. Files are the reviewed implementation/tests/docs and dbc7 artifacts only; no credentials or runtime configuration. Depends on T016.
- [ ] T018 Push only after full Rails tests pass, and create the Sure repository PR targeting `main` only after all local pre-PR checks pass. Describe exhausted-credit reporting, partial-output retry/reload recovery, test evidence, sanitized UI screenshot, and no migration requirement. State that production credits remain an operator responsibility and link the task. Remote PR action; no source-file change expected. Depends on T017.
- [ ] T019 Monitor required CI to completion, address CI/review findings in affected files, and rerun relevant local/full checks before pushing corrections. Keep the branch up to date and CI green before requesting review; repeat independent review for material changes. Do not waive or misreport failures. Record final CI links/results in the PR. Depends on T018.
- [ ] T020 Merge the reviewed PR only after required CI, repository review requirements, and branch freshness checks pass. Verify the merge commit on `main` and report the PR link and validation outcome. Remote merge action; no additional source changes expected. Depends on T019.

## Separate operational follow-up

- [ ] T021 Hand off the merged change and recovery instructions to the operator in the task's completion report. Record production recovery as unverified unless a separately authorized operator restores capacity and retries the saved question successfully, with persistence after reload. Funding, provider configuration, deployment, and live probes are outside this implementation checklist's authorization. Do not infer production recovery from mocked tests or merge success. No repository change required. Depends on T020.

## Dependency and acceptance summary

Dependency order is `T001 → {T002, T003} → T004 → {T005, T006} → T007 →
{T008, T009} → T010 → T011 → T022 → T012 → T013 → T014 → T015 → T016 → T017 →
T018 → T019 → T020 → T021`. Only the three brace-delimited groups may overlap.
For example, provider regression authoring can run alongside Chat regression
authoring, but Chat payload and retry implementation must not edit `chat.rb`
concurrently. Verification, autocorrection, review, and release remain serial.

| Acceptance area | Tasks |
| --- | --- |
| FR-012 native classification, both endpoint modes | T002, T005, T010, T012 |
| FR-013 safe public HTML/Turbo/API copy and localization | T003, T006, T008, T011, T022, T012 |
| Exact incident code, safe actionable copy, repeated failure | T002–T006, T008, T010–T012 |
| US3 recovery, reload, original question/model, history | T003, T007–T008, T010–T012 |
| US1/US2 completion, streaming, tools, follow-up compatibility | T010–T013 |
| US4 provider selection and accounting | T002, T005, T009–T013 |
| FR-009 authorization and FR-010 privacy | T003, T006, T008, T010–T014 |
| Full verification, independent review, knowledge, release | T013–T020 |
| SC-006 conditional production answer, distinct from product acceptance | T009, T018, T021 |

The smallest reviewable product increment includes safe classification/display
and partial-output recovery through T012. It is not release-ready until the full
verification, independent review, and delivery gates are satisfied.
