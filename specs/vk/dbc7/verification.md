# dbc7 local verification

## Resumed T004

Runtime and database are now available. Commands run serially on unchanged application code:

```sh
DB_HOST=/tmp DB_PORT=55432 POSTGRES_USER=postgres POSTGRES_DB=sure_test DISABLE_PARALLELIZATION=true bin/rails test test/models/provider/openai_test.rb
DB_HOST=/tmp DB_PORT=55432 POSTGRES_USER=postgres POSTGRES_DB=sure_test DISABLE_PARALLELIZATION=true bin/rails test test/models/chat_test.rb
```

Provider: 79 runs, 414 assertions, 8 failures, no errors. Four failures establish
missing native structured credit classification (both HTTP endpoint modes and
both parsed stream error events). Four are strict Minitest nil-assertion failures;
corrected the test to use `assert_nil` for absent bodies.
Chat: 42 runs, 120 assertions, 11 failures, no errors. These establish unsafe
stored-copy presentation, missing credit storage/classification and localization,
lost DeliveryTimeout localization, blocked retries after partial failed output,
and premature clearing on ineligible retries. These are behavioral failures,
not environment failures. T004's reproduction gate is satisfied.

## T005–T009 implementation checks

All Rails commands below use the same database variables and
`DISABLE_PARALLELIZATION=true` shown in T004.

- `bin/rails test test/models/provider/openai_test.rb test/models/chat_test.rb`:
  121 runs, 1127 assertions, five failures, no errors. Provider and presentation
  regressions passed; only the five not-yet-implemented retry regressions failed.
- After retry implementation and English-fallback coverage:
  `bin/rails test test/models/chat_test.rb`: 43 runs, 241 assertions, all passed.
- Native classification reads only exact structured codes. HTTP transformation
  remains chat-scoped and runs after original-exception usage recording.
- English and Spanish credit copy are explicit; German exercises configured
  English fallback. Legacy categories translate at read time.
- Recovery documentation distinguishes manual account funding from code behavior
  and explains saved-model constraints and active health probes.
- Initial controller execution found missing compiled `tailwind.css` and four new
  test-fixture ownership errors. Corrected the fixtures without changing scopes.
  Built existing assets with `RAILS_ENV=test` and the database variables above:
  `bundle exec rails tailwindcss:build` (passed; no source stylesheet changes).
  Reran `bin/rails test test/controllers/chats_controller_test.rb`: 21 runs,
  131 assertions, no failures/errors/skips. HTML and real captured Turbo broadcasts
  retain Retry and omit canaries with debug on/off; failed-tail reload and existing
  consent and cross-user boundaries pass.

## Baseline, T001

## Final implementation verification

- Focused Rails coverage: 243 runs, 1,795 assertions, no failures or errors.
- Focused browser recovery scenario: 1 run, 26 assertions, no failures or errors;
  sanitized evidence saved at `evidence/chat-credit-error.png`.
- API Minitest: 14 runs, 45 assertions, no failures or errors.
- Rswag generation: 477 documentation examples, no failures; OpenAPI regenerated.
- Full Rails suite: 15,950 runs, 103,944 assertions, no failures or errors, 9 skips.
  The first attempt lacked the local libvips runtime; supplying its Nix library
  path resolved the six unrelated Active Storage environment errors.
- Full system suite: 359 runs, 2,098 assertions, no failures, errors, or skips.
- RuboCop and ERB lint passed after scoped autocorrection inspection.
- `npm run lint` passed (148 files, no fixes) after moving the ignored local
  bundle cache outside Biome's scan root. No JavaScript changed, so the existing
  repository-wide formatting baseline was not altered.
- Brakeman passed with zero security warnings.
- `git diff --check` passed.

The implementation invocation authorizes T001 through T013, including T022,
subject to their dependency gates. Independent review and all later delivery and
operational tasks remain excluded.

- Branch: `vk/dbc7-fix-sure-ai-chat`.
- Initial worktree: only the pre-existing untracked `specs/vk/dbc7/` directory.
  Preserve those planning artifacts and unrelated changes.
- Read repository architecture, testing, development, UI, design-system and API
  consistency guidance, plus the clarified spec, plan, research, data model,
  contract and quickstart.
