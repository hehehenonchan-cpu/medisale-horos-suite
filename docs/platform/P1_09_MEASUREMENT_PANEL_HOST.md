# P1-09 Measurement Panel Host Spike Report

## Result

**PASS / REVIEW.** A replaceable measurement-panel host presents a public-AppKit inspector bound to one Viewer and one transient measurement model. The panel displays endpoint A, endpoint B, pixel distance, input state, and binding state; updates live during endpoint editing; follows Viewer movement and resize; and remains isolated across images, frames, and Viewers. Panel and Viewer closure release their bindings and observers safely. No P1-09-specific database, DICOM, defaults, ROI, filesystem, or network persistence was detected. P1-10 remains blocked.

## Verified facts

- The branch is based on the reviewed P1-08 merge commit and contains only P1-09 implementation, build verification, task status, and this report.
- The test account is the designated standard macOS user. The isolated database and plug-in directory are contained inside that user's home, without symlinks, ownership mismatch, external/shared references, additional mounted volumes, or network shares.
- The database contains only retained, known synthetic fixtures, including the approved two-frame fixture. No patient, clinical, customer, existing, or unknown data was present.
- Installed Horos 4.0.1 headers and runtime objects were used directly. No fake API, compatibility shim, inferred selector, private Viewer layout, or standard ROI was added.
- Header and runtime inspection did not establish a public, stable right-dock host. The dock approach was therefore rejected, and the approved inspector fallback uses only public AppKit behind the replaceable `MeasurementPanelHost` interface.
- The arm64 candidate bundle references the real `PluginFilter` and OsiriXAPI headers and passed strict ad-hoc signature verification.
- The candidate had no identifier, principal-class, or executable-name collision with the baseline plug-in.
- An existing signed, validated baseline plug-in (one bundle) was treated as immutable, was not accessed by P1-09, and had an identical prospective manifest before and after testing.

## Files changed

- `plugin/MeasurementPanelHost.h`: defines the replaceable panel-host boundary and lifecycle contract.
- `plugin/ViewerInspectorPanelHost.h` and `.m`: implement the public-AppKit inspector, live fields, Viewer following, active-Viewer presentation, panel re-presentation, and deterministic invalidation.
- `plugin/LineOverlayModel.h` and `.m`: expose transient input state and change notifications in the Horos-independent measurement model.
- `plugin/TransientLineOverlayController.m`: publish selection, drag, completion, and Escape-cancel state changes to the model.
- `plugin/MedisalePluginFilter.m`: bind one inspector host to each owning Viewer and overlay, prevent duplicate hosts, and coordinate cleanup.
- `plugin/Info.plist`: advances the isolated proof-of-concept bundle version.
- `Makefile`: builds the panel-host sources and verifies the new public implementation boundary.
- `TASKS.md`: records P1-09 pass/review while leaving P1-10 blocked.
- `docs/platform/P1_09_MEASUREMENT_PANEL_HOST.md`: this anonymized report.

## Tests and evidence

- `make -B verify`: PASS. It produced an arm64 Mach-O bundle against installed real Horos headers and the real `PluginFilter` runtime class. Strict ad-hoc signature verification passed.
- Model-state verification passed for initial complete state and distance, endpoint-edit state notification, live coordinate/distance update, and return to complete state.
- Horos 4.0.1 recognized, enabled, loaded, and executed the isolated candidate bundle.
- The inspector displayed endpoint A/B values and pixel distance matching the transient overlay model. During a held endpoint drag, the coordinate, distance, and editing state updated before mouse-up.
- Escape during a drag restored the exact pre-drag A/B and distance values and returned the panel to the complete state.
- Normal pan and zoom operations remained available outside endpoint targets and did not alter the image-coordinate model. The inspector remained correct after pan, zoom, and Viewer resize.
- Moving and resizing the Viewer moved the inspector to a valid adjacent location without changing its measurement values.
- Closing the inspector alone left the Viewer, overlay, endpoint editing, and normal tools functional. Re-presenting it reused the same host; repeated close/re-present cycles created no duplicate panel or observer behavior.
- Switching the bound image or frame removed the old panel state. A frame-zero measurement did not appear on frame one.
- Multiple Viewers held independent models and inspectors. Active-Viewer changes showed only the owning inspector, values did not cross between Viewers, and an unbound Viewer showed no panel.
- Closing one owning Viewer removed its panel and references without affecting another Viewer. Closing all Viewers returned Horos to the database screen. Horos then exited normally with no crash.
- Panel, model, delegate, notification observers, overlay event monitor, timer, and Viewer references were released during invalidation.

### Process-level network sandbox

- Runtime testing launched the Horos executable directly under a temporary process-level sandbox whose only added policy denied all network operations. Horos descendants were covered by the same policy.
- The capability gate allowed ordinary file reads and process execution while denying DNS, TCP, UDP, loopback, listener creation, and a child process's network operation.
- Successful network connections were zero throughout control and action runs. Wi-Fi remained enabled and unchanged; no proxy, DNS, packet-filter, firewall, or network-service setting was modified.
- Horos and its related test processes terminated. Temporary profiles, monitors, screenshots, and raw local evidence are excluded from Git.
- No cloud login, synchronization, upload, or update operation was used. Destinations, addresses, payloads, hostnames, paths, and raw communication logs are intentionally omitted.

