# Technical Spec: Restore Sure AI Chat Responses

## Task

- Task ID: `dbc7`
- Branch: `vk/dbc7-fix-sure-ai-chat`
- Reported symptom: submitting a question in Sure chat creates the user message but the assistant turn ends with “Failed to generate a response. Please try again.”

## Objective

Restore successful built-in assistant replies for the currently configured LLM while preserving Sure's existing chat history, function-tool, tenancy, streaming, error-recovery, and usage-accounting contracts.

## Current architecture

`UserMessage` schedules `AssistantResponseJob`, which invokes the configured assistant. `Assistant::Builtin` selects an LLM provider, and `Assistant::Responder` sends the user prompt and available function definitions through the provider, fulfills requested tools, and repeats until a text answer is produced. Errors are caught by the assistant boundary, recorded on the chat, and rendered as the retry state shown in the report.

The production failure can therefore originate from provider/model selection, request construction, provider response parsing, tool-call follow-ups, or background execution. The implementation must identify the concrete failing contract before changing behavior.

## Functional requirements

1. A normal financial question submitted to the built-in assistant completes with a persisted assistant response instead of the generic retry error when the configured provider returns a valid response.
2. Requests sent to the configured model use parameters supported by that model and endpoint.
3. Tool-call-only responses continue into one or more tool-result rounds and end in visible text.
4. Existing custom OpenAI-compatible and native Anthropic paths retain their established request/history behavior.
5. Genuine provider or job failures remain recoverable through the existing error and retry UI; partial or empty assistant records must not corrupt later history.
6. Provider credentials, financial data, and family-scoped context must not be exposed in logs, tests, or persisted diagnostics beyond existing approved behavior.

## Technical approach constraints

- Prefer a focused correction in the provider/request boundary that owns the incompatibility.
- Do not add dependencies.
- Preserve `Current.user` / `Current.family` tenancy and existing assistant function authorization.
- Keep provider capability decisions explicit and covered by Minitest.
- Do not weaken error handling merely to hide the UI symptom.
- Update operator-facing AI documentation if configuration semantics change.

## Verification

- Add a regression test reproducing the exact failed request or response contract.
- Run focused assistant/provider/job tests covering the changed path.
- Run the repository pre-PR checks required by `docs/llm-guides/development.md`.
- Complete an independent Codex diff review and resolve significant findings.
- Open and merge a PR only after CI passes.

## Acceptance criteria

- The reported question can produce a complete assistant answer under the affected configuration.
- The regression test fails before the fix and passes after it.
- Existing provider and assistant tests remain green.
- No unrelated product or infrastructure behavior changes.
