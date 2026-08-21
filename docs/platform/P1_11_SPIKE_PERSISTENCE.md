# P1-11 Spike Persistence Report

## Result

**PASS / REVIEW.** Completed spike measurements can now be saved transactionally to a plug-in-owned standalone SQLite database. The store accepts only an independent measurement value and `ImageContext`, contains its own path, schema, connection, statement, transaction, and rollback logic, and returns success only after commit. Normal saves, same-record updates, two-Viewer/image separation, persistence across Horos exit, and all required failure paths passed. No P1-12 restore or overlay rehydration was implemented.

## Verified facts

- The branch is based on the reviewed P1-10 merge commit and contains only P1-11 implementation, verification, task status, and this report.
- The runtime account was the designated standard macOS user. The isolated Horos database, synthetic fixtures, plug-in directory, and P1-11 store were contained inside that user's home without symlinks, ownership mismatch, external/shared references, additional mounted volumes, or network shares.
- The Horos database contained only retained, known synthetic fixtures: three Studies, three Series, five Instances, and four stored DICOM files. Identifying data, unknown data, private tags, and burned-in patient annotations were zero.
- Installed Horos 4.0.1 headers and runtime objects, the real `PluginFilter`, OsiriXAPI, and the public SQLite API were used directly. No fake API, compatibility shim, inferred selector, private schema guess, or standard ROI was introduced.
- The standalone database lives in a restrictive plug-in-owned Application Support directory inside the designated user's home. Every path component is checked before creation or opening; the canonical location, ownership, type, and absence of symlinks are revalidated before write access.
- The directory is mode `0700` and the database is mode `0600`. SQLite is opened with no-follow behavior, foreign-key enforcement, extended result codes, a bounded busy timeout, and an explicit schema version.
- The store contains no patient name, patient ID, birth date, display name, DICOM path, pixel data, preview, local user/device identity, or Horos runtime object.
- The candidate bundle had no identifier, principal-class, or executable-name collision with the immutable baseline plug-in and passed strict ad-hoc signature verification.
- The existing immutable baseline plug-in (one bundle) was not accessed by P1-11 and had an identical fixed-context manifest, signature classification, and Horos recognition state before and after testing.

## Files changed

- `plugin/MeasurementRecord.h` and `.m`: define the immutable Foundation-only spike measurement value.
- `plugin/MeasurementPersistenceStore.h`: defines the replaceable persistence boundary.
- `plugin/SQLiteMeasurementStore.h` and `.m`: contain the standalone path gate, schema, SQLite connection, prepared statement, explicit transaction, rollback, failure handling, and resource cleanup.
- `plugin/MeasurementPanelHost.h`: extends the replaceable panel-host initializer with an injected persistence store.
- `plugin/ViewerInspectorPanelHost.h` and `.m`: own a per-panel measurement identifier and timestamps, expose explicit save status, and submit independent values to the store.
- `plugin/MedisalePluginFilter.m`: creates one plug-in-owned store and injects it into Viewer-owned panels.
- `plugin/Info.plist`: advances the isolated proof-of-concept bundle version.
- `tests/PersistenceStoreTests.m`: exercises normal, update, separation, reopen, and injected-failure behavior against temporary standalone databases.
- `Makefile`: links public SQLite, builds the new sources and harness, and verifies persistence boundaries.
- `TASKS.md`: records P1-10 complete and P1-11 pass/review while leaving P1-12 blocked.
- `docs/platform/P1_11_SPIKE_PERSISTENCE.md`: this anonymized report.

## Tests and evidence

