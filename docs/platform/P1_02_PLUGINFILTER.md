# P1-02 Real PluginFilter Skeleton

> Inspection date: 2026-08-19 (Asia/Tokyo). This report contains only sanitized, publishable findings. No patient data, screenshots, raw clinical logs, usernames, device identifiers, credentials, or details of unrelated plugins are included.

## Result

`PASS`

Horos 4.0.1 loaded the ad-hoc-signed arm64 bundle, registered its menu command, invoked the real `PluginFilter` subclass, and displayed `Medisale Plugin OK` against an identifier-free synthetic image.

## Verified facts

- The checkout was on `spike/p1-02-real-pluginfilter` at the approved P1-01 base before implementation, with a clean worktree.
- Only the startup volume was present. No additional volume or network filesystem was mounted.
- Before the first launch, the dedicated user had no existing Horos Data directory, Horos preference plist, or Horos plugin directory.
- The installed application reported Horos 4.0.1 and its executable was arm64.
- The build imported the installed Horos 4.0.1 `PluginFilter.h` directly from the installed framework headers.
- The generated executable was a thin arm64 Mach-O bundle with an unresolved Objective-C reference to the real `PluginFilter` runtime class.
- The new bundle alone received an ad-hoc signature and passed strict signature verification before and after placement.
- The bundle was placed only in the dedicated user's standard Horos plugin directory.
- Horos loaded and enabled the plugin, registered `Medisale Plugin` under Image Filters, and invoked it successfully.
- Runtime input was a locally generated 64 x 64 Secondary Capture DICOM with empty Patient Name and Patient ID fields. It contained no clinical or customer data.
- The displayed confirmation was `Medisale Plugin OK`.

## Files changed

- `Makefile`
- `plugin/Info.plist`
- `plugin/MedisalePluginFilter.m`
- `scripts/create_synthetic_dicom.py`
- `docs/platform/P1_02_PLUGINFILTER.md`
- `TASKS.md`
- `.gitignore`

## Tests and evidence

- `make verify`: passed; validates the plist, arm64 Mach-O type, arm64 CPU header, real `PluginFilter` runtime reference, principal class, menu title, and plugin type. The installed Horos headers emit deprecation warnings but no plugin-source error.
- `codesign --verify --strict`: passed for both the build artifact and the placed artifact.
- Horos runtime recognition: passed; the new plugin appeared enabled for the current user.
- Horos menu registration: passed; `Image Filters > Medisale Plugin` was present.
- Horos invocation: passed; selecting the command displayed `Medisale Plugin OK`.
- The synthetic DICOM was recognized as DICOM, used only for the isolated runtime check, and deleted afterward.

## Known issues

- Horos 4.0.1 could not read its installed Japanese localization resource under the dedicated user. Runtime validation used the process-only `-AppleLanguages (en)` launch argument. No application file, permission, preference, or security setting was changed to work around this installation issue.
- The installed Horos API headers contain deprecated macOS API declarations. These produced compiler warnings but no incompatibility or runtime failure in this spike.
- Horos reports the ad-hoc development plugin as not Horos-validated. This is expected for the required ad-hoc signature and did not prevent recognition or invocation.

## Architecture impact

- The spike subclasses the installed Horos 4.0.1 `PluginFilter` directly. No compatibility class or copied API header is included.
- The plugin contains no clinical or image-processing implementation.
- `MenuTitles` and `pluginType=imageFilter` follow the official Horos plugin loader contract.

## Data-safety impact

- The plugin does not request or inspect a Viewer, image, DICOM object, database object, preference, or filesystem path.
- Isolation checks found no pre-existing Horos Data or settings in the dedicated user before launch.
- Runtime validation used only a locally generated identifier-free synthetic DICOM. No original DICOM, patient data, existing Horos Data, existing setting, or unrelated installed plugin was read or changed.
- The synthetic fixture was deleted after validation. Screenshots and raw logs were not added to the repository.
- No application permission or security setting was changed.

## Next prerequisites

- P1-03 remains blocked until this P1-02 PASS and Draft PR are reviewed. Do not begin P1-03 in this branch.

## STOP required?

`NO`

All P1-02 acceptance criteria passed without an isolation violation, patient-data exposure, fake API, security-setting change, or runtime incompatibility.
