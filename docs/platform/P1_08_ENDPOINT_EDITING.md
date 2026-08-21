# P1-08 Endpoint Editing Report

## Result

**PASS / REVIEW.** Endpoint A and endpoint B can be selected and dragged independently while image coordinates remain the sole model truth. Coordinates and pixel distance update live, editing remains correct after zoom, pan, and Viewer resize, and events do not leak across images, frames, or Viewers. Normal Horos tools remain available outside endpoint hit targets. No P1-08-specific database, DICOM, defaults, ROI, filesystem, or network persistence was detected. P1-09 remains blocked.

## Verified facts

- The branch is based on the reviewed P1-07 merge commit and contains only P1-08 implementation, build verification, task status, and this report.
- The test account is the designated standard macOS user. The isolated database and plug-in directory are contained inside that user's home, without symlinks, ownership mismatch, external/shared references, additional mounted volumes, or network shares.
- The database contains only known synthetic fixtures, including the previously approved two-frame fixture. No patient, clinical, customer, existing, or unknown data was present.
- The installed Horos 4.0.1 headers and runtime confirm the real APIs used for input and coordinate conversion, including `PluginFilter`, `ViewerController.imageView`, `DCMView.ConvertFromGL2NSView:`, and `DCMView.ConvertFromNSView2GL:`. No fake API, compatibility shim, or inferred selector was added.
- The P1-08 candidate bundle has no identifier, principal-class, or executable-name collision with the immutable baseline plug-in and passed strict ad-hoc signature verification.
- 既存のimmutable baseline plugin 1件はstrict署名検証非合格の既知状態であり、試験前後でfingerprint、検証結果、認識状態が不変だった

## Files changed

- `plugin/LineOverlayModel.h` and `.m`: add controlled image-coordinate endpoint mutation and computed pixel distance while retaining the independent image identity.
- `plugin/TransientLineOverlayController.m`: add endpoint hit testing, selection, drag, live redraw, Escape rollback, bounded outside-image handling, event conflict isolation, and cleanup.
- `plugin/Info.plist`: advances the isolated proof-of-concept bundle version.
- `Makefile`: verifies the real reverse coordinate conversion symbol and endpoint-distance implementation.
- `TASKS.md`: records P1-07 complete and P1-08 pass/review while leaving P1-09 blocked.
- `docs/platform/P1_08_ENDPOINT_EDITING.md`: this anonymized report.

## Tests and evidence

- `make -B verify`: PASS. It produced an arm64 Mach-O bundle against the installed real Horos headers and the real `PluginFilter` runtime class. Strict ad-hoc signature verification passed.
- The isolated bundle was the only newly deployed test bundle. Horos 4.0.1 recognized, enabled, loaded, and executed it.
- Model verification: PASS with six assertions covering initial distance, independent endpoint A/B updates, live distance changes, and copied independent image identity.
- Endpoint A and B were each selected and dragged independently. The displayed image-coordinate values and pixel distance changed live and matched the model results.
- At 100% zoom and another zoom scale, after pan, and after Viewer resize, endpoint hit testing and dragging continued at the same image-coordinate locations. Display changes did not become model state.
- Escape during a drag restored the exact pre-drag image coordinate and cleared selection. Dragging outside the image was handled safely by bounding the point to the valid image extent.
- Clicking or dragging outside endpoint hit targets remained available to the active Horos tool. A normal pan operation changed the display while leaving the endpoint model unchanged; endpoint editing still worked afterward.
- Switching SOP identity removed the old edit surface. Frame 0 state did not appear on frame 1, and frame 1 state did not appear when returning to frame 0.
- Two Viewer windows remained independent: selecting and editing an endpoint in one did not create, move, select, or consume state in the other. An incomplete synthetic context in the other Viewer was rejected safely.
- Closing a Viewer while an endpoint was selected removed the overlay and edit state without affecting the remaining Viewer. Observers, local event monitor, timer, subview, model link, and Viewer reference were released. All Viewers closed, Horos returned to the database screen, and Horos exited normally without a crash.

### Process-level network sandbox

- Runtime testing launched the Horos executable directly under a temporary process-level sandbox whose only additional policy denied all network operations. Horos descendants remained within the sandbox process tree.
- The capability gate allowed normal file reads and process execution while denying DNS, IPv4/IPv6 TCP, UDP, loopback, listener creation, and a sandboxed child's network operation.
- Successful network connections were zero throughout the Horos run. Wi-Fi stayed active and recorded zero state transitions; no Wi-Fi, proxy, DNS, packet-filter, firewall, or network-service setting was changed.
- Horos, its child, the sandbox wrapper, and the anonymous monitor all terminated. Temporary profiles, screenshots, and raw local monitoring artifacts were excluded from Git.
- No cloud login, synchronization, upload, or update action was used. Destinations, addresses, payloads, hostnames, paths, and raw communication logs are intentionally omitted.

