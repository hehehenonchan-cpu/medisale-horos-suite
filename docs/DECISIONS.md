# Decisions

## D-001 - Neutral shared data root

- **Status:** Accepted
- **Decision:** Place `HorosData/` and `Measurements/` as siblings below `DICOM/`.
- **Reason:** Keeps paths product-neutral, keeps Horos and Medisale ownership separate, and allows a volume to move with images and measurements together.

## D-002 - Copy -> Verify -> Switch

- **Status:** Accepted
- **Decision:** All migration and recovery use a candidate copy, explicit verification, then atomic activation.
- **Reason:** The active environment remains recoverable if copying, validation, or power fails.

## D-003 - Standalone Manager

- **Status:** Accepted
- **Decision:** Environment management, recovery, licensing, diagnostics, and controlled launch belong to a standalone application.
- **Reason:** These tasks must work before Horos launches and must avoid unsafe concurrent database access.

## D-004 - Controlled auto-launch

- **Status:** Accepted
- **Decision:** After all required checks are green, count down 30 seconds and repeat pre-launch checks immediately before opening Horos.
- **Reason:** A previously healthy external volume or plugin state can change during the countdown.

## D-005 - Offline signed licensing

- **Status:** Accepted
- **Decision:** Use offline device-bound signed licenses with local public-key verification.
- **Reason:** Client operation must not depend on an online licensing service, and signing authority must not reside on client Macs.

## D-006 - Sequential Platform Spike

- **Status:** Accepted
- **Decision:** Execute P1-01 through P1-13 as dependent gates; only P1-01 is initially ready.
- **Reason:** Horos 4.0.1 APIs and runtime behavior must be observed before implementation choices are made.
