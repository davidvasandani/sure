# Feature specification: Actionable chat credit errors and recovery

**Task**: `dbc7`
**Feature spec**: `specs/vk/dbc7/spec.md`
**Status**: Clarified with incident evidence
**Created**: 2026-11-14

## Purpose

Explain the confirmed exhausted-credit failure in Sure's built-in assistant and
preserve manual retry of the saved question. Restoring provider capacity is a
separate operator action. Successful answers, tools, history, streaming and
authorization remain compatibility requirements when capacity is available.

## Problem and evidence

The reported screenshot symptom, recorded in the [technical spec](technical-spec.md),
is that submitting a question saves the user's message but the assistant turn ends
with "Failed to generate a response. Please try again." This prevents the user
from receiving financial help even though the chat accepts their question.

The screenshot alone establishes a failed assistant turn, not its cause. The
later incident evidence below identifies native OpenAI credit exhaustion in both
the initial job and retry. The exact question and transport envelope were not
retained. No model incompatibility is established. The screenshot itself is not
present in the feature directory; its symptom is taken from the technical spec.

The [prior knowledge](prior-knowledge.md) records that no project knowledge-base
pages were available. It points to maintained repository guidance and the
[AI configuration guide](../../../docs/hosting/ai.md), which distinguish the
built-in assistant from external agents and background categorization.

## Scope

This feature covers completion of built-in chat turns, including direct answers,
answers that require existing financial tools, subsequent conversation turns,
streamed output, and recovery from genuine failures. Existing native OpenAI,
custom OpenAI-compatible, and native Anthropic behavior must remain supported
within their established capabilities.

The scope excludes new providers, new financial tools, an assistant UI redesign,
changes to external-agent or MCP-only behavior, background categorization changes,
and unrelated infrastructure or financial-data changes. It does not promise that
an unavailable or unsupported provider will produce an answer.

## User stories and acceptance scenarios

### Story 1: Receive a complete answer, priority P1

As a user of the built-in assistant, I want my submitted financial question to
receive an answer so that I can understand my finances without repeatedly retrying
a valid request.

This story is independently checkable by submitting a question with a working
configuration and reopening the resulting conversation.

1. **Given** the built-in assistant is enabled and the configured provider returns
   a valid complete answer, **when** I submit a financial question, **then** my
   question and the assistant's non-empty answer appear in the conversation and
   the turn completes without the generic failure state.
2. **Given** an answer has completed, **when** I reload or reopen the chat,
   **then** the completed answer and preceding messages remain in order.
3. **Given** the provider supplies streamed text, **when** the response arrives,
   **then** the existing streaming experience remains available and the final
   saved answer contains the complete response.

### Story 2: Answer questions using authorized financial context, priority P1

As a user, I want the assistant to use the financial information I am allowed to
access and the conversation so far, so that its answer addresses my question in
context.

This story is independently checkable with a question requiring existing tools,
followed by a question referring to the earlier exchange.

1. **Given** answering a question requires an existing financial tool, **when**
   the provider requests that tool without supplying answer text, **then** the
   assistant continues the turn using the authorized tool result and displays
   the eventual complete answer.
2. **Given** a valid answer needs multiple tool requests or successive tool
   rounds within existing limits, **when** those requests succeed and the provider
   returns final text, **then** the user receives the final answer rather than an
   empty response or a failure caused solely by the intermediate tool-only turns.
3. **Given** an existing conversation, **when** I ask a follow-up question,
   **then** the assistant retains the applicable conversation context without
   mixing in another user's or family's conversation or restricted accounts.

### Story 3: Recover from a genuine failure, priority P1

As a user whose assistant turn failed, I want an honest failure state and a usable
retry action so that I can recover without starting a new conversation.

This story is independently checkable by causing a failed turn and then retrying
with a successful provider response.

1. **Given** the provider or background execution fails, **when** the failure is
   reported, **then** the existing error and retry experience remains available
   and the user's submitted question remains in the chat.
2. **Given** a failed turn, **when** I retry and the provider returns a valid
   answer, **then** the turn completes with a visible, persisted answer and the
   conversation remains usable.
3. **Given** an attempt left partial text or no text, **when** I retry or continue
   the conversation, **then** that attempt is not treated as a completed answer
   and does not corrupt the history used for later turns.

### Story 4: Preserve a deployment's existing behavior, priority P2

As a Sure operator, I want the correction to respect my configured provider and
existing accounting so that restoring chat does not change where financial data
is sent or how assistant usage is recorded.

1. **Given** an established supported native OpenAI, custom OpenAI-compatible, or
   native Anthropic configuration, **when** a valid direct or tool-assisted
   exchange completes, **then** provider selection, conversation continuity, and
   existing usage-accounting behavior remain intact.
