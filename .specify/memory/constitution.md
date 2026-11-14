# Sure Project Constitution

## Core Principles

### I. Preserve domain and tenancy boundaries

Rails behavior keeps business logic in models, concerns, and POROs with thin
controllers. All authenticated behavior uses `Current.user` and `Current.family`,
preserves family tenancy and account authorization, and handles currencies and
transaction signs according to the documented domain model.

### II. Specify and test observable contracts

Every change defines checkable acceptance criteria before implementation and adds
behavioral coverage at the appropriate layer. Rails behavior uses Minitest and
fixtures; API v1 changes also update documentation-only rswag specs and generated
OpenAPI output. Workflow changes include credential-independent contract checks
where practical. A feature is not complete without proportionate verification.

### III. Prefer focused, native solutions

Use established Rails, Flutter, and repository patterns before introducing new
abstractions or dependencies. Keep changes small, cohesive, readable, and
reversible. New dependencies require an explicit technical or business rationale.

### IV. Keep release outcomes truthful and reproducible

Release automation must distinguish validation builds, signed distributable
artifacts, uploads, and downstream processing. A green release workflow may not
silently omit its named distribution target. Versions and build numbers must be
valid and traceable, release inputs must be validated before expensive work, and
documentation must match the executable workflow.

### V. Treat credentials and signing assets as security boundaries

Secrets, certificates, provisioning profiles, private keys, and passwords never
enter git or logs. Automation consumes them through approved secret stores, writes
them only to scoped temporary locations, applies restrictive permissions where
applicable, and performs cleanup on success and failure.

### VI. Preserve design-system and localization contracts

UI changes reuse `DS::*` primitives and functional design tokens, use the `icon`
helper, localize user-facing strings, and avoid raw SVG, raw palette values, and
arbitrary sizing when scale tokens fit. Repeated shapes become proposed shared
primitives before duplication lands.

## Quality Gates

- Read the applicable guides in `docs/llm-guides/` before changing code.
- Run focused checks during implementation and the full pre-PR checklist before
  opening a pull request: Rails tests, applicable system tests, Ruby/ERB lint,
  Biome checks, and Brakeman.
- Flutter changes also run analysis and relevant Flutter tests/build validation.
- Obtain an independent review for pipeline tasks that require it and resolve all
  significant confirmed findings.
- Do not start Rails servers, restart the app, edit credentials, or run migrations
  unless the task explicitly requires that environment operation.

## Governance

This constitution governs SpecKit artifacts and implementation. Repository
`AGENTS.md` and the applicable task guides remain authoritative; when an artifact
conflicts with them, update the artifact rather than weakening the rule. Amendments
must state their rationale and update the version.

**Version**: 1.0.0
**Ratified**: 2026-11-14
