# Research: dbc7 chat failure

## Evidence and confidence

The clarified [spec](spec.md#incident-evidence-and-planning-basis) records read-only
host diagnostics at 2026-11-14 08:01 UTC. Initial and retry jobs ran on
`ai_high_priority`, reached native OpenAI and returned `credit_balance_exhausted`.
The deployed setup selected native OpenAI with a credential and default model;
no Anthropic credential was available. These are supplied, verified incident
findings, not newly repeated diagnostics in this planning turn. No raw logs,
credentials, account identifiers or conversation content are reproduced here.
The exact HTTP status and stream-versus-HTTP error envelope were not supplied.

The reported generic error is consistent with repository inspection. It is not
evidence of a parser, worker, model-parameter or tool-loop defect. Existing
successful-model tests are compatibility evidence, not incident reproduction.
No external documentation or live provider request is needed to choose this
repository-local error-reporting change.

## Repository findings

| Source | Finding and consequence |
| --- | --- |
| `app/models/provider/openai/chat_stream_parser.rb` | Stream error data already carries event, code, message and details. Reuse the parsed code. |
| `app/views/api/v1/chats/_chat.json.jbuilder` | Uses `presentable_error_message` for API `error`; shared-model changes require API contract tests and documentation even without controller edits. |
| `app/models/provider/openai.rb` | Stream failures become an error message with the code embedded. Native chat does not currently set a safe failure code. Custom providers can opt into Responses, so endpoint capability is not provider identity. Native OpenAI can also disable Responses and use `generic_chat_response`; cover HTTP errors there too. |
| `app/models/provider.rb` | `failure_code` exists and survives default transformation. Non-Faraday opaque details are not retained by that transformation. Do not rely on raw details reaching Chat. |
| `app/models/assistant/responder.rb` | Unsuccessful responses raise their error. Completed history excludes pending and failed records. No new responder wrapper is needed. |
| `app/models/assistant/builtin.rb` | Blank failed attempts are destroyed; partial attempts are retained as failed. Existing rescue already forwards the error to Chat. |
| `app/models/chat.rb` | Payload stores friendly/technical messages and type. Classifier lacks exhausted-credit handling. Stored message is trusted. Retry checks only the last record's role. |
| `app/views/chats/_error.html.erb` | Public copy is separate from technical copy, but debug mode displays raw technical text. Existing error shape uses raw palette classes. |
| `app/views/chats/show.html.erb` | Reload hides errors when the last conversation record has assistant role, including failed records. |
| `app/models/assistant_message.rb` | First append conditionally claims a pending record, protecting against late writes after watchdog failure. Preserve this guard. |
| `db/schema.rb` | Chat JSONB error and message status/model already support the change. |
| `app/controllers/chats_controller.rb` | Show/retry use `Current.user.chats`; AI consent/enabled guards already exist. Preserve them. |

## Decisions and alternatives

1. Reuse `Provider::Error#failure_code` and a single application-owned code. A broad
   billing-error taxonomy, new exception hierarchy, or substring matcher would add
   ambiguity and scope. HTTP 429 alone must keep its rate-limit meaning.
2. Classify exact structured codes only for native OpenAI chat. Labeling every
   OpenAI-compatible endpoint as OpenAI would give incorrect operator instructions.
3. Render fixed translated copy. Escaping raw provider text prevents HTML injection
   but does not prevent disclosure of credentials, URLs or account identifiers.
4. Persist the safe category in the existing payload, without migration. New
   recognized failures need no raw technical payload; other internal diagnostics
   remain unchanged. Remove technical rendering from the chat for every error.
5. Fix tail-of-history retry selection and reload visibility. These are verified
   acceptance gaps, separate from the incident cause. Keep existing history builders,
   response pointers, accounting and timeout behavior.
6. Document funding as an operational prerequisite. Automatic provider switching,
   model substitution, added retries and timeout tuning cannot repair exhausted
   account credits and may alter where financial context is sent.

## Remaining implementation checks

Confirm actual installed Faraday error-body shapes against repository dependencies
and synthetic fixtures before implementing the chat-scoped transformer. Handle
Hash, JSON string and malformed input defensively. This is an adapter detail, not
an unresolved product decision. `config/application.rb` enables I18n fallbacks. Verify the new key in a non-English
locale and when falling back to English. Historical watchdog payloads carry
`type: DeliveryTimeout`; preserve this category across locale switches rather
than trying to infer it from translated prose. Exercise non-string field values
and non-object JSON as well as malformed JSON. No production secret access is needed.

`rg` is unavailable in this shell; inspection used `find`, `grep`, `sed` and `cat`.
No application was booted, no jobs were enqueued, and no incident probe was repeated.
