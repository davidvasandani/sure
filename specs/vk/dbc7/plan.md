# Technical plan: Actionable chat credit errors

**Task**: dbc7
**Date**: 2026-11-14
**Status**: Planned, no application changes made
**Authority**: [Clarified specification](spec.md), especially "Incident evidence and planning basis"

## Outcome and scope

When native OpenAI rejects a built-in chat attempt with
`credit_balance_exhausted`, show a fixed, localized explanation and recovery action.
The initial job and retry both reached OpenAI and failed for exhausted API credits.
Changing the UI cannot restore provider capacity. The operator must fund the
configured OpenAI account or deliberately configure a supported alternative.

Use the existing provider error, chat error storage, Turbo error partial and Retry
button. Preserve saved questions, completed history, model selection, tools,
streaming, usage accounting and authorization. Include the narrowly related
partial-output retry/reload correction required by the clarified acceptance criteria.
No new dependencies, migration, endpoint, automatic fallback, worker tuning,
request-parameter change or expanded diagnostics are planned.

This plan supersedes the speculative provider-compatibility approach in
`technical-spec.md` and the initial `implementation-plan.md` for implementation
scope. Those earlier artifacts remain historical inputs. Their release steps do
not authorize implementation, commits, PR creation, deployment or merging in this
planning-only turn.

## Technical context

- Rails with ActiveRecord, Minitest/Mocha, server-rendered ERB and Turbo.
- `Provider::Openai#native_chat_response` already receives parsed stream error
  codes. `Provider::Error#failure_code` already survives the provider wrapper.
- `Assistant::Responder` raises unsuccessful provider errors. `Assistant::Builtin`
  cleans up blank attempts, marks partial output failed, then calls `Chat#add_error`.
- `Chat#error` is an existing JSONB column holding JSON-encoded payloads.
- `Chat#presentable_error_message` currently trusts a persisted `message`, while
  its classifier does not recognize this incident. The partial also renders raw
  technical messages when debug mode is enabled.
- Retry and the reload error condition currently depend on the last message's
  role, so retained failed assistant output can block recovery.

Detailed findings and limits are in [research](research.md), storage and lifecycle
in [data model](data-model.md), and observable behavior in the
[contract](contracts/chat-errors.md).

## Planned changes in dependency order

### 1. Reproduce the incident with synthetic errors

Add native OpenAI regression fixtures inline in Minitest, with the exact verified
code and invented provider text. Exercise a parsed stream error and an HTTP error
body independently. The evidence does not establish which transport shape the
incident used. Include secret-like canaries to prove arbitrary text never becomes
user-facing copy. Do not copy production payloads or record new live VCR traffic.

### 2. Carry a narrow, typed classification

In `app/models/provider/openai.rb`, classify the exact structured code
`credit_balance_exhausted` as `:openai_credits_exhausted` only when
`custom_provider?` is false. A custom endpoint can enable the Responses API, so
`supports_responses_endpoint?` alone is insufficient to establish native OpenAI.

For stream failures, set the existing `failure_code` when constructing the error
from `StreamErrorData`. For HTTP failures in both `native_chat_response` and
`generic_chat_response`, use a chat-scoped error transformer passed to `with_provider_response`, gated by `custom_provider?`.
Native OpenAI may use Chat Completions when Responses is explicitly disabled.
Read only the nested `error.code` from a Hash body or safely parsed JSON object. Unknown, missing and malformed bodies
retain the current transformation. Do not match arbitrary message substrings or
HTTP 429 alone, and do not change the shared provider transformer or other OpenAI
operations. Preserve the original exception through the existing usage-recording
rescue before transformation, so accounting behavior remains unchanged.

### 3. Persist and present safe copy

In `app/models/chat.rb`, allowlist the new failure code when building the existing
error payload. Select `chat.errors.openai_credits_exhausted` before the existing
rate-limit/temporary/auth/default rules. On reads, resolve recognized codes through
I18n. Legacy application-authored copy may identify a known category, but render that
category's translation in the current locale rather than returning stored text.
Recognize the existing `DeliveryTimeout` type before generic pattern matching so
old watchdog errors retain `chat.errors.no_response` across locale changes.
Otherwise classify into existing safe categories or use the generic translation.
Treat non-string message/code/type fields and non-object JSON defensively; they
must neither raise nor become public text or dynamic translation keys.

Add the key under `config/locales/models/chat/` following repository locale
conventions. Proposed English copy:

> OpenAI API credits are exhausted. Ask your Sure administrator to restore OpenAI API credits or configure a supported provider, then retry.

For this recognized error, store only the internal code and fixed safe text/type
in the chat payload; do not copy the raw upstream message or body into it. Keep
existing technical storage for other errors unchanged in this focused change.

