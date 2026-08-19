# Architecture

## Components

```text
Horos 4.0.1
  -> verified Horos plugin entry points
  -> HorosAdapter
  -> Medisale independent models and services

Standalone Horos Manager
  -> environment and license preflight
  -> storage association and recovery orchestration
  -> plugin health checks
  -> pre-launch recheck
  -> controlled Horos launch
```

Horos runtime objects such as `ViewerController`, `DCMPix`, and `ROI` must not cross into measurement-domain interfaces. The adapter emits stable independent models such as `ImageContext` containing study, series, SOP, frame, dimensions, and pixel spacing.

## Storage boundary

```text
DICOM/
|-- HorosData/       # Horos lifecycle and schema
`-- Measurements/    # Medisale SQLite and store metadata
```

Manager settings, licenses, and logs remain in Mac-local Application Support. Logs must exclude patient data and sensitive DICOM metadata.

## Migration state machine

```text
ACTIVE_SOURCE -> COPY_CANDIDATE -> VERIFY_CANDIDATE -> READY_CANDIDATE -> ATOMIC_SWITCH
```

Failure before `ATOMIC_SWITCH` leaves the original source active. The previous source is preserved after switching; deletion is never automatic.

## Platform dependency rule

P1-01 through P1-13 are sequential gates. No downstream work may replace missing evidence with assumptions or compatibility stubs.
