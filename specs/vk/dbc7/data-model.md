# Data model: dbc7

No database migration, index, association or new table is needed.

## Existing records

| Record | Relevant fields | Planned treatment |
| --- | --- | --- |
| Chat | `user_id`, JSONB `error`, `latest_assistant_response_id` | Preserve ownership and response-pointer semantics. Extend only the existing error payload with an allowlisted code. |
| UserMessage | `chat_id`, `content`, `ai_model`, `status` | Retry reuses the saved question and model. No duplicated question. |
| AssistantMessage | `chat_id`, `content`, `status`, `ai_model`, `provider_id` | Keep existing pending/complete/failed behavior and blank-attempt cleanup. Failed text remains excluded from provider history. |
| LlmUsage | Existing per-call usage and error metadata | No schema or accounting changes. |

## Error payload

Proposed recognized credit error, represented here as decoded JSON:

```json
{
  "failure_code": "openai_credits_exhausted",
  "message": "OpenAI API credits are exhausted. Ask your Sure administrator to restore OpenAI API credits or configure a supported provider, then retry.",
  "technical_message": "OpenAI API credits are exhausted.",
  "type": "Provider::Openai::Error"
}
```

All values above are application-owned; none interpolate upstream text. Preserve
the current serialization convention to avoid an unrelated data conversion.
`failure_code` is optional. Unknown codes never become translation keys directly.
Known codes resolve at read time through an explicit map. Only string codes from
that map may select translations. Non-string fields, arrays, scalar JSON and
malformed values fall back safely without raising. Map legacy
`type: DeliveryTimeout` to `chat.errors.no_response` before text classification;
recognized legacy copy selects a category translated in the reader's locale. Existing payloads may
be decoded hashes, JSON-encoded objects, JSON strings or plain text. Preserve
safe generic/rate-limit/auth/temporary/timeout handling without displaying
arbitrary historical `message` or `technical_message` values.

The API's existing nullable-string `error` field uses the same presenter. Its
content follows the safe-copy contract; it does not expose the internal payload
or add a public `failure_code` field. API tests and documentation must reflect it.

No backfill is required. Historical generic errors without a trustworthy code may
remain generic until the next attempt. Do not mine old opaque text for new billing
classifications. The chat UI never renders `technical_error_message`, even in
debug mode. This is a display restriction, not a claim that all historical
technical storage or existing logs have been scrubbed.

## Recovery transitions

1. Saved question queues the existing pending assistant record and job.
2. Credit failure before output removes the blank attempt and saves the safe chat
   error. Failure after output retains failed partial text and saves the error.
3. Reload displays a nonempty chat error regardless of a failed assistant tail.
4. Manual retry ignores trailing failed assistant records, selects the unresolved
   saved user question, clears the error through the existing enqueue path, and
   creates a fresh pending assistant record.
5. A pending or completed assistant tail blocks selecting an older question.
   Empty history also queues nothing. No new retry is scheduled automatically.
6. A successful retried response uses existing persistence/history/accounting.
   A repeated exhausted-credit response restores the same safe error.

The current implementation marks output complete on first append and demotes it
on failure. This plan does not redesign that lifecycle. Existing late-output guards
and completed-history filtering must continue to pass their regression tests.
