# P1-10 Guide Engine PoC Report

## Result

**PASS / REVIEW.** An independent `GuideEngine` now supplies always-visible short operating instructions and an optional detailed operating guide to every measurement inspector. The detailed-guide state is stored through a replaceable preference-store protocol as one Boolean in a dedicated plug-in domain, defaults to off when absent or invalid, synchronizes across open Viewer panels, and survives Horos relaunch in both off and on states. Guide changes did not alter measurement coordinates, distance, endpoint editing, Viewer binding, database content, DICOM content, or Horos settings. P1-11 remains blocked and unstarted.

## Verified facts

- The branch is based on the reviewed P1-09 merge commit and contains only P1-10 implementation, build verification, task status, and this report.
- The test account is the designated standard macOS user. The isolated database and plug-in directory are contained inside that user's home without symlinks, ownership mismatch, external/shared references, additional mounted volumes, or network shares.
- The database contained only retained, known synthetic fixtures. No patient, clinical, customer, existing, or unknown data was present.
- Installed Horos 4.0.1 headers and runtime objects were used directly. No fake API, compatibility shim, inferred selector, private Viewer layout, or standard ROI was added.
- `GuideEngine` is a Foundation component that depends only on the `GuidePreferenceStore` protocol. It has no Horos, Viewer, DICOM, image, measurement-value, UID, frame, path, or managed-object dependency.
- The concrete store uses public `CFPreferences` with an explicit, dedicated application domain, one dedicated key, current-user scope, and any-host scope. It writes only a Boolean and verifies the persisted readback.
- The missing and invalid-value states both safely default to detailed guide off.
- The actual preference file was verified inside the designated user's home with no symlink or ownership mismatch. No ByHost, system, Horos-domain, or second plug-in-domain preference was created.
- The arm64 candidate bundle references the real `PluginFilter` and OsiriXAPI headers and passed strict ad-hoc signature verification.
- The candidate had no identifier, principal-class, or executable-name collision with the immutable baseline plug-in.
- The existing immutable baseline plug-in (one bundle) was not accessed by P1-10 and had an identical prospective manifest, fixed-context signature result, and Horos recognition state before and after testing.

## Files changed

- `plugin/GuidePreferenceStore.h` and `.m`: define the replaceable store boundary and the public-`CFPreferences` Boolean implementation.
- `plugin/GuideEngine.h` and `.m`: own the operating-guide text, current detailed-guide state, persistence coordination, and change notification.
- `plugin/MeasurementPanelHost.h`: extends the replaceable panel-host initializer with an injected guide engine.
- `plugin/ViewerInspectorPanelHost.h` and `.m`: present always-visible short instructions, the detailed-guide toggle and text, cross-panel synchronization, and observer teardown.
- `plugin/MedisalePluginFilter.m`: creates one shared guide engine/store and injects it into Viewer-owned panels.
- `plugin/Info.plist`: advances the isolated proof-of-concept bundle version.
- `Makefile`: builds the guide sources and verifies their public API and persistence boundary.
- `TASKS.md`: records P1-10 pass/review while leaving P1-11 blocked.
- `docs/platform/P1_10_GUIDE_ENGINE.md`: this anonymized report.

## Tests and evidence

- `make -B verify`: PASS. It produced an arm64 Mach-O bundle against installed real Horos headers and the real `PluginFilter` runtime class. Strict ad-hoc signature verification passed.
- A Foundation-level executable completed eight assertions covering absent-value default off, invalid-type fallback off, short instructions, on/off writes, change notifications, exact one-key storage, and independent store instances reading the persisted state.
- A temporary-domain capability probe verified real public `CFPreferences` write/read/remove behavior in current-user/any-host scope. Its file was contained inside the designated user's home, was not a symlink, and was owned by that user. Probe data was removed before runtime testing.
- With the production preference absent, a control run showed short instructions and detailed guide off without creating the preference file.
- Enabling detailed guide displayed operating-only detail immediately while all three short instructions remained visible. Disabling it hid only the detailed text.
- Closing and re-presenting a panel reused the same host without duplicate windows or observers and preserved the shared guide state.
- Two independent synthetic Viewers held different endpoint values and distances. Toggling the guide in either panel immediately synchronized the other panel without crossing measurement state.
- Endpoint dragging remained functional with the guide off and with it on. Guide toggling did not change endpoint values, distance, input state, overlay ownership, or normal Horos-tool behavior.
- Closing one owning Viewer released its panel and references without affecting the other Viewer. Closing all Viewers returned Horos to the database screen.
- A relaunch with the stored value off reopened the panel with short instructions visible and detail hidden. After setting the value on and exiting normally, a second relaunch reopened with short instructions and detailed text visible.
- The final preference inventory contained exactly one file and one target Boolean key. ByHost files, system files, other keys, and other plug-in preference domains were all zero.
- Horos recognized, enabled, loaded, and executed the P1-10 candidate. It exited normally in the control, action, off-relaunch, and on-relaunch runs; no child process remained and no crash was detected.
- Panel observers, model references, guide-engine references, delegate, overlay monitor, timer, and Viewer references were released by their existing deterministic invalidation paths.

### Process-level network sandbox

- Every runtime run launched the Horos executable directly under the previously validated temporary process-level sandbox whose only added policy denied all network operations. Horos descendants inherit the policy.
- The capability gate allowed ordinary file reads and process execution while denying DNS, TCP, UDP, loopback, listener creation, and a child process's network operation.
- Successful TCP, UDP, and child-process network connections were zero throughout all runs. Wi-Fi remained enabled and unchanged; no proxy, DNS, packet-filter, firewall, or network-service setting was modified.
- No cloud login, synchronization, upload, or update operation was used. Destinations, addresses, payloads, hostnames, paths, and raw communication logs are intentionally omitted.
- Horos and related test processes terminated normally. The temporary sandbox profile, capability artifacts, monitors, screenshots, and raw local evidence are excluded from Git.

