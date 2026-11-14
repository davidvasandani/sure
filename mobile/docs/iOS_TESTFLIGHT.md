# iOS TestFlight releases

`.github/workflows/ios-testflight.yml` builds a signed Sure IPA and uploads it to
App Store Connect for TestFlight processing. It can run directly or as the iOS
distribution leg of `.github/workflows/mobile-release.yml`.

## Apple prerequisites

Before configuring GitHub, the Apple Developer/App Store Connect owner must have:

1. An App Store Connect application matching the iOS bundle identifier. The
   repository default is `am.sure.mobile`.
2. An Apple Distribution certificate exported as a password-protected `.p12`.
3. An App Store distribution provisioning profile for the same bundle identifier
   and Apple team.
4. An App Store Connect API key with permission to upload builds, including its
   key ID, issuer ID, and `.p8` private key.
5. Current Apple agreements accepted for the account.

Do not commit `.p12`, `.mobileprovision`, `.p8`, passwords, or their base64 values.

## GitHub configuration

Set the following repository Actions secrets:

| Secret | Value |
| --- | --- |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID` | App Store Connect issuer ID |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Single-line base64 encoding of the `.p8` key |
| `IOS_TEAM_ID` | Apple Developer team ID |
| `IOS_KEYCHAIN_PASSWORD` | Random password used only for the temporary CI keychain |
| `IOS_DISTRIBUTION_P12_BASE64` | Single-line base64 encoding of the distribution `.p12` |
| `IOS_DISTRIBUTION_P12_PASSWORD` | Password used when exporting the `.p12` |
| `IOS_DISTRIBUTION_CERT_NAME` | Certificate identity, normally `Apple Distribution` |
| `IOS_PROVISIONING_PROFILE_NAME` | Profile name as shown in the Apple Developer portal |
| `IOS_PROVISIONING_PROFILE_BASE64` | Single-line base64 encoding of the profile |

If the App Store application uses a different bundle identifier, set the optional
repository Actions variable `IOS_APP_BUNDLE_ID`. If omitted, the workflow uses
`am.sure.mobile`.

On macOS, encode files without line wrapping with:

```bash
base64 -i AuthKey_KEYID.p8 | tr -d '\n'
base64 -i Distribution.p12 | tr -d '\n'
base64 -i Sure_App_Store.mobileprovision | tr -d '\n'
```

## Starting a release

For a one-off beta build:

1. Open **Actions → iOS TestFlight → Run workflow**.
2. Select the git ref containing the code to distribute.
3. Enter an explicit numeric marketing version such as `2026.11.14`.
4. Optionally add release notes and run the workflow.

Canonical `v*` release tags also trigger the workflow. A `mobile-v*` release uses
`mobile-release.yml`, which passes its selected version into the same reusable
TestFlight workflow.

The checked-in `mobile/pubspec.yaml` version is intentionally a development
placeholder and is never used as an implicit TestFlight version.

## What success means

A successful **iOS TestFlight** run means all of these completed:

- release inputs and all required secrets passed preflight on Linux;
- Flutter and CocoaPods dependencies installed on the macOS runner;
- Xcode archived and exported a signed App Store IPA;
- App Store Connect accepted the IPA upload; and
- the exact IPA was retained as the `ios-ipa-testflight` workflow artifact.

App Store Connect processes uploads asynchronously. After the workflow succeeds,
open **App Store Connect → Apps → Sure → TestFlight** and wait for the matching
version/build number to finish processing. Apple may still report metadata,
compliance, or beta-review requirements there.

## Failure behavior and diagnosis

The workflow fails before allocating a macOS runner when a required secret is
missing. The preflight summary lists configuration names only; it never prints
secret values. This failure is intentional—a green TestFlight workflow must not
mean that distribution was silently skipped.

Common later failures:

- **Certificate import**: confirm the `.p12` base64 and export password.
- **Provisioning mismatch**: confirm profile name, team, bundle identifier, and
  certificate all refer to the same App Store application.
- **Archive/export**: inspect the `Build signed IPA` Xcode output.
- **Upload authentication**: confirm the API key ID, issuer, private key, role, and
  account agreements.
- **Duplicate build**: rerun to receive a new UTC timestamp build number; never
  attempt to reuse a build number already accepted for that marketing version.

Temporary certificates, profiles, API keys, and the CI keychain are removed by an
unconditional cleanup step; GitHub also destroys the hosted runner after the job.