2. **Given** diagnosis of a failed exchange, **when** support information is
   recorded, **then** it does not disclose credentials or expand retention or
   exposure of financial data beyond existing approved behavior.

The incident-specific acceptance scenarios extend Story 3:

4. **Given** native OpenAI returns the exact structured credit-exhaustion code,
   **when** the initial attempt or a retry fails, **then** fixed localized copy
   explains exhausted OpenAI API credits and asks the administrator to restore
   capacity or configure a supported provider before retrying.
5. **Given** a stored error, **when** chat is rendered, broadcast or returned by
   the existing API, **then** public error copy contains no arbitrary upstream or
   stored diagnostic text, including with debug mode enabled. Reload preserves
   the error and Retry action after failed partial output.

## Functional requirements

- **FR-001**: A valid completed provider response to a built-in chat question must
  become a non-empty, visible, persisted assistant answer.
- **FR-002**: The assistant must honor the effective provider and model selection
  and communicate within that configuration's supported request and response
  capabilities. Preserve existing provider-order and credential fallback rules. Success must not
  depend on introducing a new fallback or substituting the saved message model.
- **FR-003**: A valid tool-only intermediate response must continue the exchange
  through the existing authorized tools. It must not count as a completed answer
  or fail merely because it contains no user-facing text.
- **FR-004**: Completed turns must preserve conversation order, existing history
  semantics, and the ability to ask follow-up questions after reopening a chat.
- **FR-005**: Streaming and final persistence must retain the existing user
  experience, without presenting an interrupted or empty response as success.
- **FR-006**: Genuine provider, timeout, background-execution, or unhandled tool failures
  must retain recoverable error behavior. Handled tool errors remain tool results
  that the assistant can explain or correct within existing limits. Hiding the error alone
  does not satisfy this feature.
- **FR-007**: Failed or partial attempts must not invalidate subsequent retries
  or conversation history.
- **FR-008**: Existing usage accounting must retain its established treatment of
  successful responses, tool rounds, and failed or retried attempts.
- **FR-009**: All chat context and tool access must preserve user, family, and
  account authorization boundaries, including when work runs in the background.
- **FR-010**: Credentials and financial context must not gain new exposure in
  logs, test artifacts, or persisted diagnostics.
- **FR-011**: Existing supported provider paths must retain their established
  chat and history behavior. Any necessary configuration-semantic change must be
  accurately described in operator-facing AI documentation.

- **FR-012**: Classify the exact structured native OpenAI code
  `credit_balance_exhausted` as the application-owned `openai_credits_exhausted`
  category. Cover stream errors and HTTP error bodies in both supported endpoint
  modes. Custom endpoints, arbitrary text mentions and HTTP 429 alone must not
  receive this category.
- **FR-013**: Render localized application-owned error copy in HTML, Turbo and
  the existing API chat `error` field. Never display arbitrary persisted messages
  or technical text, even in debug mode. Recognized credit payloads store only
  safe application-owned values. Preserve safe legacy categories and timeout copy.
  No historical diagnostic scrub or new diagnostic retention is required.

## Edge cases

- A response contains tool requests but no text, including more than one round.
- An entire turn contains neither usable answer text nor valid tool requests. It
  must not be marked successful. A successful final tool follow-up may contain no
  new text if an earlier successful round already supplied usable answer text.
- A provider rejects a request, times out, or interrupts a stream after partial
  text. Recovery must preserve the original question and valid prior history.
- A tool cannot access requested data because of existing permissions. The
  correction must not widen access to make the answer succeed.
- A conversation includes a failed attempt before a successful retry or follow-up.
- A deployment uses a supported provider other than the one affected by the
  reported failure.

## Key concepts

- **Conversation**: The authorized user's ordered chat history, including saved
  questions, completed answers, and the existing failure state.
- **Assistant turn**: The work prompted by a user message, which may require
  several provider and tool exchanges before it produces an answer or fails.
- **Financial tool context**: Information available through existing assistant
  functions, limited by the current user's family and account permissions.
- **Provider configuration**: The effective provider, model, and connection
  settings already selected for the built-in assistant.
- **Usage record**: Existing accounting associated with assistant processing,
  whose meaning must remain unchanged. Daily activity telemetry and per-provider-call
  token/cost records are distinct contracts, as clarified below.

## Success criteria

- **SC-001**: Synthetic native OpenAI credit failures produce the actionable
  localized error on initial attempt and repeated retry, including after reload
  with partial failed text. Secret-like sentinels never appear in recognized
  stored payloads or public HTML/Turbo/API error copy. This is product acceptance.
