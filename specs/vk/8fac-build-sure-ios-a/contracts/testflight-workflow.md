# TestFlight Workflow Contract

## Triggers

- `workflow_dispatch`: requires `app_version`; accepts optional `notes`.
- `workflow_call`: requires or receives the coordinated mobile release version;
  accepts optional `notes`; inherits repository secrets from its caller.
- eligible release tags: derive a version from the tag according to the repository's
  release policy.

## Repository variable

- `IOS_APP_BUNDLE_ID` (optional): defaults to `am.sure.mobile`.

## Required secrets

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_BASE64`
- `IOS_TEAM_ID`
- `IOS_KEYCHAIN_PASSWORD`
- `IOS_DISTRIBUTION_P12_BASE64`
- `IOS_DISTRIBUTION_P12_PASSWORD`
- `IOS_DISTRIBUTION_CERT_NAME`
- `IOS_PROVISIONING_PROFILE_NAME`
- `IOS_PROVISIONING_PROFILE_BASE64`

## Outcomes

- Ineligible automatic tag: no distribution job, with an explicit eligibility
  result.
- Missing/invalid input: failed preflight, named missing/invalid fields, no macOS
  allocation.
- Configured build failure: failed release with Xcode/Flutter diagnostics and
  unconditional secret cleanup.
- Successful export/upload: successful workflow, retained `ios-ipa-testflight`
  artifact, and App Store Connect accepting the upload for asynchronous processing.
