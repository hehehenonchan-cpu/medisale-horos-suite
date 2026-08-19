# Tasks

## Status rules

- `GO / READY`: approved and all prerequisites satisfied
- `BLOCKED`: must not start
- A passing issue unlocks only its direct successor after review.
- P1-13 completion does not automatically authorize feature development; a Platform Gate review is required.

## Epic P1 - Platform Spike

| ID | Title | Status | Dependency | Primary evidence |
|---|---|---|---|---|
| P1-01 | Horos 4.0.1 Platform Baseline | **GO / READY** | Target Mac available | `docs/platform/HOROS_4_0_1_BASELINE.md` |
| P1-02 | Real PluginFilter Skeleton | **PASS / REVIEW** | P1-01 PASS | Plugin executes `Medisale Plugin OK` |
| P1-03 | Viewer Toolbar PoC | BLOCKED | P1-02 PASS | Correct viewer-bound toolbar action |
| P1-04 | Browser Toolbar PoC | BLOCKED | P1-03 PASS | Read-only selection context tests |
| P1-05 | HorosAdapter Foundation | BLOCKED | P1-04 PASS | Independent `ImageContext` output |
| P1-06 | Two Point Input | BLOCKED | P1-05 PASS | Image-coordinate input |
| P1-07 | Overlay Renderer | BLOCKED | P1-06 PASS | Zoom/pan/resize tracking |
| P1-08 | Endpoint Editing | BLOCKED | P1-07 PASS | Editable endpoints without tool conflict |
| P1-09 | Measurement Panel Host Spike | BLOCKED | P1-08 PASS | Stable docked panel or inspector fallback |
| P1-10 | Guide Engine PoC | BLOCKED | P1-09 PASS | Persistent guide preference and short instructions |
| P1-11 | Spike Persistence | BLOCKED | P1-10 PASS | Transactional standalone SQLite store |
| P1-12 | Reload / Restore | BLOCKED | P1-11 PASS | SOP UID + frame exact restore |
| P1-13 | Lifecycle / Stability Test | BLOCKED | P1-12 PASS | Regression report and Platform Gate matrix |

Detailed scope, acceptance criteria, and STOP conditions are in `docs/platform/PLATFORM_SPIKE.md` and the corresponding GitHub Issues.