- **SC-002**: Every controlled successful scenario above completes with a
  non-empty answer, including direct text, one tool round, multiple tool rounds,
  and a follow-up in an existing conversation.
- **SC-003**: Every controlled failure scenario retains a recoverable failure
  state. A subsequent valid retry completes without losing the original question
  or corrupting history.
- **SC-004**: Compatibility checks for the established provider paths show no
  regression in conversation history, streaming, or usage accounting.
- **SC-005**: Authorization checks show no additional cross-family or restricted
  account access, and evidence review finds no newly exposed credentials or
  financial context.

- **SC-006**: Production answer recovery remains unverified until a separately
  authorized operator restores capacity and retries the saved question, with the
  answer retained after reload. Mocked tests do not satisfy this operational goal.

These are acceptance targets, not claims that the behavior has been verified.
Provider availability and response latency remain subject to existing operational
limits; this feature introduces no new latency guarantee.

## Governing constraints and assumptions

The [repository guidance](../../../AGENTS.md),
[architecture guide](../../../docs/llm-guides/architecture.md), and
[constitution](../../../.specify/memory/constitution.md) govern the eventual
change. It must stay focused, preserve domain and tenancy boundaries, add no
dependencies as required by the technical spec, and retain design-system and
localization contracts wherever applicable. Behavioral evidence and required
repository quality gates remain conditions of completion.

Successful scenarios assume chat is enabled, required user consent is present,
the configured provider supports the requested capabilities and has capacity, and
background processing can run. The supplied incident evidence is sufficient to
plan safe credit-error reporting without reading the private question. It does
not establish that production capacity or successful answers have been restored.

This document defines what must work and why. It does not select a root cause,
prescribe code changes, or provide an implementation plan.


## Clarifications

### Session 2026-11-14

These answers come from repository inspection at commit `9e16de720`. They define
acceptance behavior, not a diagnosis or implementation approach. Tests cited here
were read, not executed.

- **Q: Which model and provider must the fix target?** A: The provider selected
  for the affected saved user message and its `ai_model`. New-message defaults
  do not establish an existing message's model. `Chat.default_model`,
  `Assistant::Provided`, and `Provider::Registry.llm_provider_order` already allow
  credential/model-aware provider selection. Preserve those rules; FR-002 does
  not prohibit existing fallback. Do not infer the affected model from the
  defaults or from named-model regression tests.
- **Q: What does compatibility and streaming mean?** A: Preserve the selected
  endpoint mode. Native OpenAI normally uses Responses and response IDs; custom
  OpenAI-compatible endpoints normally use synchronous Chat Completions and
  reconstructed message/tool history. `OPENAI_SUPPORTS_RESPONSES_ENDPOINT` can
  override endpoint selection. Native Anthropic uses its own history format and
  streaming path. FR-005 requires live streaming where already supported and a
  visible complete answer for synchronous paths; it does not require adding
  streaming to custom Chat Completions. Existing history budgets still apply.
- **Q: Must every provider round produce text?** A: No. A turn can contain
  multiple tool-only rounds and parallel tool requests. The existing limit is
  eight tool rounds by default, configurable by a positive
  `ASSISTANT_MAX_TOOL_CALL_ITERATIONS`; invalid values use the default. Parallel
  calls count as one round. At the limit, the existing contract requests text
  without further tools; further tool requests fail recoverably. Preserve the
  limit rather than extending it to make a scenario pass.
- **Q: What counts as an empty answer or a completed turn?** A: Whitespace alone
  is not an answer. Preserve whitespace within actual answer text. Require usable
  text across the turn and successful provider termination, with no outstanding
  tool requests. An empty final follow-up does not discard earlier usable text
  from a successful round. An interrupted stream remains a failure even if it
  emitted text. This is an observable completion contract, not a requirement to
  redesign the internal message-status lifecycle.
- **Q: Does a failed tool always fail the chat?** A: No. Existing tools return
  structured errors for unknown tools, invalid arguments, inaccessible records,
  and execution failures. The assistant can correct a request or answer while
  explaining missing information. Such an answer may complete normally; it must
  not invent unavailable data or imply a failed action succeeded. Unhandled
  failures and exhausted tool limits retain the recoverable chat error state.
- **Q: What must retry do after partial output?** A: Retry the original saved
  user question in the same chat, including when a failed assistant record is
  last. Preserve valid prior history and exclude pending/failed attempts from
  model history. Do not duplicate the user's question or revive a timed-out
  attempt when late output arrives. Retained partial text may remain marked
  failed; deletion of all failed records is not required. Existing write tools
  may already have acted before an error. This feature does not promise rollback
  or exactly-once execution of those actions, or introduce automatic retries.
