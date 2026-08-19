# Platform Spike P1-01 through P1-13

## Common prohibitions

Do not modify the installed Horos application, active Horos database, original DICOM, standard ROI, or other plugins. Do not implement clinical algorithms. Do not fabricate `PluginFilter` or substitute assumed APIs. Stop and document unmet gates.

## P1-01 - Horos 4.0.1 Platform Baseline (READY)

**Outcome:** Record the actual macOS, hardware, executable, framework, plugin, signing, and toolbar API baseline without changing the installation.

Run the following locally in Terminal on the designated Mac. Copy only non-sensitive output into `docs/platform/HOROS_4_0_1_BASELINE.md`; redact usernames, serial numbers, UUIDs, signing identities, and patient paths.

```bash
set -u
HOROS_APP="/Applications/Horos.app"

test -d "$HOROS_APP" || { echo "STOP: Horos.app not found"; exit 10; }

sw_vers
uname -m
system_profiler SPHardwareDataType | sed -E '/Serial Number|Hardware UUID|Provisioning UDID/d'
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$HOROS_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$HOROS_APP/Contents/Info.plist"
file "$HOROS_APP/Contents/MacOS/Horos"
codesign -dv --verbose=4 "$HOROS_APP" 2>&1 | sed -E '/^Authority=/d;/^TeamIdentifier=/d'

find "$HOROS_APP/Contents" -maxdepth 5 \( -name 'OsiriXAPI.framework' -o -name 'PluginFilter.h' \) -print
FRAMEWORK="$(find "$HOROS_APP/Contents" -maxdepth 5 -name 'OsiriXAPI.framework' -print -quit)"
test -n "$FRAMEWORK" || { echo "STOP: OsiriXAPI.framework not found"; exit 20; }

find "$FRAMEWORK" -maxdepth 4 -type f -perm -111 -print -exec file {} \;
find "$HOROS_APP/Contents" -maxdepth 7 -name 'PluginFilter.h' -print -exec sed -n '1,220p' {} \;
nm -gU "$HOROS_APP/Contents/MacOS/Horos" 2>/dev/null | grep -E 'PluginFilter|toolbarAllowedIdentifiersForViewer|toolbarItemForItemIdentifier' || true

find "$HOME/Library/Application Support" -maxdepth 4 -type d \( -iname '*plugin*' -o -iname '*horos*' \) -print
find '/Library/Application Support' -maxdepth 4 -type d \( -iname '*plugin*' -o -iname '*horos*' \) -print 2>/dev/null

defaults read org.horosproject.horos 2>/dev/null | grep -i -E 'plugin|toolbar' || true
```

Then, without installing or changing a plugin, inspect Horos Plugin Manager and record:

- directories it recognizes;
- whether it distinguishes installed, disabled, incompatible, or unsigned plugins;
- minimum observable bundle and `Info.plist` keys from an already installed non-sensitive sample, if available;
- Viewer and Browser toolbar extension selectors confirmed by framework headers or runtime symbols.

**PASS:** Horos is exactly 4.0.1; executable and OsiriXAPI architectures are buildable on the target Mac; the real `PluginFilter` class/header or runtime class is confirmed; plugin path and loading mechanism are evidenced; signing and toolbar API findings are recorded.

**STOP:** Horos is not 4.0.1; OsiriXAPI is absent; the real `PluginFilter` cannot be confirmed; executable/framework architecture cannot be targeted; commands would require changing the installed app, active database, plugins, or security settings. Do not begin P1-02.

## P1-02 - Real PluginFilter Skeleton (BLOCKED by P1-01)

Build the smallest plugin using the verified real Horos API. It must be recognized and invoked by Horos and display `Medisale Plugin OK`. Plugin Manager visibility alone is not a pass. Stop on API incompatibility; do not create a fake base class.

## P1-03 - Viewer Toolbar PoC (BLOCKED by P1-02)

Add a `Medisale Test` Viewer toolbar item using only verified selectors. It displays `Viewer Toolbar OK`, identifies the owning Viewer, supports multiple Viewers, and closes without a crash.

## P1-04 - Browser Toolbar PoC (BLOCKED by P1-03)

Add read-only `Medisale Tools Test` Browser toolbar behavior. Verify no selection, one Study, one Series, and multiple selections. Do not mutate Browser data.

## P1-05 - HorosAdapter Foundation (BLOCKED by P1-04)

Map the current Horos image into an independent `ImageContext`: Study UID, Series UID, SOP UID, frame number, pixel dimensions, and pixel spacing. Horos runtime objects must not enter the measurement layer.

## P1-06 - Two Point Input (BLOCKED by P1-05)

Capture two points in image coordinates with cancel, out-of-view rejection, zoom/pan correctness, and per-Viewer isolation.

## P1-07 - Overlay Renderer (BLOCKED by P1-06)

Render a transient line from image-coordinate truth. Track zoom, pan, resize, and image changes; do not show it on another image.

## P1-08 - Endpoint Editing (BLOCKED by P1-07)

Edit each endpoint with live image-coordinate and pixel-distance updates, clean selection behavior, and no material conflict with normal Horos tools.

## P1-09 - Measurement Panel Host Spike (BLOCKED by P1-08)

Try a right-docked panel first. If private-layout dependency or instability appears, stop that approach and use a Viewer-following inspector panel. Keep a replaceable `MeasurementPanelHost` interface.

## P1-10 - Guide Engine PoC (BLOCKED by P1-09)

Implement detailed-guide on/off behavior with a persistent preference. Short instructions remain visible even when detailed guides are off.

## P1-11 - Spike Persistence (BLOCKED by P1-10)

Store spike-only measurements transactionally in standalone SQLite keyed by image identity and frame. Never write to Horos DB or DICOM. A failed save leaves no partial record.

## P1-12 - Reload / Restore (BLOCKED by P1-11)

Restore by SOP Instance UID and frame number at the same image coordinates after closing and reopening the Viewer. Never restore Image A's line on Image B.

## P1-13 - Lifecycle / Stability Test (BLOCKED by P1-12)

Test ten Viewer open/close cycles, two Viewers, study/series/image switches, mid-measurement close, panel close behavior, Horos relaunch, sleep/wake, and SQLite lifecycle. Record crashes, dangling references, observers, panels, Viewer binding, SOP binding, and DB locks in `PLATFORM_SPIKE_RESULTS.md`.

Completion requires a Platform Gate review. It does not authorize VHS or any later feature.
