# Medisale Horos Suite Working Rules

## Scope and safety

- Target Horos 4.0.1 on the Mac environment documented by P1-01.
- Treat all DICOM, patient, customer, and clinical data as protected medical data.
- Use synthetic or properly de-identified fixtures only.
- Never modify original DICOM files or the active Horos database during development.
- Do not upload DICOM, medical images, metadata, logs, or screenshots to external services.
- Stop when an issue's stated dependency or STOP condition is unmet.

## Development flow

- One task = one issue = one branch = one pull request.
- Only P1-01 is ready. P1-02 through P1-13 remain blocked until their dependencies pass.
- Do not infer Horos APIs. Verify installed frameworks, headers, symbols, and runtime behavior.
- Do not create fake `PluginFilter` or compatibility classes to bypass a failed platform gate.
- Use `main` as the stable branch. Development branches use `spike/p1-xx-short-name`.
- Draft pull requests are the default. Merge, release, installation on a clinical Mac, and production changes require separate approval.

## Required reporting

Every issue report must include result, verified facts, files changed, tests, evidence, known issues, architecture impact, data-safety impact, next prerequisites, and whether STOP is required.
