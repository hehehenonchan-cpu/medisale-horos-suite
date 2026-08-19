# P1-05 HorosAdapter Foundation Report

## Result

**PASS / REVIEW.** HorosAdapter generated an independent ImageContext for the current Horos image. Every required field matched the known synthetic fixture, the context followed an image switch, and no Horos runtime object crossed into the measurement-side consumer. P1-06 remains blocked.

## Verified facts

- PR #18 approved head `101fd26af1a5aadec2e3b69b158265d3d924abe0` had base `main`, a P1-04-only diff, passing local verification, no failed checks or unresolved reviews, and `CLEAN` merge state.
- PR #18 was merged as `939d74b48e4aaf7839a811736a5e8b89457c76c7`, matching remote `main` before this branch was created.
- Issue #4 was closed as completed. Issue #5 satisfied its Definition of Ready and was moved to `status: ready`.
- Branch `spike/p1-05-horos-adapter` was created directly from that verified merge commit.
- Installed Horos 4.0.1 headers verify every runtime API used: current image, current DCMPix, Study/Series/SOP UID accessors, frame number, dimensions, and pixel spacing.
- No additional volumes, SMB/NFS shares, or old plug-ins were present at the isolation gate.

## Files changed

- `plugin/ImageContext.h` and `.m`: independent Foundation value model containing copied scalar/string values only.
- `plugin/HorosAdapter.h` and `.m`: the sole boundary that accesses Horos runtime objects and constructs ImageContext.
- `plugin/MeasurementContextConsumer.h` and `.m`: consumes ImageContext without importing or retaining Horos types.
- `plugin/MedisalePluginFilter.m`: invokes the adapter for the current Viewer and displays the independent context for the spike test.
- `scripts/create_synthetic_dicom.py`: adds a reproducible two-image context fixture mode with known identifiers, dimensions, spacing, and instance numbers.
- `Makefile`: builds all boundary files and verifies real API linkage and architectural separation.
- `plugin/Info.plist`: advances the proof-of-concept version to 0.4.0 (build 4).
- `TASKS.md`: records P1-04 complete and P1-05 pass/review without unlocking P1-06.

## Tests and evidence

- `make clean && make verify`: PASS; arm64 Mach-O bundle and strict ad-hoc signature verified.
- Real `PluginFilter` and real OsiriXAPI/Horos runtime symbols are referenced; no fake API or compatibility shim exists.
- Static boundary check confirms ImageContext and MeasurementContextConsumer contain no ViewerController, DCMPix, DicomImage, NSManagedObject, or ROI type.
- Horos 4.0.1 loaded bundle version 4 from the isolated temporary plug-in directory.
- First synthetic image: Study, Series, and SOP identifiers, frame 0, 64 by 64 dimensions, and the known X/Y pixel spacing all matched the fixture.
- After switching to the second image, a newly generated context contained the second SOP identifier while Study, Series, frame, dimensions, and spacing remained correct. The first SOP was not reused.
- The initial Series property was observed to contain a Horos display prefix; the adapter was corrected to use the header-verified raw DICOM Series UID accessor and the complete test was repeated successfully.
- SHA-256 sets for every isolated database file and both synthetic DICOM files were identical immediately before and after context generation.
- Horos exited normally without a crash.
- Evidence records matches and structural facts only; no actual UID, screenshot, raw log, local path, username, or device identifier is published.

## Known issues

- Horos reports the ad-hoc plug-in as not Horos-validated, as expected for an isolated proof of concept.
- Deprecation warnings originate in installed Horos headers; the P1-05 source adds no warning.
- The fixture uses two single-frame DICOM instances, so the explicitly verified current frame is zero for both images.
- The Viewer menu action and context alert are spike-only test surfaces, not product UI.

## Architecture impact

- HorosAdapter is the only component permitted to access Horos runtime objects.
- ImageContext owns copied identifiers and scalar values and retains no Horos object.
- The measurement-side consumer imports only ImageContext and Foundation.
- No two-point input, overlay, editing, persistence, or P1-06 behavior is included.

## Data-safety impact

- Tests used only two generated DICOM images with blank patient name and patient ID in a process-specific temporary home.
- Context generation performs no setter, save, delete, import, export, managed-object mutation, DICOM write, or database write.
- Existing Horos data, preferences, studies, and old plug-ins were not read, copied, or modified.
- The temporary home, synthetic fixtures, isolated database, bundle, and test settings were deleted after clean shutdown.
- No medical data, images, metadata, logs, or screenshots were sent externally.

## Next prerequisites

- Review this P1-05 report and Draft PR.
- Merge requires separate SHIP approval.
- Only after P1-05 is reviewed and merged may P1-06 readiness be assessed separately.

## STOP required

No P1-05 STOP condition remains. Stop after opening the Draft PR; do not close Issue #5, merge the Draft PR, or begin P1-06.