In `app/views/chats/_error.html.erb`, remove rendering of
`technical_error_message`, including in debug mode. Retain the DOM target and
existing retry route/button; use `DS::Alert` and `DS::Button` with functional tokens
instead of the current raw red palette. No stylesheet changes or new component
are necessary. This closes the debug-mode disclosure path for historical errors
as well as newly classified errors. Technical accessors remain internal.

### 4. Keep failed turns recoverable

Add a small Chat-owned selection method used by retry: ignore failed assistant
records at the tail, then retry only when the remaining last conversation record
is the saved user question. Do not skip a pending or completed assistant response
to reach an older question. Reuse `ask_assistant_later` and the question's `ai_model`;
do not create another user message or delete completed history. Clear the error
through the existing enqueue path only after selecting an eligible question.

In `app/views/chats/show.html.erb`, render a persisted error independently of the
last message's role. This retains the error/Retry UI after reloading a chat whose
last assistant record is failed. Leave the broader meaning of
`needs_assistant_response?` unchanged unless its callers demonstrably require a
change. Preserve existing history filtering and late-output claim guards.

This correction does not add automatic retries, write-tool rollback, or exactly-once
execution. Do not expand it into a message lifecycle redesign.

### 5. Document recovery and verify

Add a troubleshooting subsection to `docs/hosting/ai.md`: a configured API key and
running worker are insufficient when the provider reports exhausted credits;
restore credits for the configured account, then manually retry the saved question.
An alternative provider must be explicitly configured and support the saved model;
changing the default alone does not rewrite existing questions' models. Never
silently send financial context to another provider. Repeated retries while credits
remain exhausted should show the same explanation, not promise eventual success.

Describe this product change separately from operational resolution. Success can
be claimed for error reporting after mocked regression checks; restored production
answers require a separately authorized operator correction and successful retry.
Do not open the AI health page as a passive check: it performs live probes.

## Verification and acceptance mapping

| Requirement | Behavioral verification |
| --- | --- |
| Incident-specific actionable error | Native stream and HTTP code propagate through provider, responder and Chat; initial and repeated failed attempt show fixed copy |
| Privacy, FR-010 | Assert secret-like canaries absent from recognized stored payload and rendered HTML/Turbo, with debug on/off; unknown/legacy payloads never render raw strings |
| Recovery/history, FR-004/006/007 | Failure before text and after partial text; reload shows Retry; retry queues original question/model once per ordinary action; success clears error and persists answer; pending/completed tail does not queue an old question |
| Completion/stream/tools, FR-001/003/005 | Existing direct, multi-round tool, empty/whitespace and interrupted-stream tests remain green; no new completion logic |
| Selection and accounting, FR-002/008/011 | Custom OpenAI-compatible and Anthropic regression suites; no native credit label for custom endpoint with same code; existing per-call usage and daily capture assertions remain intact |
| Authorization, FR-009 | Existing user-scoped show/retry and AI consent guards remain; another user's chat cannot be read or retried |

Use existing `test/models/provider/openai_test.rb`, `test/models/chat_test.rb`,
`test/models/assistant_test.rb`, responder/parser tests and chat controller/render
coverage. Add one focused system scenario if needed for broadcast, reload and Retry
visibility. Capture a sanitized UI screenshot for the eventual PR.

The existing API partial `app/views/api/v1/chats/_chat.json.jbuilder` calls
`presentable_error_message`. Thus the API error content changes even though its
nullable-string shape, routes, authentication and scopes stay unchanged. Add
Minitest coverage in `test/controllers/api/v1/chats_controller_test.rb` with
`X-Api-Key`, including safe credit/legacy errors and cross-user access. Update
documentation-only `spec/requests/api/v1/chats_spec.rb` and the shared
`ChatResource.error` description in `spec/swagger_helper.rb`; regenerate
`docs/api/openapi.yaml`. No raw diagnostic fields are added to the API.

Run focused tests during implementation, then every required pre-PR check in
[development guidance](../../../docs/llm-guides/development.md#before-opening-a-pull-request):
full Rails tests, applicable system tests, Ruby/ERB lint, Biome and Brakeman.
See [verification guide](quickstart.md). Do not claim checks passed when runtime
prerequisites are missing. The current work changes documentation only.

## Constitution check

Pass at design time: business logic stays in existing models, user/family scopes
remain, behavioral contracts precede implementation, credentials never enter
artifacts, no dependencies or schema change, and touched UI uses DS components
and localization. The shared presenter affects API v1 error content, so API behavioral coverage,
documentation-only rswag and OpenAPI regeneration are required by principle II.
Recheck these constraints against the eventual implementation diff. The earlier
artifact requests an independent review before release; schedule that at the
implementation stage, not as parallel work during this planning turn.

## Release and rollback

Deploy as an ordinary application change after required checks. No migration or
backfill. Old workers may keep producing generic failures until updated; new reads
remain compatible with old payloads. Rollback restores generic reporting and the
old partial-retry behavior; it cannot replenish credits. Record product validation
and operator recovery as separate outcomes. No production mutation is part of this
plan execution.
