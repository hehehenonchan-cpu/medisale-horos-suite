# P1-12 Reload / Restore Report

## Result

**PASS / REVIEW.** Measurements saved by the P1-11 standalone SQLite store are now restored only to an open Viewer whose independent `ImageContext` exactly matches the stored Study, Series, SOP Instance UID, and frame number. Restored endpoints remain image-coordinate values, the transient overlay follows zoom, pan, and resize, and exact restoration passed after Viewer close/reopen and Horos exit/relaunch. Other images, other frames, Viewers without a matching record, and unopened targets received no substitute overlay. No P1-13 lifecycle/stability work was implemented.

## Verified facts

- The branch is based on the reviewed P1-11 merge commit and contains only P1-12 implementation, verification, task status, and this report.
- The runtime account was the designated standard macOS user. The isolated Horos database, known synthetic fixtures, candidate plug-in, and P1-11 standalone store were contained inside that user's home without symlinks, ownership mismatch, external/shared references, additional mounted volumes, or network shares.
- The isolated database contained only known synthetic fixtures: three Studies, three Series, five Instances, and four stored DICOM files. Identifying data, unknown data, private tags, and burned-in patient annotations were zero.
- Installed Horos 4.0.1 headers and runtime objects, the real `PluginFilter`, real OsiriXAPI notification constants, the public Viewer list, and public SQLite APIs were used directly. No fake API, compatibility shim, inferred selector, private schema guess, or standard ROI was introduced.
- Restore opens only the P1-11 standalone database using no-follow, read-only, full-mutex, query-only access after canonical-home, ownership, file-type, and symlink validation.
- Restore requires non-empty Study, Series, and SOP identities plus a valid frame and dimensions. The query matches all four identities, returns the latest exact record, and reconstructs an independent Foundation measurement value using the current independent `ImageContext`.
- Restored records are rejected when endpoints are outside the current image, distance is inconsistent, schema is unsupported, timestamps are invalid, or any required identity is incomplete.
- The candidate bundle had no identifier, principal-class, or executable-name collision with the immutable baseline plug-in and passed strict ad-hoc signature verification.
- The existing immutable baseline plug-in (one bundle) was not accessed by P1-12 and had an identical prospective content manifest, file/resource set, signature result/classification, and Horos recognition state before and after testing.

## Files changed

- `plugin/MeasurementPersistenceStore.h`: adds a replaceable exact-image restore boundary.
- `plugin/SQLiteMeasurementStore.m`: adds contained query-only database access, exact Study/Series/SOP/frame lookup, and restored-value validation.
- `plugin/MedisalePluginFilter.m`: observes verified Viewer/image notifications, scans public open Viewers, restores exact records, and removes stale overlays immediately.
- `plugin/MeasurementPanelHost.h`, `plugin/ViewerInspectorPanelHost.h`, and `plugin/ViewerInspectorPanelHost.m`: allow a restored record to retain its identifier/creation time and report restored state without an implicit write.
- `plugin/TwoPointInputController.h` and `plugin/TwoPointInputController.m`: add deterministic monitor, observer, completion, point, and Viewer-reference invalidation.
- `plugin/Info.plist`: advances the isolated proof-of-concept bundle version.
- `tests/PersistenceStoreTests.m`: covers exact restore, wrong SOP, wrong frame, latest update, multiple images/Viewers, bounds rejection, and reopen restore.
- `Makefile`: verifies read-only/query-only restore and lifecycle boundaries.
- `TASKS.md`: records P1-11 complete and P1-12 pass/review while leaving P1-13 blocked.
- `docs/platform/P1_12_RELOAD_RESTORE.md`: this anonymized report.

## Tests and evidence

