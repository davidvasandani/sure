# Contract: Safe built-in chat errors and recovery

This covers internal Ruby errors and their public presentation. No route or API
field shape changes. Existing API v1 chat responses serialize the shared
presenter into the nullable-string `error` field, so their content is affected.
Minitest API coverage and documentation-only rswag/OpenAPI updates are required.

## Provider to chat

| Input | Required result |
| --- | --- |
| Native OpenAI chat, exact structured `credit_balance_exhausted` in stream error or nested `error.code` in an HTTP error body, including native Chat Completions with Responses disabled | Unsuccessful provider response with `failure_code: :openai_credits_exhausted`; no success text fabricated |
| Custom OpenAI-compatible endpoint, even with Responses enabled and the same code | Existing provider behavior; do not claim native OpenAI billing failure |
| Anthropic or other provider error | Existing behavior and safe public classifications |
| 429 without the recognized structured native code | Existing rate-limit handling |
| Unknown/malformed/missing code | Existing safe fallback; classification itself must not raise |
| Raw text merely mentions the code | No native-credit classification based on text alone |

Existing `Provider::Response` fields stay `success?`, `data`, `error`. Existing
responder/builtin exception propagation remains. No request, tool, model, timeout,
usage or provider-selection contract changes.

## Chat to browser

Recognized credit errors display localized application-owned text explaining that
OpenAI API credits are exhausted and asking the Sure administrator to restore
credits or configure a supported provider before retrying. They retain the
existing Retry action and chat DOM target in broadcasts and full-page rendering.

Neither normal mode nor debug mode exposes exception text, raw provider bodies,
URLs, API keys, organization/project identifiers, prompts or tool results through
the error component. Unknown stored values cannot bypass the safe copy mapping.
Escaping is required but is not sufficient sanitization. No new diagnostic panel
or provider-payload download is introduced.

For stored data, reject non-string codes/messages as public copy and safely
handle arrays, scalars and malformed JSON. `DeliveryTimeout` retains the
`no_response` translation across locale switches. Recognized legacy copy selects
a fixed category rendered in the current locale; it is not returned verbatim.
The API returns the same safe public copy without adding diagnostic fields.

## Retry and persistence

- Retry targets the original unresolved saved question in the same chat and uses
  its saved model. Trailing failed assistant attempts do not block it.
- Pending/completed assistant attempts do not cause an older question to replay.
- Existing user/family access and AI consent guards apply to show and retry.
- Failed and pending text is excluded from model history. Completed earlier turns
  retain their order. Partial failed text may remain visible as failed.
- After another rejected attempt, show the same actionable error. After successful
  recovery, persist the answer and keep the chat usable with no stale error.
- No automatic retry, automatic alternate provider, tool rollback or exactly-once
  write-tool guarantee is added.

## Acceptance examples

Use invented content and secret-like sentinel values in tests, never production
logs. Assert that the sentinel is absent from recognized persisted error data and
from rendered error HTML/Turbo for all modes and API JSON. Cover legacy raw strings, JSON
strings, hashes, unknown codes, malformed JSON and hostile stored message values.
A live answer is conditional on operational provider capacity; passing mocked
error/retry tests does not establish that the production account has been funded.
