# P1-03 Viewer Toolbar PoC Report

## Result

**PASS / REVIEW.** Horos 4.0.1 loaded the ad-hoc-signed arm64 bundle, exposed the plug-in item in the actual Viewer toolbar customization palette, and dispatched actions to the correct owning Viewer across two open Viewer windows. P1-04 remains blocked pending review and separate authorization.

## Verified facts

- PR #16 approved head `86699418a4b118616aa687a2889e2457cf0082fb` was merged as `db3f6d92bcf6998929d49a7bafdabeb751b16c9a`, matching remote `main` before this branch was created.
- P1-02 evidence was complete, Issue #2 was closed as completed, and Issue #3 was moved from `status: blocked` to `status: ready` after its Definition of Ready was satisfied.
- Branch `spike/p1-03-viewer-toolbar` was created directly from merge commit `db3f6d92bcf6998929d49a7bafdabeb751b16c9a`.
- The installed Horos 4.0.1 `PluginFilter.h` declares `toolbarAllowedIdentifiersForViewer:`, `toolbarItemForItemIdentifier:forViewer:`, and `duplicateCurrent2DViewerWindow`; the implementation uses those real APIs and the real `PluginFilter` base class.
- No additional volumes or SMB/NFS network shares were mounted at the isolation gate.
- Runtime loading occurred only with a process-specific temporary `HOME` and `CFFIXED_USER_HOME`. The bundle was placed only under that isolated runtime home's `Library/Application Support/Horos/Plugins` directory.
- Only a generated, blank-identity synthetic DICOM fixture was imported into the isolated runtime database. The database showed one study and one image.

## Files changed

- `plugin/MedisalePluginFilter.m`: adds the Viewer toolbar item, weak owner tracking, anonymous Viewer numbering, confirmation action, and verified Viewer duplication used by the acceptance test.
- `plugin/Info.plist`: advances the proof-of-concept version to 0.2.0 (build 2).
- `scripts/create_synthetic_dicom.py`: generates unique UIDs per synthetic fixture and centralizes valid UI padding.
- `Makefile`: verifies both real Viewer toolbar selector names in the built binary.
- `TASKS.md`: records P1-02 complete and P1-03 pass/review without unlocking P1-04.
- `docs/platform/P1_03_VIEWER_TOOLBAR.md`: this anonymized report.

## Tests and evidence

- `make clean && make verify`: PASS.
- Built executable: Mach-O 64-bit bundle, arm64.
- Linkage check: unresolved Objective-C reference to the actual Horos `PluginFilter` runtime class; no fake base class or compatibility shim.
- Selector checks: both verified Viewer toolbar selectors are present in the binary.
- `codesign --verify --strict`: PASS for the newly built ad-hoc-signed bundle.
- Horos runtime: version 4.0.1 loaded `MedisalePlugin`, bundle version 2, from the isolated temporary plug-in directory.
- Toolbar customization: `Medisale Test` appeared in the real Viewer customization palette and was added to the Viewer toolbar (displayed in the overflow menu at the tested window width).
- Viewer ownership: first action displayed `Viewer Toolbar OK` and `Owning Viewer: Viewer 1`; the duplicated Viewer displayed `Owning Viewer: Viewer 2`; returning to the original again displayed Viewer 1.
- Lifecycle: after Viewer 1 was closed, Viewer 2 continued to display Viewer 2 correctly. Closing Viewer 2 returned Horos to `Documents DB` without a crash.
- No screenshot, DICOM, database, raw runtime log, hostname, username, or other unprocessed environment output is included in this report or prepared for upload.

## Known issues

- Horos reports the ad-hoc plug-in as not Horos-validated, which is expected for this isolated proof of concept.
- Compilation emits ten deprecation warnings originating in the installed Horos framework headers; the plug-in source itself adds no build warning.
- At the tested window width, the custom item is reached through the standard toolbar overflow menu after customization.
- The duplication button exists only to exercise the multiple-Viewer acceptance case with a verified real API; it is not a product feature.

## Architecture impact

- Establishes the verified Viewer-toolbar extension boundary using only actual Horos selectors.
- Associates each `NSToolbarItem` weakly with its owning Viewer and assigns anonymous per-process labels without reading study or patient state.
- Adds no persistence, browser selection access, measurement behavior, or P1-04 functionality.

## Data-safety impact

- No patient data, existing Study, existing Horos Data, existing preferences, or old plug-in was read, copied, or modified.
- Existing dedicated-user Horos files discovered at their path were treated as out of scope; all P1-03 runtime state was redirected to an isolated temporary home.
- The fixture contains no patient name or patient ID and was used only in the isolated runtime database.
- No medical data, images, metadata, logs, or screenshots were sent to an external service.

## Next prerequisites

- Review this P1-03 report and Draft PR.
- Merge requires separate SHIP approval.
- Only after P1-03 is reviewed and merged may P1-04 readiness be assessed separately.

## STOP required

No P1-03 STOP condition was encountered. Stop after opening the Draft PR; do not merge it and do not begin P1-04.
