# Prior Knowledge: Restore Sure AI Chat Responses

## Knowledge-base search

The repository was searched for a WikiLLM/project knowledge-base index and for pages concerning the assistant, chat failures, provider request compatibility, and background assistant responses.

No project WikiLLM knowledge-base pages or knowledge-base index are available in this workspace, and no project knowledge-base search tool is connected. This is treated as an empty/first-task knowledge base, so there were no prior pages to distill.

## Reusable knowledge from dbc7

No writable project knowledge base became available, so no separate topic page
could be stored or indexed. The sanitized reusable findings are retained here and
tagged `dbc7`:

- Classify provider-specific capacity failures only from exact structured codes
  and only after confirming native provider identity; message text and status
  codes alone are too ambiguous for provider-specific guidance.
- Public chat and API errors must be application-owned localized copy. Raw
  provider diagnostics remain internal and must not appear even in debug UI.
- Manual retry should reuse the unresolved saved user message and its saved model,
  skipping only trailing failed assistant attempts while stopping at pending or
  completed answers.
- Product recovery UI and operational recovery are separate: code can preserve a
  safe Retry path, but an operator must restore provider capacity before answers
  can succeed.

## Relevant maintained project guidance

Although it is repository documentation rather than WikiLLM knowledge, the following established guidance constrains this task:

- `AGENTS.md` requires business behavior to remain in models/POROs, family tenancy to be preserved, Minitest coverage, and the full pre-PR verification suite.
- `docs/llm-guides/architecture.md` identifies `AssistantResponseJob` as the background entry point and documents the provider registry/response contract.
- `docs/hosting/ai.md` documents the built-in assistant, native OpenAI Responses API, custom OpenAI-compatible providers, native Anthropic, tool calling, response timeouts, and model/provider settings.
- `.specify/memory/constitution.md` requires observable acceptance criteria, focused native solutions, credential safety, and independent review.

These sources indicate that the correct fix should target the concrete provider or responder contract, retain existing error recovery, and include regression coverage rather than suppressing the rendered failure state.