### Prospective baseline plug-in immutability

- With Horos fully closed, a prospective manifest was recorded using a fixed user, working directory, environment, architecture, canonical bundle location, and direct `/usr/bin/codesign` execution outside the process sandbox.
- The manifest covered canonical-location fingerprint, whole-bundle content, executable and property-list content, complete relative path/size/content records, file count, ownership, permissions, extended attributes, modification metadata, architecture, anonymous identifier data, and signing metadata.
- Direct strict verification and deep/strict verification were each repeated three times. Results were stable within the canonical context; all canonical prospective runs passed.
- After runtime testing, the full manifest, every per-file record, ownership, permissions, timestamps, extended attributes, architecture, anonymous identifiers, signing metadata, verification results, and Horos recognition state were identical to the prospective baseline.
- Earlier local signature observations were context-dependent. This known variance was not hidden; the P1-09 decision uses only repeated before/after measurements from the fixed canonical context.
- The existing signed, validated baseline plug-in (one bundle) was not moved, changed, repaired, re-signed, disabled, invoked, or depended upon by P1-09.

### Database and DICOM comparison

- Read-only measurements were taken with Horos closed using an inspected SQLite schema, query-only connections, semantic record fingerprints, DICOM set/content fingerprints, and SQLite integrity checks.
- A control run opened the same synthetic Viewer configuration without a P1-09 panel action. Schema, Study/Series/Instance counts and synthetic identity sets, DICOM set and content, and integrity remained unchanged.
- The P1-09 action run preserved the same schema, semantic record sets, DICOM set, and DICOM contents. SQLite integrity passed, and no action-specific persistent change was detected.
- The aggregate database-bundle fingerprint changed during both ordinary control activity and the action run. This mismatch is retained and not hidden; the control reproduced Horos bookkeeping changes while all semantic and DICOM invariants remained unchanged.
- Actual identities, hashes, filenames, local paths, usernames, device identifiers, screenshots, raw database content, and raw logs are intentionally omitted.

### Static write-path audit

- P1-09 source contains no Core Data save or managed-object mutation, database connection or SQL, Horos database mutation API, DICOM write, filesystem write, defaults persistence, network operation, or ROI creation/change/save.
- The inspector reads only an independent `LineOverlayModel`. That model contains image-coordinate values and copied `ImageContext` identity, not Viewer, image-view, managed-object, ROI, or other Horos runtime objects.
- Display coordinates remain confined to the existing transient overlay controller. The inspector does not become a coordinate truth source and does not implement P1-10 guide behavior.

## Known issues

- A stable public right-dock interface was not verified in the installed Horos API. The spike therefore uses the approved replaceable inspector fallback rather than private Viewer layout access.
- Signature verification had produced context-dependent observations in earlier local work. In P1-09's fixed prospective context, three repeated pre-test results were stable and the complete post-test state was identical.
- The aggregate database-bundle fingerprint changes during ordinary Horos launch/Viewer/exit bookkeeping. Control and action semantic state, DICOM content, and SQLite integrity were unchanged.
- Horos emitted one nonfatal internal data-model diagnostic while duplicating a synthetic Viewer. No crash or semantic database/DICOM change followed, and the P1-09 source has no Core Data access.
- Network denial produces an expected unavailable-network warning for a Horos listener. No setting was changed and no network connection succeeded.
- The isolated launch used a process-only English localization argument because an installed localized resource is unreadable in this environment; no default, application file, or system setting was changed.
- Horos reports the ad-hoc test plug-in as not Horos-validated, as expected for an isolated proof of concept.
- Deprecation warnings originate in installed Horos headers; P1-09 adds no build error.
- The inspector layout and labels are spike-only test surfaces, not final product UI.

## Architecture impact

- `MeasurementPanelHost` makes the host replaceable without changing the independent measurement model. A future verified host can replace the public-AppKit inspector without introducing private API into the measurement layer.
- Each inspector is owned by one weak Viewer binding and one strong independent `LineOverlayModel`. Viewer, SOP, and frame lifecycle invalidation prevents stale or cross-Viewer presentation.
- Model notifications provide live values and input state without exposing Horos event objects or display-coordinate state to the panel.
- Panel presentation, following, close/re-present, active-Viewer behavior, and teardown remain inside the host implementation. Measurement and overlay responsibilities stay separate.
- P1-10 guide-engine behavior is not implemented.

## Data-safety impact

- Testing used only retained, known synthetic fixtures in the designated user's contained database. No patient, clinical, customer, existing Study, or unknown data was accessed.
- P1-09 actions produced no semantic database, DICOM, defaults, ROI, filesystem, or network change. Synthetic DICOM contents were unchanged.
- The baseline plug-in remained immutable and unused. Horos.app and macOS security/network settings were not modified.
- No DICOM, image, metadata, screenshot, raw log, database content, local identifier, signature detail, or communication detail was sent externally or published.

## Next prerequisites

- Review this P1-09 report and Draft PR.
- Merge requires separate SHIP approval.
- Only after P1-09 is reviewed and merged may P1-10 readiness be assessed separately.

## STOP required

No P1-09 STOP condition remains. Stop after opening the Draft PR; do not close Issue #9, merge the Draft PR, or begin P1-10.
