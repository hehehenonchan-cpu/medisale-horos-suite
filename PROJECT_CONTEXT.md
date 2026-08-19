# Project Context

## Objective

Establish a safe, verifiable foundation for the Medisale Horos Suite on Horos 4.0.1 before clinical measurement features are implemented.

## Initial users

- Veterinary imaging staff using Horos
- Medisale technicians installing, licensing, diagnosing, migrating, and recovering the suite

## Current phase

Epic 1, Platform Spike. Only P1-01 is approved for execution. No clinical measurement algorithm is in scope.

## Constraints

- Mac and Horos behavior must be proven on the target installation.
- This repository must not contain patient data, DICOM files, credentials, device identifiers, licenses, or customer logs.
- Data operations follow Copy -> Verify -> Switch and never automatically delete the old source.
- Horos-owned data and Medisale measurements are separate siblings under a neutral `DICOM/` root.