- `Gemfile.lock` pins Faraday 2.14.3 and ruby-openai 8.1.0. The shared provider
  transformer reads Faraday's `response[:body]`. Synthetic coverage must exercise
  both Hash and JSON-string bodies. Installed Faraday behavior cannot yet be
  inspected because the application bundle is missing.
- Native Responses stream errors retain a structured code in `StreamErrorData`.
  Native Chat Completions uses the generic path when Responses is disabled.
  Both paths record the original exception before the provider wrapper handles it.
- `config/application.rb` enables I18n fallbacks. Chat errors have locale-specific
  files, including English and Spanish. Credit translations do not exist yet.
- `DS::Alert` accepts `variant`, `live`, `message`, `title` and block content.
  `DS::Button` accepts `href` and forwards method/options to `button_to`.
  Existing components support the planned alert and Retry without new styles.
- Chat already has JSONB error storage; message status/model fields need no schema
  changes. Retry currently clears errors before eligibility and stops at any
  assistant tail. The presenter currently trusts stored `message` values.

## Runtime availability

`ruby`, `bundle`, `rg`, Docker and Podman are absent from the initial PATH.
Read-only inspection found the required Ruby in the existing Nix store:

```sh
export PATH=/nix/store/lkrkc1fxj9yr3ghsxp7nq30c2hxn9z0k-ruby-3.4.9/bin:$PATH
ruby --version
bundle check
```

Ruby reports 3.4.9, matching `.ruby-version`. `bundle check` fails because the
application gems are missing, including Rails, pg, Faraday and ruby-openai.
No gems were installed, no database was prepared or migrated, and no server,
health-page probe, credential access or live provider request was performed.
An existing configured local test environment was requested from the user.

T004 requires observed behavioral failures against unchanged application code.
An environment failure cannot satisfy that gate or authorize ticking dependent
implementation/verification tasks as complete.

## Regression authoring, T002 and T003

Added provider regressions for native/custom endpoints in both endpoint modes,
Hash and JSON HTTP error bodies, exact structured stream codes, unknown/malformed
codes and bodies, ordinary 429 errors and message-only mentions. HTTP expectations
require the original exception to reach usage recording; stream tests require
one zero-token failed usage record and no fabricated success response.

Added Chat regressions for safe credit storage, allowlisted codes, Spanish
read-time translation, hostile legacy fields, malformed/scalar JSON, existing
safe categories and DeliveryTimeout across locale changes. Retry coverage uses
zero, one and several failed attempts and checks original question/model reuse,
preserved history and no duplicate question. Pending/completed boundaries and
empty histories must retain the error and enqueue nothing.

These tasks author tests only. They do not establish that the tests run or pass.
English fallback coverage remains part of T006 after locale implementation.

## Regression execution, T004 blocked

With the Ruby PATH prefix shown above, ran these serially against unchanged
application code:

```sh
DISABLE_PARALLELIZATION=true bin/rails test test/models/provider/openai_test.rb
DISABLE_PARALLELIZATION=true bin/rails test test/models/chat_test.rb
```

Both exited 1 in `config/boot.rb` with `Bundler::GemNotFound`, before loading
the tests. Missing dependencies include Rails 8.1.4.1, pg 1.5.9, Faraday 2.14.3,
ruby-openai 8.1.0, Minitest and Mocha. These are environment failures, not the
required observed behavioral failures.

Expected failures once the test environment is available, based on code inspection:

- Native structured credit failures currently have no `failure_code`.
- Chat currently retains upstream credit text and lacks the credit locale key.
- Historical stored messages currently bypass safe classification and read-time
  localization; DeliveryTimeout relies on its stored translated message.
- Retry currently cannot select a question behind failed assistant output and
  clears errors even when no question is eligible.

Do not treat these expectations as executed results. T004 remains unticked;
T005 through T013, including T022, have not started because they depend on T004.
All excluded later-stage tasks remain unticked as requested.

## Available static checks

```sh
ruby -c test/models/provider/openai_test.rb
ruby -c test/models/chat_test.rb
git diff --check
```

Both Ruby files report `Syntax OK`; the whitespace check passes. These checks
cannot replace Rails behavioral tests, browser evidence or the pre-PR checks.
