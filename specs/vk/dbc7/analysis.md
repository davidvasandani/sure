# Cross-artifact analysis: dbc7

Date: 2026-11-14. Repository baseline: `9e16de720`.

Reviewed spec, plan, tasks, research, data model, chat-error contract and
`.specify/memory/constitution.md`, with repository code and task guides as evidence.
The initial technical spec and implementation plan remain historical inputs.
The constitution needs no amendment. This review changed artifacts only.

## Confirmed findings and resolutions

| ID | Severity | Finding and evidence | Resolution |
| --- | --- | --- | --- |
| A01 | High | The spec's opening and assumptions still said the cause was unknown and blocked planning; SC-001 required a restored production answer. Its incident clarification and plan instead established exhausted credits and a bounded error-reporting fix. The closing reference also treated the old implementation plan as current. | Reconciled purpose, evidence, assumptions and artifact authority. SC-001 now measures product behavior; SC-006 tracks separately authorized operational recovery. No live diagnosis was repeated. |
| A02 | High | Actionable credit copy and suppression of historical/debug text existed in the plan and contract without explicit functional requirements or incident-specific story scenarios. This weakened principle II's acceptance traceability. | Added Story 3 scenarios and FR-012/013, with task mappings. Existing success/tool/provider requirements remain regression constraints, not a request to redesign those paths. |
| A03 | Critical | The plan and contract said there was no API impact and waived rswag/OpenAPI. `app/views/api/v1/chats/_chat.json.jbuilder` emits `chat.presentable_error_message`, so changing that method changes API error content. Omitting API verification conflicted with constitution II. | Added API Minitest, documentation-only rswag, shared schema description and generated OpenAPI work in T022. T012 depends on T022; T017 includes the post-commit API checklist. Updated plan, data model, contract and quickstart. Routes and nullable-string shape remain unchanged. |
| A04 | High | The contract covered native OpenAI HTTP credit failures, but the plan targeted only the Responses method. `chat_response` can route native OpenAI to `generic_chat_response` when Responses is disabled. | Require the native-identity-gated HTTP transformer in both chat paths and tests for both endpoint modes. Custom endpoints remain excluded, including when they enable Responses. |
| A05 | Medium | Allowlisting stored translated prose could lose watchdog timeout classification after a locale change, or return old-locale copy. `undelivered_error_payload` already persists `type: DeliveryTimeout`. | Specify type-based timeout recognition and read-time category translation, with locale-switch and fallback tests. No backfill or expanded error taxonomy. |
| A06 | Medium | Historical payload coverage named malformed JSON and hashes but did not define behavior for valid scalar/array JSON or non-string object fields. A malformed stored value could otherwise raise or bypass safe rendering. | Define safe fallback without raising or constructing dynamic translation keys; add model and public-output coverage. |

All six findings are resolved in the artifacts. Implementation and behavioral
verification remain future work; unchecked tasks are not completion evidence.

## Requirement coverage after edits

| Requirement | Tasks |
| --- | --- |
| FR-001, FR-003, FR-005: completion, tools, streaming | T010–T013 |
| FR-002: saved model and selection | T002, T005, T007, T010, T012 |
| FR-004, FR-006, FR-007: history and recovery | T003, T007, T008, T010–T013 |
| FR-008: accounting | T002, T005, T010, T012 |
| FR-009: authorization | T008, T010, T012, T022 |
| FR-010: privacy | T002, T003, T006, T008, T011, T014, T022 |
| FR-011: provider compatibility and documentation | T002, T005, T009, T012 |
| FR-012: structured native credit classification | T002, T005, T010, T012 |
| FR-013: localized safe public errors | T003, T006, T008, T011, T012, T022 |

## Constitution and scope review

- I: Keep Chat-owned recovery logic and existing user/family/account boundaries.
- II: The missing API verification dependency is now explicit. All 13 functional
  requirements map to future behavioral verification.
- III: No dependency, migration, provider switch, tool change or lifecycle redesign.
  The partial-failure retry/reload fix is supported by the existing code and spec.
- IV: Product validation, merge and production recovery remain separate outcomes.
- V: Synthetic fixtures and sentinels only; no production payloads or credentials.
- VI: Existing DS alert/button and localization requirements remain. No stylesheet
  change is authorized or needed.
- Quality gates remain full Rails/system tests, Ruby/ERB lint, Biome, Brakeman and
  the planned independent implementation review. This analysis is not that review.

No release or operational task was executed. Parallel task markers describe
future independent file work and do not initiate agents in this analysis turn.
No constitution rule was weakened to accommodate the plan.

## Validation and limits

Static validation checks unique task IDs, defined prerequisites, dependency order,
requirement mappings and local Markdown link targets. Application files were read
only. No Rails tests, provider calls, environment setup or production checks ran.
Incident findings are inherited from the supplied artifacts, not independently
re-established here. Actual installed Faraday behavior, runtime availability,
locale rendering and test results remain implementation-stage checks in T001–T013.
