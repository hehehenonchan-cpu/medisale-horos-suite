# P1-07 Overlay Renderer Report

## Result

**PASS / REVIEW.** A transient line overlay was rendered from two image-coordinate endpoints with the real Horos 4.0.1 API. It followed zoom, pan, and Viewer resize, remained isolated by Viewer and image identity, and was removed when the displayed SOP or frame changed. No action-specific database, DICOM, preference, ROI, filesystem, or network persistence was detected. P1-08 remains blocked.

## Verified facts

- The branch was based on the reviewed P1-06 merge commit and contained only P1-07 implementation, build, fixture-generator, task-status, and report changes.
- The test account was the designated standard macOS user. The isolated database was inside that user's home, with no symlink, ownership mismatch, external/shared reference, mounted additional volume, or network share.
- The contained database held only repository-derived synthetic fixtures. No patient, clinical, customer, or unknown data was present.
- The plug-in inventory contained the P1-07 test bundle and one existing signed, validated baseline plug-in. Anonymous identity-collision checks passed; the baseline bundle, signature, and fingerprint remained unchanged.
- Installed Horos headers and the runtime verify the selectors and notifications used: `PluginFilter`, `ViewerController.imageView`, `DCMView.ConvertFromGL2NSView:`, `OsirixDCMViewIndexChangedNotification`, and `OsirixUpdateViewNotification`.

## Files changed

- `plugin/LineOverlayModel.h` and `.m`: hold only image-coordinate A/B values and a copied independent image identity.
- `plugin/TransientLineOverlayController.h` and `.m`: render and own a transient Viewer-bound overlay; redraw on display changes; invalidate on SOP/frame change or Viewer close; release all observers, monitor, timer, subview, and Viewer reference.
- `plugin/MedisalePluginFilter.m`: creates one overlay controller per Viewer after successful P1-06 input and reports sanitized test results.
- `plugin/Info.plist`: advances the isolated proof-of-concept bundle version.
- `Makefile`: compiles the overlay files and verifies the real Horos coordinate conversion and image-change notification symbols.
- `scripts/create_synthetic_multiframe_dicom.py`: creates an identifier-free, two-frame secondary-capture fixture with deterministic synthetic pixels and fresh synthetic identities for frame-isolation testing.
- `TASKS.md`: records P1-06 complete and P1-07 pass/review while leaving P1-08 blocked.
- `docs/platform/P1_07_OVERLAY_RENDERER.md`: this anonymized report.

## Tests and evidence

- `make -B verify`: PASS; produced an arm64 Mach-O bundle against the installed real Horos headers and real `PluginFilter` runtime class.
- Strict ad-hoc signature verification: PASS. Horos 4.0.1 loaded and executed the new test bundle.
- Two image-coordinate endpoints produced a visible transient line whose endpoint locations matched the coordinates reported by the P1-06 input layer.
- At 100% zoom and at a different zoom scale, the line remained attached to the same image locations. Pan and Viewer resize moved the line with the image without changing the model coordinates.
- Changing to a different SOP removed the line. A second Viewer held an independent line; neither Viewer displayed or accepted the other Viewer's overlay state.
- Closing a Viewer removed the overlay subview, notification observers, local event monitor, redraw timer, and weak Viewer reference. Other Viewer state remained intact, all Viewers closed normally, and Horos returned to the database screen.
- Horos exited normally without a new crash report.

### Process-level network sandbox

- The runtime test launched the Horos executable directly below a temporary user-local `sandbox-exec` profile whose default was allow and whose only additional rule denied all network operations.
- A capability test confirmed normal file reads and process execution while denying DNS, IPv4/IPv6 TCP, UDP, loopback, and a sandboxed child process's network operation.
- Firewall, Gatekeeper, and SIP state fingerprints were unchanged. No system firewall, packet-filter, application, signing, or security setting was modified.
- Horos and its descendants remained in the sandbox process tree. Successful network connection count was zero for fixture import and overlay action runs; no cloud, login, sync, upload, or update function was used.
- The profile and monitor retained only anonymous counts. Destinations, hosts, addresses, payloads, local paths, and raw communication logs were not recorded in this report.

### Approved two-frame fixture import and frame isolation

