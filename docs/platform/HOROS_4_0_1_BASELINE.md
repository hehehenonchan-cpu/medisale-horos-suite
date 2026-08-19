# Horos 4.0.1 Platform Baseline

> Inspection date: 2026-08-19 (Asia/Tokyo). This report contains only sanitized, publishable findings. No patient data, usernames, device serials, UUIDs, signing identities, credentials, old plugin names, internal identifiers, code, raw symbol inventories, screenshots, or raw logs are included.

## Result

`PASS`

Horos is exactly version 4.0.1. The installed Horos executable and OsiriXAPI framework are arm64 and targetable with the installed Apple Clang toolchain on the Apple silicon Mac. The real `PluginFilter` header and runtime class are present. Plugin discovery, signing state, minimum bundle metadata, and Viewer and Browser toolbar extension points were evidenced without modifying or launching Horos.

## Verified facts

| Item | Sanitized finding |
|---|---|
| Horos version | 4.0.1 |
| Horos build | 20231016 |
| macOS | 26.5.2 (build 25F84) |
| Hardware | MacBook Air, model Mac14,2, Apple M2, 8 cores, 8 GB memory |
| Host architecture | arm64 |
| Horos executable | Mach-O 64-bit arm64 |
| OsiriXAPI | Present inside the installed Horos application bundle; Mach-O 64-bit arm64 |
| Compiler | Apple Clang 21.0.0; arm64 target accepted |
| `PluginFilter` header | Present in the installed Horos/OsiriXAPI headers; declares the real `PluginFilter` interface |
| `PluginFilter` runtime | Objective-C class and metaclass symbols present in the Horos executable |
| User plugin directory | `~/Library/Application Support/Horos/Plugins` exists |
| Other standard locations checked | User and system OsiriX plugin directories and system Horos plugin directory were absent; no embedded `Contents/Plugins` directory was present |
| Loader evidence | Horos executable/resources contain recognition evidence for the standard plugin bundle suffixes; Horos preferences also contain plugin availability/update keys |
| Plugin Manager states | Static application resource/binary evidence exists for installed, disabled, incompatible, and unsigned states |
| Horos signing metadata | Hardened runtime and stapled notarization ticket are recorded; signer identity was intentionally redacted |
| Horos signature verification | Both strict and deep-strict verification failed with a sanitized finding that installed code or signature has been modified |
| Viewer toolbar API | Installed `PluginFilter` header declares `toolbarAllowedIdentifiersForViewer:` and `toolbarItemForItemIdentifier:forViewer:` |
| Browser toolbar API | Installed `PluginFilter` header declares `toolbarAllowedIdentifiersForBrowserController:` and `toolbarItemForItemIdentifier:forBrowserController:` |

## Old plugin compatibility and conflict review

The old plugins were inspected read-only and reported only as an anonymous aggregate:

- Four old plugin bundles were present in the recognized user plugin directory.
- All four contain arm64 executables and reference the real `PluginFilter` runtime class.
- None has a direct OsiriXAPI framework load command; this is recorded as an implementation characteristic, not by itself a load failure.
- All four provide `CFBundleExecutable`, `CFBundleVersion`, `CFBundlePackageType`, and `NSPrincipalClass`.
- Two of four additionally provide `CFBundleIdentifier`, `CFBundleName`, `CFBundleShortVersionString`, and `LSMinimumSystemVersion`.
- No duplicate non-empty bundle identifiers, principal classes, or executable names were found among the four bundles.
- None of the four passed strict code-signature verification. This may surface as an unsigned or incompatible state depending on Horos and macOS policy.
- Architecture and anonymous identifier checks found no direct conflict that blocks an arm64 P1-02 build. Runtime coexistence was not tested because Horos was not launched.

No plugin file, source, binary, resource, setting, license, or inspection artifact was changed, moved, disabled, re-signed, copied outside the Mac, or added to this repository.

## Minimum plugin `Info.plist` findings

The minimum consistently observable keys in all four installed samples are:

- `CFBundleExecutable`
- `CFBundleVersion`
- `CFBundlePackageType`
- `NSPrincipalClass`

`CFBundleIdentifier`, `CFBundleName`, `CFBundleShortVersionString`, and `LSMinimumSystemVersion` are not consistently present and must not be assumed from these samples. A P1-02 bundle should define an explicit unique bundle identifier and deployment target rather than copying anonymous legacy metadata.