### Baseline plug-in immutability

- Before and after the test, the immutable baseline bundle had identical content and metadata fingerprints, root metadata, resource/file sets, sizes, modification times, modes, and per-entry records.
- Strict signature verification returned the same expected failure, the same classified failure category, and the same anonymous output fingerprint before and after the run.
- Horos recognition, validated/enabled presentation, and plug-in inventory were unchanged. P1-08 neither referenced nor operated the baseline plug-in.

### Database and DICOM comparison

- Read-only measurements were taken with Horos fully closed and used an inspected SQLite schema, query-only connections, semantic record fingerprints, DICOM set/content fingerprints, and SQLite integrity checks.
- Schema, Study/Series/Instance counts and synthetic identity sets, selected persistent values, DICOM file set, and all synthetic DICOM content were unchanged from the pre-action semantic baseline. SQLite integrity passed.
- The aggregate database-bundle fingerprint changed in one Horos-maintained file. This mismatch is retained and not hidden. P1-07 control attribution already reproduced ordinary Horos bookkeeping changes, while the P1-08 comparison found no action-specific schema, record, identity, or DICOM change.
- Actual identities, hashes, filenames, local paths, usernames, device identifiers, screenshots, raw database content, and raw logs are intentionally omitted.

### Static write-path audit

- P1-08 source contains no Core Data save or managed-object mutation, database connection or SQL, Horos database mutation API, DICOM write, filesystem write, defaults persistence, network operation, or ROI creation/change/save.
- Endpoint editing mutates only `NSPoint` values in the transient `LineOverlayModel`. The model retains no display coordinates and no Horos runtime object.
- The overlay remains a non-interactive `NSView` drawing surface rather than a standard Horos ROI. Only handled endpoint events are consumed; all other events are returned to Horos.

## Known issues

- The immutable baseline plug-in remains in its approved strict-signature-failure state. It was not repaired, re-signed, moved, disabled, accessed, or changed.
- The database-bundle aggregate fingerprint changes during ordinary Horos launch/Viewer/exit bookkeeping. Semantic database state, DICOM contents, and integrity remained unchanged, and no P1-08-specific persistence was detected.
- Network denial causes an expected DICOM listener unavailable-network warning. It was dismissed without changing settings.
- The isolated launch used a process-only English localization argument because an installed localized resource is unreadable in this environment; no default, application file, or system setting was changed.
- Horos reports the ad-hoc test plug-in as not Horos-validated, as expected for this isolated proof of concept.
- Deprecation warnings originate in the installed Horos headers; P1-08 adds no build error.
- Endpoint rings, the coordinate/distance label, hit radius, and styling are spike-only test surfaces, not final product UI.

## Architecture impact

- Image-coordinate A/B remain the only endpoint truth; display coordinates are calculated only for drawing and hit testing.
- Endpoint edits stay inside the Viewer-bound transient overlay controller. The measurement model receives independent values and image identity, never Horos runtime objects.
- Edit ownership remains bound to Viewer, SOP identity, and frame number. A mismatch invalidates the overlay and cancels active interaction instead of reusing state.
- Event handling is narrow: endpoint hits and active drags are consumed, while normal Horos tool events pass through unchanged.
- P1-09 measurement panel hosting is not implemented.

## Data-safety impact

- Testing used only retained, known synthetic fixtures in the designated user's contained database. No patient, clinical, customer, existing Study, or unknown data was accessed.
- P1-08 actions produced no semantic database, DICOM, defaults, ROI, filesystem, or network change. Synthetic DICOM contents were unchanged.
- The baseline plug-in remained immutable and unused. Horos.app and macOS security/network settings were not modified.
- No DICOM, image, metadata, screenshot, raw log, database content, local identifier, or communication detail was sent externally or published.

## Next prerequisites

- Review this P1-08 report and Draft PR.
- Merge requires separate SHIP approval.
- Only after P1-08 is reviewed and merged may P1-09 readiness be assessed separately.

## STOP required

No P1-08 STOP condition remains. Stop after opening the Draft PR; do not close Issue #8, merge the Draft PR, or begin P1-09.
