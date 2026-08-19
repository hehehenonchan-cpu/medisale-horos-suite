# Data Safety

## Classification

DICOM, patient information, clinical measurements, customer logs, device identifiers, and license files are sensitive. Repository development uses synthetic or properly de-identified inputs only.

## Copy -> Verify -> Switch

1. **Copy:** Keep the existing data root active while copying into a separate candidate location.
2. **Verify:** Validate structure, file count, total size, required databases, SQLite integrity, measurement-store readability, write access, and important hashes where practical.
3. **Switch:** Mark the candidate ready and atomically update the active data-root configuration only after all required checks pass.

An interrupted copy or failed verification must never change the active root. The old source is not automatically deleted, reformatted, renamed destructively, or overwritten.

## Recovery and migration

- Restore into a candidate directory, never directly over the current healthy `DICOM/` tree.
- Create a recoverable safety copy before database-schema migration.
- Run migrations in transactions and roll back failures.
- Use soft deletion for measurements; physical deletion is outside normal product behavior.
- Prevent writes while Horos is running unless a future operation has explicit proof and approval that concurrent access is safe.

## Verification evidence

Record timestamps, source and destination identifiers without patient data, counts, sizes, check outcomes, configuration revision, and failure reason. Never place secrets, full device identifiers, or clinical data in logs or GitHub Issues.

## Definition of done

A data-changing workflow is not complete until forced interruption, disk-full behavior, verification failure, and rollback have been tested and the original source remains usable.