## Tests and evidence

The following read-only checks were run on the designated Mac. Outputs were reduced before recording so sensitive values and old plugin implementation details did not leave the Mac:

- `sw_vers`, `uname -m`, and a serial/UUID-redacted hardware profile.
- `PlistBuddy` reads of the Horos public version and build keys.
- `file` inspection of the Horos and OsiriXAPI executables.
- `find` checks for OsiriXAPI, `PluginFilter.h`, and standard plugin directories.
- Header presence checks for the real `PluginFilter` interface and the Viewer/Browser toolbar selectors.
- `nm` confirmation of the `PluginFilter` Objective-C runtime class; only the class conclusion is retained here.
- `clang` target checks for arm64 and x86_64; both targets were accepted by the installed compiler. The installed Horos and framework require arm64 for this baseline.
- Redacted `codesign` metadata inspection, strict verification, deep-strict verification, and Gatekeeper assessment.
- Anonymous aggregate checks of old plugin architecture, required `Info.plist` key presence, signature validity, real `PluginFilter` reference, framework load commands, and identifier collisions.
- Static checks of application resources, executable strings, and preference key names for plugin suffix recognition and Plugin Manager state vocabulary.

The Horos GUI and Plugin Manager were not opened because doing so could expose the active clinical database or patient information. Recognition behavior is therefore evidenced statically, not by a runtime screenshot or raw application log.

## Files changed

- `docs/platform/HOROS_4_0_1_BASELINE.md`

No files under `/Applications/Horos.app`, the Horos database, DICOM storage, or any installed plugin location were changed.

## Known issues

- The installed Horos application does not pass strict code-signature validation even though its metadata reports hardened runtime and a stapled notarization ticket. Do not modify, re-sign, or replace it under P1-01.
- The four old plugins do not pass strict signature validation, and two omit common identity/version metadata. Their runtime loading state remains unverified.
- Plugin Manager GUI behavior and actual loading were not exercised to avoid opening patient-bearing application state. P1-02 must validate recognition and invocation using a new, uniquely identified test plugin only after this baseline is reviewed.
- The installed API does not declare `toolbarDefaultItemIdentifiersForViewer:`. Downstream work must use only the verified selectors and must not infer this method.
- x86_64 is compiler-targetable, but the installed Horos executable and OsiriXAPI framework are arm64-only. A plugin intended for this exact installation must include arm64.

## Architecture impact

- P1-02 must build against the installed, real OsiriXAPI headers and subclass the verified `PluginFilter`; no compatibility shim is permitted.
- The deployment artifact must include arm64 and use the verified Viewer and BrowserController toolbar selector pairs.
- Plugin identity must be unique. Existing anonymous checks found no collision, but missing legacy metadata must not become a template for new bundles.
- Code-signing and runtime loading require explicit validation in P1-02 because neither the installed Horos bundle nor the inspected old plugin bundles currently pass strict verification.

## Data-safety impact

- Inspection was read-only.
- No patient record, DICOM object, image, active database content, clinical log, or screenshot was opened or collected.
- No writes were made to Horos, its database, installed plugins, preferences, or security settings.
- Temporary local aggregation lists contained paths only, remained on the Mac, and were deleted immediately after summarization.
- Only this sanitized report is approved for GitHub publication.

## STOP required?

`NO`

All P1-01 mandatory platform gates passed without requiring mutation. The signature failures and lack of runtime Plugin Manager observation are documented risks, but the P1-01 acceptance criteria require those signing and loading-mechanism findings to be recorded rather than requiring a valid signature or launching Horos.

## Next prerequisites

P1-02 remains blocked until this P1-01 PASS and Draft PR are reviewed. After approval, P1-02 may create a separate branch and issue-scoped pull request to build a minimal arm64 plugin using:

- the installed Horos 4.0.1 OsiriXAPI headers;
- the verified real `PluginFilter` base class;
- a unique bundle identifier and principal class;
- the verified plugin directory and bundle recognition mechanism;
- an explicit signing/loading validation plan that does not alter existing plugins or the installed Horos application.

No P1-02 implementation or runtime test was performed as part of this issue.
