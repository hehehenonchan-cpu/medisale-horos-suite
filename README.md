# Medisale Horos Suite

Medisale Horos Suite is a planned set of Horos 4.0.1 extensions and a standalone Horos Manager for veterinary imaging workflows. The repository is currently in the Platform Spike phase; it does not yet contain production plugin or clinical measurement code.

## Current gate

- **Ready:** P1-01 Horos 4.0.1 Platform Baseline
- **Blocked:** P1-02 through P1-13, pending their prerequisite issues
- P1-01 must be run locally on the designated Mac. The repository preparation environment is Windows and cannot validate the Mac installation.

## Non-negotiable safety rules

- Preserve original DICOM and the active Horos database.
- Use synthetic or properly de-identified test data only.
- Never invent or stub Horos APIs to get past a platform gate.
- For migration and recovery, use **Copy -> Verify -> Switch**.
- Never automatically delete the previous data root or source disk.

## Planned data layout

```text
<local shared folder or external volume>/DICOM/
|-- HorosData/       # Horos-managed data
`-- Measurements/    # Medisale-owned data
```

`Measurements/` must never be placed inside `HorosData/`.

## Development workflow

One task = one GitHub Issue = one branch = one draft pull request. An issue may begin only when its dependencies have passed and its status is explicitly ready.

See [TASKS.md](TASKS.md) and [docs/platform/PLATFORM_SPIKE.md](docs/platform/PLATFORM_SPIKE.md).