- `make -B verify`: PASS. It produced an arm64 Mach-O bundle against installed real Horos headers and the real `PluginFilter` runtime class. Strict ad-hoc signature verification passed.
- The Foundation-level persistence harness completed 53 assertions. It covered an initial save, exact image identity/frame/endpoints/distance, transactional update of the same identifier, a second Viewer/image record, explicit schema version, restrictive path permissions, reopen persistence, and SQLite integrity.
- Failure injection covered invalid required values/frame, constraint violation, simulated statement failure, simulated pre-commit failure, interrupted-save rollback, busy/locked database, and read-only I/O failure. After every failure the transaction rolled back, record count and prior values were unchanged, partial rows were zero, integrity passed, and a subsequent normal save succeeded.
- `/usr/bin/leaks --atExit` reported zero leaked allocations for the 53-assertion persistence harness.
- In Horos, a completed synthetic measurement saved with `Save OK`. Query-only verification matched its Study/Series/SOP/frame identity and image-coordinate endpoints/distance. Editing and saving the same measurement updated one row rather than creating a partial or duplicate version.
- Two independent synthetic Viewers saved distinct measurement identifiers with exact, non-crossed image/frame identity and values. The standalone store retained those records after normal Horos exit and read-only reopen.
- A synthetic fixture lacking a complete required image identity was safely rejected before persistence. A retained complete synthetic fixture was then used; no partial record was created.
- The final rebuilt candidate, including the component-by-component path gate, loaded under Horos 4.0.1, completed a new save, reported `Save OK`, and left five valid distinct spike rows at schema version 1 with SQLite integrity passing.
- The measurement panel, overlay, event monitor, observers, delegate, and Viewer references followed their deterministic invalidation paths. Closing the panel and Viewer returned Horos to the database screen; Horos then exited normally without a crash or remaining child process.

### Schema and transaction boundary

- Schema version 1 has one spike-only measurement table. Its columns are measurement ID, Study Instance UID, Series Instance UID, SOP Instance UID, frame number, endpoint A/B image coordinates, pixel distance, schema version, and created/updated timestamps.
- Required text fields are non-empty, frame and schema values are constrained, and the measurement identifier is the primary key used by a prepared upsert.
- Save performs `BEGIN IMMEDIATE`, prepares and binds every value, executes the upsert, optionally exercises an isolated failure-injection point, and commits. Success is returned only after `COMMIT` succeeds.
- Every non-success path finalizes the statement, performs explicit rollback (or close-induced rollback for the interrupted-save simulation), closes the connection, returns a generic error, and omits raw SQL, UID, path, or database content from logs.
- Same-identifier saves preserve the creation timestamp and advance the update timestamp. P1-11 verifies record existence only; it has no read/restore interface for Viewer state.

### Process-level network sandbox

- Runtime Horos was launched directly under the previously validated temporary process-level sandbox whose only added policy denied all network operations. Horos descendants inherited the policy; Wi-Fi and system network settings remained unchanged.
- The capability gate allowed ordinary file reads and process execution while denying DNS, TCP, UDP, loopback, listener creation, and child-process network operations.
- The corrected final monitor sampled the complete final run and observed zero successful network descriptors. No cloud login, synchronization, upload, or update operation was used.
- Two earlier monitor attempts were invalidated because their harness treated an expected zero-result query as a shell failure. Those attempts were excluded, the harness was corrected and self-tested, and complete replacement runs observed zero successful connections. This procedure issue did not change system settings or data.
- Destinations, addresses, payloads, hostnames, paths, screenshots, and raw communication logs are intentionally omitted. Temporary sandbox profiles, probes, monitors, screenshots, and raw local evidence were excluded from Git and removed after verification.

### Database, DICOM, preference, and baseline comparison