- Before import, the retained fixture passed explicit-VR DICOM syntax validation, exact two-frame validation, exact synthetic pixel-pattern validation, blank patient-name/ID validation, private-tag and identity-field checks, burned-in-annotation checks, new synthetic identity checks, home-containment, symlink, owner, and local SHA-256 evidence checks.
- Under the process-level network sandbox, exactly one approved DICOM file was imported into the isolated database. Import added one Study, one Series, one SOP/DICOM file, and the expected two Horos frame records. No other Study, Series, SOP, DICOM file, or schema object was added or changed.
- The stored DICOM exactly matched the approved two-frame fixture. Pre-existing synthetic DICOM files and persistent records were unchanged, SQLite integrity passed, and external network success remained zero.
- The post-import state became the new semantic baseline. A line created on frame 0 appeared at its expected image-coordinate endpoints. On switching to frame 1, the frame 0 line was absent.
- Frame 1 accepted an independent pair of endpoints and displayed its own line. Returning to frame 0 did not display the frame 1 line. The controller therefore bound overlay ownership to both SOP identity and frame number.
- After action and normal shutdown, schema, Study/Series/image-record counts, synthetic identity fingerprints, selected semantic-record fingerprints, complete DICOM set and hashes, source-fixture hash, and SQLite integrity were identical to the new baseline.

### Database mutation attribution

- Snapshots were taken only with Horos fully closed, through read-only SQLite connections with `query_only`, inspected schema, integrity checks, semantic record fingerprints, DICOM set/hash fingerprints, and per-file local evidence.
- Prior no-action control and overlay-action runs both reproduced ordinary Horos database-bundle hash changes while schema, synthetic identity sets, semantic records, DICOM contents, and integrity remained unchanged.
- The final two-frame action run also changed the aggregate database-bundle hash, affecting two Horos-maintained files. This mismatch is retained and not hidden.
- No action-only schema, Study, Series, frame record, identity, DICOM, or selected persistent-value change occurred. The semantic evidence and the control reproduction attribute aggregate-only differences to normal Horos launch/Viewer/exit bookkeeping, not P1-07 persistence.
- Actual UIDs, hashes, filenames, local paths, usernames, device identifiers, screenshots, and raw database or application logs are intentionally omitted.

### Static write-path audit

- P1-07 source contains no Core Data save or managed-object mutation, database connection or SQL, Horos database mutation API, DICOM write, filesystem write, defaults persistence, network operation, or ROI creation/change/save.
- Drawing uses a non-interactive `NSView` subview and `NSBezierPath`. It does not create or modify a standard Horos ROI.
- The line model contains only two `NSPoint` values and an independent copied `ImageContext`; it stores no display coordinate and no Horos runtime object.

## Known issues

- The database-bundle aggregate hash changes during ordinary Horos use. Control/action attribution found no P1-07-specific semantic or DICOM change.
- The user-approved baseline plug-in remains loaded but is not used or referenced by P1-07. Runtime tests therefore require the process-level network sandbox; successful connections remained zero.
- Network denial causes Horos's DICOM listener startup to report an expected unavailable-network warning. The warning was dismissed without changing settings.
- The isolated test launch used a process-only English localization argument because the installed localized resources are not readable in this environment; no defaults or application file was changed.
- During an earlier coordinate-based test step, a delete confirmation was opened accidentally and cancelled immediately. Subsequent semantic and DICOM comparisons confirmed that nothing was deleted or changed.
- Horos reports the ad-hoc test plug-in as not Horos-validated, as expected for this isolated proof of concept.
- Deprecation warnings originate in the installed Horos headers; P1-07 adds no build error.
- Toolbar/menu entries, thick high-contrast line styling, markers, and alerts are spike-only test surfaces, not product UI.

## Architecture impact

- Image-coordinate A/B remain the sole coordinate truth. `ConvertFromGL2NSView:` is used only at draw time to project them into the current Viewer.
- Overlay ownership is scoped by Viewer plus independent SOP/frame identity. A different SOP or frame invalidates rather than reusing the overlay.
- The overlay view is transient, non-interactive, and outside Horos's ROI model. P1-08 endpoint editing is not implemented.
- Horos runtime objects remain inside the adapter/controller boundary and do not enter `ImageContext` or the measurement-side consumer.

## Data-safety impact

- Tests used only known synthetic fixtures in the designated user's contained database. No patient, clinical, customer, existing Study, or unknown data was accessed.
- The only intentional database/DICOM change was the explicitly approved import of one new two-frame synthetic fixture. That post-import state was the action baseline.
- P1-07 actions produced no semantic database, DICOM, defaults, ROI, filesystem, or network change. All DICOM hashes were unchanged from the new baseline.
- The existing signed, validated baseline plug-in was neither changed nor used. The dedicated database and all fixtures were retained in place and were not deleted, moved, repaired, or reconfigured.
- No DICOM, image, metadata, screenshot, raw log, database content, path, identifier, or communication detail was sent externally or published.

## Next prerequisites

- Review this P1-07 report and Draft PR.
- Merge requires separate SHIP approval.
- Only after P1-07 is reviewed and merged may P1-08 readiness be assessed separately.

## STOP required

No P1-07 STOP condition remains. Stop after opening the Draft PR; do not close Issue #7, merge the Draft PR, or begin P1-08.
