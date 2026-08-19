# P1-06 Two Point Input Report

## Result

**PASS / REVIEW.** The real Horos 4.0.1 API captured two points as image coordinates, rejected clicks outside the image, cancelled safely with Escape, remained correct after 100% zoom and pan, and kept two Viewer input sessions isolated. A control/action comparison found no P1-06-specific persistent database, DICOM, or preference mutation. P1-07 remains blocked.

## Verified facts

- Issue #6 was open with `status: ready`, and the branch was based on the reviewed P1-05 merge commit.
- The resumed worktree contained only the five P1-06 implementation/build files; no change was reset, discarded, or overwritten.
- The test account was the designated standard macOS user. The dedicated Horos database was inside that user's home, with no symlink, owner mismatch, external/shared reference, additional volume, network share, or old plug-in.
- The contained database held two Studies, two Series, and three Instances. Every item was traced to a known synthetic fixture; patient information and unknown data counts were zero.
- Installed Horos headers verify the runtime types and selectors used: `PluginFilter`, `ViewerController.imageView`, `DCMView.curDCM`, `DCMView.mouseXPos`, `DCMView.mouseYPos`, and `DCMPix.pwidth`/`pheight`.

## Files changed

- `plugin/TwoPointInputController.h` and `.m`: Viewer-bound two-point state, image-coordinate capture, bounds rejection, Escape/window-close cancellation, and lifecycle cleanup.
- `plugin/MedisalePluginFilter.m`: per-Viewer controller ownership, Viewer toolbar/menu test entry points, and sanitized result alerts.
- `Makefile`: compiles the controller and verifies linkage to the real `mouseXPos` selector.
- `plugin/Info.plist`: advances the proof-of-concept version to 0.5.0 (build 5).
- `TASKS.md`: records P1-05 complete and P1-06 pass/review without unlocking P1-07.
- `docs/platform/P1_06_TWO_POINT_INPUT.md`: this anonymized report.

## Tests and evidence

- `make -B verify`: PASS; produced an arm64 Mach-O bundle using the installed real Horos headers and the real `PluginFilter` runtime class.
- Strict ad-hoc signature verification: PASS. The signature has no team identity, as expected for the isolated spike bundle.
- Horos 4.0.1 loaded and ran the new bundle in the dedicated user's isolated plug-in directory.
- At 100% zoom, known display clicks produced the expected image-coordinate A/B values. After pan, clicks at the same image locations produced the same image-coordinate values even though their display positions changed.
- A click outside the image was rejected without damaging the pending state. Escape produced a cancelled result with no incomplete point retained.
- Two Viewer windows each completed independent input. A point, cancel, and completion in one Viewer did not change the other Viewer's state, and an event belonging to the other Viewer was not accepted.
- Completing or cancelling input removed the local event monitor. Closing a Viewer during input removed both the monitor and window-close observer without affecting the remaining Viewer.
- Horos exited normally without a crash in the functional run, the no-action control run, and the P1-06 action run.

### Database mutation attribution

- With Horos closed, each snapshot used a read-only SQLite URI, `query_only`, the inspected live schema, and an integrity check. No private table or column was queried before schema inspection.
- The baseline contained 17 database-bundle files. Schema, Study/Series/Instance counts, synthetic Study/Series/SOP identity-set fingerprints, stored-DICOM file-set fingerprint, selected persistent-record fingerprints, per-file size/hash, and source-fixture hashes were measured locally.
- The control run opened the same synthetic fixture in two Viewers, used 100% zoom and pan, did not start the P1-06 action, and exited normally.
- The database-bundle aggregate hash changed during the control run. One database-related file changed while file count, schema, Study/Series/Instance counts and identities, selected persistent values, stored-DICOM set, source DICOM, and SQLite integrity remained unchanged.
- Control changes were limited to Horos-maintained open/display state, zoom/pan/window state, and Core Data generation metadata.
- The action run used the same contained data and two-Viewer configuration, exercised successful two-point input, out-of-image rejection, Escape cancellation, and Viewer isolation, then exited normally.
- The aggregate hash also changed during the action run. It was again the same class of single database-related file; the changed column categories were a strict subset of those reproduced by the control run, with zero action-only changed columns.
- Schema, the two/two/three semantic record counts, synthetic identity sets, selected persistent record values, all three stored DICOM files, both source fixture files, and SQLite integrity remained unchanged from baseline through action completion.
- The aggregate-hash mismatch is retained as evidence and is not hidden. The control reproduction, identical semantic fingerprints, and absence of action-only changes attribute it to ordinary Horos launch/Viewer/exit bookkeeping rather than P1-06 persistence.
- Actual UIDs, hashes, filenames, local paths, usernames, device identifiers, screenshots, and raw database/log contents are intentionally omitted.

### Static write-path audit

- P1-06 source contains no Core Data save, managed-object mutation, database connection, SQL execution, filesystem write, DICOM write, defaults persistence, ROI creation/save, or Horos database mutation API.
- The implementation stores only two `NSPoint` values in process memory and displays a transient result alert.
- The owning Viewer is weakly referenced. A weak-key/strong-value map scopes one input controller to each Viewer and releases it after completion or cancellation.

## Known issues

- The whole database-bundle aggregate hash changes across ordinary Horos runs. The no-action control reproduced this, while all semantic fixture and DICOM evidence remained unchanged.
- Horos reports the ad-hoc plug-in as not Horos-validated, as expected for an isolated proof of concept.
- Deprecation warnings originate in the installed Horos headers; P1-06 adds no build error.
- The menu, toolbar item, and result alerts are spike-only test surfaces, not product UI.

## Architecture impact

- Two-point input is isolated in a Viewer-bound controller and uses real image-coordinate truth from `DCMView` after Horos has applied its zoom/pan transform.
- Event acceptance requires the event window to match the owning Viewer, preventing cross-Viewer point or Escape handling.
- No Horos runtime object enters the existing independent `ImageContext` or measurement-side consumer.
- Overlay rendering, endpoint editing, persistence, and every P1-07-or-later behavior remain unimplemented.

## Data-safety impact

- Tests used only known synthetic fixtures in the designated user's contained database. No patient, clinical, customer, or unknown data was present.
- P1-06 performs no write to DICOM, the Horos database, preferences, defaults, or the filesystem.
- The two source fixture hashes and all three stored-DICOM hashes were unchanged through control and action runs.
- Horos itself updated ordinary Viewer/open-state metadata in both control and action runs; no action-specific semantic persistence was detected.
- The dedicated database was retained in place and was not deleted, moved, repaired, or reconfigured.
- No DICOM, image, metadata, raw log, screenshot, or database content was sent externally.

## Next prerequisites

- Review this P1-06 report and Draft PR.
- Merge requires separate SHIP approval.
- Only after P1-06 is reviewed and merged may P1-07 readiness be assessed separately.

## STOP required

No P1-06 STOP condition remains. Stop after opening the Draft PR; do not close Issue #6, merge the Draft PR, or begin P1-07.