- **Q: What usage semantics must remain?** A: `Usage.capture` attempts daily
  installation activity capture before each provider call, including failed
  attempts, subject to existing opt-in and deduplication rules. Separately,
  providers record family-scoped token/cost usage for individual calls, including
  tool follow-ups and retries, and their established error records. Anthropic
  preserves available partial usage on stream failure without double recording
  that attempt. A failed overall turn does not erase earlier calls' usage.
- **Q: Are worker changes, timeout changes, or new diagnostics required?** A:
  No such change is selected. Chat uses `ai_high_priority`; the existing browser
  watchdog includes queue wait, defaults to 90 seconds, and has a 30-second
  minimum. Provider request timeouts are separate. Preserve existing controls
  and recovery behavior. Any eventual change must follow evidence of the actual
  failure, without expanding diagnostic retention or exposing prompts, tool
  outputs, credentials, or raw provider payloads in task artifacts.

### Evidence and limits

| Contract | Repository evidence |
| --- | --- |
| Saved model and provider selection | `app/controllers/messages_controller.rb`, `app/models/chat.rb`, `app/models/assistant/provided.rb`, `app/models/provider/registry.rb` |
| Endpoint selection, stream behavior and usage | `app/models/provider/openai.rb`, `app/models/provider/anthropic.rb` |
| Tool rounds, whitespace, completed history and daily activity | `app/models/assistant/responder.rb`, `app/models/usage.rb`, `test/models/assistant/responder_test.rb` |
| Tool errors and authorization context | `app/models/assistant/function_tool_caller.rb`, `app/models/assistant/builtin.rb`, `test/models/assistant_test.rb` |
| Earlier text followed by an empty round | `test/models/assistant_test.rb`, test `keeps earlier text when the final tool follow-up is empty` |
| Partial failures, retry and late output | `app/models/chat.rb`, `app/models/assistant_message.rb`, `app/models/assistant/builtin.rb` |
| Worker queue and operator controls | `app/jobs/assistant_response_job.rb`, `docs/hosting/ai.md` |

Static inspection identifies a retry acceptance gap worth verifying: the built-in
assistant retains partial output as a failed assistant message, while
`Chat#retry_last_message!` only queues work if the last conversation message has
the user role. This supports the explicit retry requirement above. It does not
establish the cause of the reported initial failure.

Read-only workspace checks found no Ruby/Bundler, Docker, or kubectl executable
on PATH; no `.env`, `.env.local`, or `.env.production`; and no development or
production application log. Presence-only checks found no shell values for
`RAILS_ENV`, `ASSISTANT_TYPE`, `LLM_PROVIDER`, `OPENAI_MODEL`, `ANTHROPIC_MODEL`,
`OPENAI_URI_BASE`, `OPENAI_ACCESS_TOKEN`, `ANTHROPIC_API_KEY`, `DATABASE_URL`,
`REDIS_URL`, or `KUBECONFIG`. These observations describe this shell only. They do
not establish whether the deployed application has credentials, database
settings, or healthy workers. No application boot, provider inference, health
probe, job enqueue, database mutation, or infrastructure change was performed.
The AI health page is not treated as a passive diagnostic: the hosting guide
says opening it runs provider probes and can persist diagnostic entries.

### Incident evidence and planning basis

Read-only diagnostics on the documented Sure host identified the affected jobs
at 2026-11-14 08:01 UTC. Both the initial `AssistantResponseJob` and its retry
ran from `ai_high_priority`, reached native OpenAI, and failed with provider code
`credit_balance_exhausted`. The provider stated that the organization had no API
credits. The deployed configuration selected OpenAI, used its default model and
native endpoint, had an OpenAI credential, and had no Anthropic credential.
Secrets and conversation content were not read or copied.

The incident is therefore an upstream account-state failure, not a missing
worker, lost job, parser error, or tool-loop defect. Sure cannot make a successful
provider response without funded OpenAI credits or another configured provider.
The product defect in scope is that the chat loses the actionable error category
and renders only the generic failure shown in the report. Use fixed application
copy derived from the structured code; upstream message text is not trusted.

The working assumption is that the report concerns built-in chat, as stated in
the task artifacts. If evidence instead identifies external chat or an
infrastructure-only failure, revisit scope before planning. Existing tests for
specific models and tool-only replies are compatibility evidence, not proof of
incident reproduction. A regression must demonstrate the identified failed
contract before a correction can be claimed.

For this incident, acceptance is that the failed chat turn identifies exhausted
OpenAI credits and directs the operator to restore provider capacity, while
preserving retry and history behavior. A successful financial answer remains
conditional on that operational correction. The current
[plan](plan.md) and [tasks](tasks.md) govern implementation scope.
`implementation-plan.md` and `technical-spec.md` are historical inputs and do not
override this clarified scope.