- Read-only measurements used the inspected Horos SQLite schema, query-only connections, semantic record fingerprints, synthetic identity-set fingerprints, DICOM set/content fingerprints, and SQLite integrity checks with Horos closed.
- Study/Series/Instance counts, known synthetic identity sets, semantic records, Horos DB schema, DICOM set and contents, P1-10 guide preference, Horos.app, and SQLite integrity were unchanged through the final action run.
- The aggregate Horos database-bundle fingerprint changed during ordinary Horos bookkeeping. This mismatch is retained and not hidden; semantic records, identity sets, DICOM content, and schema were unchanged, and action-specific protected mutation was zero.
- The expected persistent changes were confined to the P1-11 plug-in-owned directory, standalone SQLite file, and transient SQLite transaction artifacts. The final standalone store contained only valid spike measurement records.
- The immutable baseline plug-in's complete fixed-context manifest, file/resource set, signature result/classification, and Horos recognition state were unchanged. It was not moved, repaired, re-signed, disabled, copied, or depended upon, and P1-11 did not invoke any of its commands or functionality.
- Actual identities, coordinates, UIDs, values, hashes, filenames, local paths, usernames, device identifiers, signature details, screenshots, raw database content, and raw logs are intentionally omitted.

### Static write-path and content audit

- Only `SQLiteMeasurementStore` imports or calls SQLite in production. UI, Viewer, overlay, measurement model, and adapter sources contain no SQL or connection logic.
- `MeasurementRecord`, `MeasurementPersistenceStore`, and the SQLite store contain no `ViewerController`, `DCMPix`, ROI, managed object, Horos database object, or DICOM runtime object.
- Production P1-11 source contains no Core Data save, managed-object mutation, Horos database API, DICOM write, ROI create/change/save, defaults persistence, independent network API, or P1-12 restoration path.
- The only production filesystem creation/write path is the contained standalone store, guarded by canonical-home, ownership, file-type, symlink, and permission checks.

## Known issues

- This is an intentionally spike-only schema with no production migration, encryption, retention, audit, recovery, or multi-process design. It is not a product database.
- P1-11 stores measurement records but does not load or restore them into a Viewer. Exact SOP/frame restore belongs exclusively to P1-12.
- The aggregate Horos database-bundle fingerprint changes during normal Horos launch/Viewer/exit bookkeeping. Semantic database state, DICOM content, and SQLite integrity remained unchanged.
- Network denial produces an expected unavailable-network warning for a Horos listener. No network or security setting was changed and no connection succeeded.
- Horos reports the ad-hoc candidate as not Horos-validated, as expected for an isolated proof of concept.
- Deprecation warnings originate in installed Horos headers; P1-11 adds no build error.

## Architecture impact

- `MeasurementRecord` is an immutable, Horos-independent Foundation value containing only the approved spike fields and an independent `ImageContext`.
- `MeasurementPersistenceStore` is a replaceable write-only boundary for P1-11. Viewer and panel code depend on the protocol, never SQLite or a path.
- `SQLiteMeasurementStore` exclusively owns containment checks, schema, connection lifetime, prepared SQL, transactions, rollback, failure classification, and cleanup.
- The plug-in injects one store into independent Viewer panel hosts. Each panel owns its own stable measurement identifier, so endpoint edits update that record while separate Viewers remain distinct.
- No Horos runtime object crosses into the persistence layer, and no restore or overlay rehydration dependency was added.

## Data-safety impact

- Testing used only retained, known synthetic fixtures in the designated user's contained environment. No patient, clinical, customer, existing Study, or unknown data was accessed.
- P1-11 actions produced no semantic Horos database, DICOM, ROI, Horos preference, baseline plug-in, Horos.app, network, or macOS security-setting change.
- The standalone store contains only approved image identity, frame, image-coordinate endpoints, pixel distance, schema, identifier, and timestamp values. It contains no display/patient metadata, file path, pixel data, preview, or environment identity.
- No DICOM, image, metadata, screenshot, raw log, database content, local identifier, signature detail, or communication detail was sent externally or published.

## Next prerequisites

- Review this P1-11 report and Draft PR.
- Merge requires separate SHIP approval.
- Only after P1-11 is reviewed and merged may P1-12 readiness be assessed separately.

## STOP required

No P1-11 STOP condition remains. Stop after opening the Draft PR; do not close Issue #11, merge the Draft PR, or begin P1-12.
