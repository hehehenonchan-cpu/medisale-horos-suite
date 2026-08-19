# P1-04 Browser Toolbar PoC Report

## Result

**PASS / REVIEW.** Horos 4.0.1 loaded the ad-hoc-signed arm64 bundle, exposed `Medisale Tools Test` in the actual Browser toolbar customization palette, and classified all required Browser selection states without modifying Browser data, the isolated Horos database, or synthetic DICOM files. P1-05 remains blocked.

## Verified facts

- PR #17 approved head `07d7199db2e592598f06143de5d66ffba327468e` had base `main`, a P1-03-only diff, no failed checks or unresolved reviews, and `CLEAN` merge state.
- PR #17 was changed to ready for review and merged with merge commit `9f3a30222dc32451ca827a185c4c0acf40487ae4`, which matched remote `main` before this branch was created.
- Issue #3 was closed as completed. Issue #4 satisfied its Definition of Ready and was moved from `status: blocked` to `status: ready`.
- Branch `spike/p1-04-browser-toolbar` was created directly from `9f3a30222dc32451ca827a185c4c0acf40487ae4`.
- Installed Horos 4.0.1 headers declare `toolbarAllowedIdentifiersForBrowserController:`, `toolbarItemForItemIdentifier:forBrowserController:`, `databaseSelection`, `DicomStudy`, and `DicomSeries`.
- No additional volumes or SMB/NFS network shares were mounted at the isolation gate.
- Runtime tests used two process-specific temporary homes: one empty database and one database containing only two generated, blank-identity synthetic studies.

## Files changed

- `plugin/MedisalePluginFilter.m`: adds the Browser toolbar item and read-only selection classification using verified real Horos APIs.
- `plugin/Info.plist`: advances the proof-of-concept version to 0.3.0 (build 3).
- `Makefile`: verifies the two Browser toolbar selectors and `databaseSelection` reference in the binary.
- `TASKS.md`: records P1-03 complete and P1-04 pass/review without unlocking P1-05.
- `docs/platform/P1_04_BROWSER_TOOLBAR.md`: this anonymized report.

## Tests and evidence

- `make clean && make verify`: PASS.
- Built executable: Mach-O 64-bit bundle, arm64.
- Real API linkage: unresolved Objective-C reference to the actual Horos `PluginFilter` runtime class; no fake API or compatibility shim.
- Static selector checks: both verified Browser toolbar selectors and `databaseSelection` are present in the binary.
- `codesign --verify --strict`: PASS for each newly placed ad-hoc-signed test bundle.
- Horos runtime: version 4.0.1 loaded `MedisalePlugin`, bundle version 3, only from each isolated temporary plug-in directory.
- Browser toolbar customization: `Medisale Tools Test` appeared in the actual Browser palette and was added through standard toolbar customization.
- Empty isolated database: action displayed `Browser Toolbar OK` and `Selection: None`.
- One synthetic Study: action displayed `Selection: Study 1`.
- One synthetic Series: action displayed `Selection: Series 1`.
- Multiple synthetic Studies: action displayed `Selection: Multiple 2 (Studies 2, Series 0, Other 0)`.
- Read-only verification: SHA-256 sets for every isolated Horos database file and both synthetic DICOM fixtures were identical immediately before and after a toolbar action.
- Both Horos sessions exited normally without a crash.
- No screenshot, DICOM, database, raw runtime log, hostname, username, or other unprocessed environment output is included in this report or prepared for upload.

## Known issues

- Horos reports the ad-hoc plug-in as not Horos-validated, as expected for this isolated proof of concept.
- Compilation emits eleven deprecation warnings originating in the installed Horos framework headers; the plug-in source adds no build warning.
- Horos retains a last selection once an item exists, so the no-selection condition was verified separately in a new empty isolated database.
- The selection summary deliberately reports only type and count. It does not read patient attributes, identifiers, or other metadata.

## Architecture impact

- Establishes the verified Browser-toolbar extension boundary using the real Browser controller supplied by Horos.
- Reads a snapshot returned by `databaseSelection` and classifies objects using the public `DicomStudy` and `DicomSeries` classes.
- Adds no persistence, adapter layer, image-context mapping, or P1-05 functionality.

## Data-safety impact

- The action performs no setter, save, delete, import, export, managed-object mutation, DICOM write, or database write.
- No patient data, existing Study, existing Horos Data, existing preferences, or old plug-in was read, copied, or modified.
- The only populated test database contained two generated fixtures with blank patient name and patient ID; the no-selection database contained no studies.
- Both temporary homes, including synthetic fixtures, isolated databases, test bundles, and test preferences, were deleted after clean Horos shutdown.
- No medical data, images, metadata, logs, or screenshots were sent to an external service.

## Next prerequisites

- Review this P1-04 report and Draft PR.
- Merge requires separate SHIP approval.
- Only after P1-04 is reviewed and merged may P1-05 readiness be assessed separately.

## STOP required

No P1-04 STOP condition was encountered. Stop after opening the Draft PR; do not merge it and do not begin P1-05.