- `make -B verify`: PASS. It produced an arm64 Mach-O candidate against installed real Horos headers and the real `PluginFilter` runtime class. Strict ad-hoc signature verification passed.
- The Foundation persistence harness completed 62 assertions. It verified exact Study/Series/SOP/frame restoration, unchanged image-coordinate endpoints, no record for a wrong SOP or frame, latest transactional update selection, independent second-image restoration, invalid/out-of-bounds rejection, reopen persistence, and SQLite integrity.
- `/usr/bin/leaks --atExit` reran the 62-assertion harness and reported zero leaked allocations.
- The candidate loaded in Horos 4.0.1 from the designated user's plug-in directory. Only the newly built candidate was ad-hoc signed.
- A retained P1-11 synthetic measurement was intentionally saved to the standalone store and reported save success. That post-save state became the restore semantic baseline.
- Closing its Viewer removed the panel and overlay. Reopening the same synthetic image/frame restored the same image-coordinate endpoints and pixel distance automatically.
- Normal Horos exit followed by sandboxed relaunch restored the same record to the same synthetic image/frame without a user invoking a load command.
- Switching from the recorded image to a different synthetic image removed the old overlay immediately. The different image received no substitute overlay.
- On the approved two-frame synthetic fixture, frame zero restored its exact overlay, frame one showed none, and returning to frame zero restored the original overlay. The same separation passed again after Horos relaunch.
- A second Viewer remained operational and did not receive the first Viewer's overlay when the owning Viewer was closed. Independent Viewer ownership and cleanup were observed without crossed overlay state.
- Changing zoom, panning the image, and resizing the Viewer moved the transient overlay with the image while its displayed image-coordinate endpoint values and distance remained unchanged.
- Record-not-found, wrong-SOP, wrong-frame, updated-record, unopened-target, and reopened-store behavior passed through the runtime checks and/or the 62-assertion store harness. No fallback to another record was observed.
- Viewer close emitted the expected local deallocation sequence for the Viewer controller, window, study/series views, and image view. Horos returned to the database screen and exited normally with no crash report or remaining process.

### Restore and lifecycle boundary

- `MedisalePluginFilter` registers only verified Horos notification constants and coalesces restore work onto the main queue.
- Each restore pass obtains a fresh independent `ImageContext` from `HorosAdapter`. An active overlay survives only while Study, Series, SOP, and frame identities all match the current image.
- A mismatch invalidates the old transient overlay and its panel before any lookup. A missing, invalid, or unopened record produces no overlay and no alternative lookup.
- Restored overlays reuse the existing P1-07 image-coordinate renderer; display coordinates are calculated only during drawing and are never persisted.
- Viewer keys are weak and Viewer-owned values are strongly retained only while active. Viewer close, overlay invalidation, panel close, plug-in unload, and input cancellation remove observers, event monitors, completions, points, panels, overlays, and Viewer references.
- The restore read path never calls the save boundary. A write occurs only when the user explicitly presses the existing P1-11 save control.

### Process-level network sandbox

- Runtime Horos was launched directly under the previously validated temporary process-level sandbox whose only added policy denied all network operations. Horos descendants inherited the policy; Wi-Fi and system network settings remained unchanged.
- The capability gate allowed ordinary file reads and process execution while denying DNS, TCP, UDP, loopback, listener creation, and child-process network operations.
- The valid no-action control run sampled the Horos process tree 274 times and observed zero network descriptors and zero successful connections.
- The complete valid relaunch/action run sampled the Horos process tree 1,301 times and observed zero network descriptors and zero successful connections. No cloud login, synchronization, upload, or update operation was used.
- Network denial produced the expected unavailable-listener alert. It was dismissed without changing a setting, and the remaining Viewer and restore tests continued normally.
- Preliminary monitoring/launch attempts were invalidated after harness or localization-selection procedure errors. They were excluded, left no running Horos process, changed no system setting or protected data, and were replaced from the beginning by the complete valid run above.
- Destinations, addresses, payloads, hostnames, paths, screenshots, and raw communication logs are intentionally omitted. Temporary profiles, probes, monitors, screenshots, and raw local evidence were excluded from Git.

### Database, DICOM, preference, store, and baseline comparison