### Prospective baseline plug-in immutability

- With Horos fully closed, a prospective manifest was recorded in one fixed evidence context. It covered canonical-location fingerprint, whole-bundle content, every relative entry, file count, size, ownership, permissions, timestamps, extended attributes, executable and property-list content, anonymous identity data, architecture, signing metadata, and direct strict/deep verification results.
- Strict and deep/strict verification were each repeated three times and produced one stable known result in that context. The same repetitions after control, action, and relaunch testing produced the identical result and classification.
- The complete final manifest was byte-for-byte identical to the prospective manifest. Horos recognition, enabled state, and validated state were also unchanged.
- Signature observations differ across execution contexts on this Mac. This known context dependence is not hidden; the immutability decision uses only repeated before/after measurements from the same fixed context, while the P1-10 candidate independently passed direct strict verification.
- The existing immutable baseline plug-in (one bundle) was not moved, changed, repaired, re-signed, disabled, invoked, copied, or depended upon by P1-10.

### Database, DICOM, and preferences comparison

- Read-only measurements used the inspected SQLite schema, query-only connections, semantic record fingerprints, synthetic identity-set fingerprints, DICOM set/content fingerprints, and SQLite integrity checks with Horos closed.
- The retained baseline contained three synthetic Studies, three synthetic Series, five synthetic Instances, and four stored DICOM files. These counts, known synthetic identity sets, semantic records, DICOM set and contents, and schema remained unchanged through the final run. SQLite integrity passed.
- The aggregate database-bundle fingerprint changed during ordinary Horos control activity and again during action/relaunch activity. This mismatch is retained and not hidden; all semantic and DICOM invariants were unchanged, and the action introduced no unique database change.
- Ordinary Horos preferences changed five keys in the control run. The final four changed Horos keys were a strict subset of those control changes; P1-10 introduced no action-specific key in the Horos domain.
- The only P1-10-owned persistent change was the authorized dedicated Boolean guide preference. No measurement, endpoint, distance, image identity, UID, frame, path, or clinical value was stored.
- Actual identities, values, hashes, filenames, local paths, usernames, device identifiers, screenshots, raw database content, and raw logs are intentionally omitted.

### Static write-path and content audit

- Only `CFPreferencesGuidePreferenceStore` calls the persistence API. `GuideEngine`, the panel host, measurement model, overlay controller, and Horos adapter cannot access the concrete preference implementation.
- The store uses neither `NSUserDefaults` nor any Horos application preference domain, global/any-user scope, current-host scope, database API, SQL, filesystem write API, DICOM API, ROI API, or network API.
- P1-10 source contains no Core Data save, managed-object mutation, Horos database mutation, DICOM write, ROI create/change/save, network operation, or independent filesystem write.
- Short and detailed text contains operating instructions only. It contains no diagnosis, recommendation, threshold, treatment, risk score, interpretation, clinical claim, or medical advice.
- Guide state is a Boolean only and cannot carry measurement coordinates, distance, image identity, UID, frame, patient data, or local path.

## Known issues

- Signature verification of the immutable baseline plug-in is execution-context dependent. The fixed prospective before/after context was stable and identical, and all content/metadata records and Horos recognition state were unchanged.
- The aggregate database-bundle fingerprint changes during ordinary Horos launch/Viewer/exit bookkeeping. Control and action semantic state, DICOM content, and SQLite integrity were unchanged.
- Network denial produces an expected unavailable-network warning for a Horos listener. No setting was changed and no network connection succeeded.
- The isolated launch used a process-only English localization argument because an installed localized resource is unreadable in this environment; no default, application file, or system setting was changed.
- Horos reports the ad-hoc test plug-in as not Horos-validated, as expected for an isolated proof of concept.
- Deprecation warnings originate in installed Horos headers; P1-10 adds no build error.
- The guide wording and inspector layout are spike-only test surfaces, not final product UI or clinical content.

## Architecture impact

- `GuideEngine` is a Horos-independent Foundation component. It owns guide presentation state and text but no Viewer, measurement, DICOM, image, or clinical state.
- `GuidePreferenceStore` makes persistence replaceable and testable. The production implementation confines the one authorized Boolean write to an explicit plug-in-owned domain and key.
- One shared engine per plug-in instance makes the detailed-guide choice consistent across panels while each `MeasurementPanelHost` continues to own an independent measurement model and Viewer binding.
- Panel observers react to engine notifications and are removed during invalidation. The panel knows the engine abstraction but not the concrete store or persistence API.
- P1-11 persistence, measurement-record storage, restoration, and clinical behavior are not implemented.

## Data-safety impact

- Testing used only retained, known synthetic fixtures in the designated user's contained database. No patient, clinical, customer, existing Study, or unknown data was accessed.
- P1-10 actions produced no semantic database, DICOM, ROI, filesystem, network, or Horos-preference change. Synthetic DICOM contents were unchanged.
- The sole plug-in-owned persistent state is the authorized detailed-guide Boolean; it contains no protected, measurement, image, or local-environment data.
- The immutable baseline plug-in remained unchanged and unused. Horos.app and macOS security/network settings were not modified.
- No DICOM, image, metadata, screenshot, raw log, database content, local identifier, signature detail, or communication detail was sent externally or published.

## Next prerequisites

- Review this P1-10 report and Draft PR.
- Merge requires separate SHIP approval.
- Only after P1-10 is reviewed and merged may P1-11 readiness be assessed separately.

## STOP required

No P1-10 STOP condition remains. Stop after opening the Draft PR; do not close Issue #10, merge the Draft PR, or begin P1-11.
