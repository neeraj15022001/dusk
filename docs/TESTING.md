# Testing and compatibility

## Automated checks

```sh
bash scripts/test.sh
bash scripts/build-app.sh
codesign --verify --deep --strict dist/Dusk.app
```

`DuskChecks` is a dependency-free Swift executable. It covers effect endpoints, monotonic closing/reopening, invalid configuration, opacity bounds, aperture and CRT geometry, and HID report decoding. It does not simulate WindowServer, physical sensors, sleep, or every accessibility setting.

GitHub Actions builds and runs these checks on a hosted macOS runner. Hosted CI does not validate a MacBook hinge. The build script targets the host architecture; a local Apple silicon build is not a universal binary.

## Toolchain troubleshooting

If compilation reports a missing `SwiftUIMacros.StateMacro` plugin, check that your selected Xcode/Command Line Tools installation includes the plugins required by its SDK. This occurred during release preparation with Swift 6.4 and the macOS 27 SDK in Command Line Tools. It is not a hinge-permission error.

The build script forwards optional SwiftPM flags. If you have an older compatible SDK installed, select it explicitly with `bash scripts/build-app.sh --sdk /path/to/MacOSX.sdk`. Otherwise use a complete compatible Xcode/toolchain installation. Dusk does not install or change your system toolchain. The hosted CI runner provides an independent build check.

## Hardware evidence

During development, the agent read live hinge angles on an M3 MacBook Air running macOS 26.6.2 and exercised settings and four-second preview cleanup. These are limited development observations, not a claim of support for every MacBook or macOS release. The deployment target is macOS 13; the oldest supported OS has not been physically tested.

The HID report is hardware-dependent. Unsupported models retain the in-window simulator and preview, but automatic hinge effects require a readable compatible sensor. Report compatibility with your model/chip and macOS version, never your serial number.

## Manual verification

1. Keep the lid above the start threshold. Confirm the desktop stays clear.
2. Lower the lid slowly for each effect. Confirm the effect increases, holds at an intermediate angle, and reverses on reopening.
3. Test the emergency pause shortcut, Escape in settings, menu bar pause, and quit.
4. Run a four-second preview. Confirm it clears automatically and leaves Enabled unchanged.
5. Sleep and wake; switch Spaces; enter a full-screen app. Confirm cleanup and recovery after a fresh reading.
6. Connect an external display. Verify only the built-in display is affected.
7. Check Reduce Motion and Reduce Transparency. Reduce Motion should use Fade while preserving the selected effect.
8. Relaunch and check saved effect, thresholds, darkness, and blur. Invalid or retired selections should fall back to Soft blur.
9. Check an unsupported sensor or interrupted-reading path when suitable hardware is available. The desktop should remain clear or clear promptly.

Document what you tested, what failed, and what remains untested. Do not infer hardware compatibility from a green build.

## Synthetic artwork

```sh
dist/Dusk.app/Contents/MacOS/Dusk --render-effects docs/effects-preview.png
```

This draws generated desktop artwork and effect masks. It does not record the user's screen. Core Image rendering needs access to normal macOS graphics services, which some execution sandboxes restrict.

The read-only sensor probe is optional and requires compatible hardware:

```sh
dist/Dusk.app/Contents/MacOS/Dusk --probe
```