- Read-only measurements used the inspected Horos SQLite schema, query-only connections, semantic record fingerprints, synthetic identity-set fingerprints, DICOM set/content fingerprints, and SQLite integrity checks with Horos closed.
- The no-action control run reproduced an aggregate Horos database-bundle fingerprint change while schema, Study/Series/Instance counts and semantic sets, DICOM set/content, and SQLite integrity remained unchanged.
- Between the post-save semantic baseline and the final relaunch/action state, Horos schema, Study/Series/Instance counts and known synthetic identity sets, DICOM set/content, P1-10 preference, Horos.app, and both SQLite integrity checks were unchanged.
- The P1-11 standalone store's schema, record count, complete semantic record set, and integrity were unchanged by close/reopen, frame/image switching, rendering, and Horos relaunch. Only the explicit pre-baseline save changed a standalone measurement record as authorized.
- Aggregate Horos database-bundle and standalone SQLite-directory fingerprints changed during ordinary Horos/SQLite bookkeeping. These mismatches are retained and not hidden; the complete semantic sets and integrity were unchanged, so P1-12 action-specific protected or standalone semantic mutation was zero.
- The immutable baseline plug-in's prospective content manifest, file/resource set, signature result/classification, and Horos recognition state were identical before and after. It was not moved, repaired, re-signed, disabled, copied, invoked, or depended upon.
- Actual identities, coordinates, UIDs, values, hashes, filenames, local paths, usernames, device identifiers, signature details, screenshots, raw database content, and raw logs are intentionally omitted.

### Static write-path and content audit

- The production P1-12 diff adds no Core Data save, managed-object mutation, Horos database API, DICOM write, ROI create/change/save, defaults write, filesystem write, or independent network API.
- Only `SQLiteMeasurementStore` imports or calls SQLite in production. The new restore connection is explicitly read-only and query-only; the existing P1-11 transactional write path remains the sole measurement write path.
- `MeasurementRecord`, `MeasurementPersistenceStore`, and the SQLite store contain no Viewer controller, pixel object, ROI, managed object, Horos database object, or DICOM runtime object.
- Viewer, panel, overlay, measurement model, adapter, and restore orchestration code contain no SQL, database path, or Horos persistence logic.
- The public diff contains no patient data, DICOM, database, fixture, candidate bundle, binary, signature identity, screenshot, raw log, local path, username, device identifier, or baseline plug-in identifier.

## Known issues

- This remains an isolated platform spike using the P1-11 standalone schema. It has no production migration, encryption, retention, audit, recovery, multi-process coordination, or clinical validation design.
- The aggregate Horos database-bundle and standalone SQLite-directory fingerprints can change during ordinary Horos/SQLite bookkeeping even when semantic data and integrity are unchanged.
- Network denial produces an expected unavailable-listener warning. No system network or security setting was changed and no connection succeeded.
- Direct executable launch required a transient process-only language selection because another installed localization resource was unreadable to the designated user. Horos.app, its permissions, and user defaults were not changed.
- Horos reports the ad-hoc candidate as not Horos-validated, as expected for an isolated proof of concept.
- Deprecation warnings originate in installed Horos headers; P1-12 adds no build error.

## Architecture impact

- `MeasurementPersistenceStore` is now a replaceable read/write boundary. P1-12 adds exact-image read semantics without exposing SQLite or a path to the Viewer, panel, overlay, or measurement domain.
- The standalone store reconstructs only independent Foundation values and the caller's independent `ImageContext`; it never retains a Horos runtime object.
- Restore orchestration remains in the Horos adapter edge: verified Viewer notifications trigger fresh context extraction, exact lookup, and transient rendering.
- Overlay ownership is explicitly bound to one Viewer and exact Study/Series/SOP/frame identity. There is no cross-Viewer or fallback rendering path.
- Lifecycle cleanup is explicit at input, overlay, panel, Viewer, and plug-in boundaries. P1-13 stability-loop work was not added.

## Data-safety impact

- Testing used only retained, known synthetic fixtures in the designated user's contained environment. No patient, clinical, customer, existing Study, or unknown data was accessed.
- P1-12 actions produced no semantic Horos database, DICOM, ROI, Horos preference, baseline plug-in, Horos.app, network, or macOS security-setting change.
- The only authorized measurement write was an explicit save to the P1-11 plug-in-owned standalone SQLite store before the restore baseline. All subsequent restore actions were read-only with respect to that store.
- No DICOM, image, metadata, screenshot, raw log, database content, local identifier, signature detail, or communication detail was sent externally or published.

## Next prerequisites

- Review this P1-12 report and Draft PR.
- Merge requires separate SHIP approval.
- Only after P1-12 is reviewed and merged may P1-13 readiness be assessed separately.
- Post-Platform Issues remain blocked; no Compact UI, Space-PAN, clinical measurement, or validation-data work was started.

## STOP required

No P1-12 STOP condition remains. Stop after opening the Draft PR; do not close Issue #12, merge the Draft PR, mark Issue #13 ready, begin P1-13, or change Post-Platform Issues.
