# Implementation Plan: Restore Sure AI Chat Responses

1. Trace the reported failure from the chat retry partial through `AssistantResponseJob`, `Assistant::Builtin`, `Assistant::Responder`, provider selection, and provider request/response handling.
2. Inspect the active Sure deployment's model/provider configuration and safe error diagnostics to identify the exact failed API contract without exposing credentials or family data.
3. Encode the failure as a focused Minitest at the lowest layer that owns the behavior, with an integration-level assistant test as needed to protect the user-visible outcome.
4. Implement the smallest provider/responder correction that accepts the affected configuration while retaining native OpenAI, custom OpenAI-compatible, Anthropic, tool-loop, history, and retry semantics.
5. Update AI hosting/operator documentation if the accepted model parameters or configuration behavior changes.
6. Run focused tests for the changed assistant/provider path, then the full repository pre-PR checklist from `docs/llm-guides/development.md`.
7. Run an independent Codex review of the complete diff, address confirmed significant findings, and repeat focused/full verification where changes warrant it.
8. Record reusable findings in the project knowledge base if one is available; otherwise explicitly record that no new knowledge page can be stored.
9. Commit the cohesive change, create a Sure repository pull request against `main`, monitor CI to green, and merge it.
