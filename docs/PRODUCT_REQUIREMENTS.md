# Product Requirements

## Product boundary

The suite will combine Horos plugins with a standalone **Horos Manager**. Horos Manager is not a Horos plugin and must be able to perform preflight, licensing, storage association, health checks, guided migration/recovery, diagnostics, and controlled Horos launch while Horos is closed.

## Data layout

Use neutral paths rather than vendor-branded roots:

```text
/Users/Shared/DICOM/
|-- HorosData/
`-- Measurements/

/Volumes/<VolumeName>/DICOM/
|-- HorosData/
`-- Measurements/
```

Horos owns `HorosData/`; Medisale owns `Measurements/`. Neither component may silently alter the other's ownership boundary.

## Manager startup behavior

The Manager health view includes data root, measurement store, read/write access, iCloud risk, storage, license, plugin state, and Time Machine state. When every required item is green, the Manager offers immediate launch and begins a 30-second auto-launch countdown. Immediately before launch it repeats the pre-launch checks. Any new failure cancels launch and displays a specific recovery path.

## Licensing

Licensing is offline, device-bound, and cryptographically signed. A license file is generated outside the client Mac from a device request, verified locally using an embedded public key, and contains no private signing key. Missing, altered, expired, or wrong-device licenses fail closed. Device identifiers and issued licenses must not be committed.

## Initial delivery boundary

The Platform Spike validates Horos integration only. VHS, VLAS, CTR, real-size measurement, DICOM import, production storage schemas, production licensing, and installer implementation are outside the current implementation scope.
