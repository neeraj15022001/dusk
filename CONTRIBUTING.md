# Contributing to Dusk

Thank you for helping make closing a MacBook feel better. Bug reports, hardware compatibility reports, documentation, accessibility improvements, and focused patches are welcome.

Read the [Code of Conduct](CODE_OF_CONDUCT.md), [AI policy](AI_POLICY.md), and [security policy](SECURITY.md) before contributing.

## Start with a useful report

Search existing issues before opening one. Include your MacBook model and chip, macOS version, Dusk version or commit, selected effect, angle thresholds, steps to reproduce, and expected versus observed behavior. Do not include serial numbers, personal desktop screenshots, credentials, or unredacted system logs.

For substantial features or new dependencies, open a feature request first so scope and maintenance costs can be discussed. Small fixes can go straight to a pull request.

## Development

1. Fork the repository and clone your fork.
2. Install Xcode Command Line Tools with `xcode-select --install` if needed. Use macOS 13+ and Swift 5.9+.
3. Create a focused branch: `git switch -c fix/describe-your-change`.
4. Run `bash scripts/test.sh` and `bash scripts/build-app.sh`.
5. Open `dist/Dusk.app` to try the change. Quit an existing Dusk instance before launching a rebuilt copy.

The native app has no third-party package dependencies. `Sources/DuskCore` contains deterministic effect math and HID report decoding. `Sources/Dusk` contains the AppKit/SwiftUI app and IOKit sensor integration. Tests are a standalone Swift executable, so a full Xcode installation is not required.

For website changes, follow [`website/README.md`](website/README.md). Use Node.js 22.12+ and run `npm ci`, `npm test`, and `npm run build` from `website/`. Check desktop and mobile layouts, keyboard controls, and the preview in a browser. Website dependencies are separate from the native app. Pull requests build in GitHub Actions; publication happens after a push to `main`.

## Protect the desktop experience

- Keep sensor I/O off the main thread.
- Invalid or stale readings must clear the overlay. Pause, quit, sleep, and reopening must remain reliable escape paths.
- Preserve click-through behavior, built-in-display-only scope, and Reduce Motion support.
- Do not introduce screen recording, telemetry, network calls, login items, or new permissions without a separate discussion and explicit product decision.
- Preserve stored preferences when changing effect names or configuration.
- Keep changes small and use the existing Swift formatting style. Explain non-obvious hardware or lifecycle decisions.

## Validation

Run the commands above and report their actual results. Add regression coverage when changing effect math, HID decoding, or lifecycle behavior that can be tested meaningfully. Do not add tests that merely restate implementation details.

For visual changes, regenerate the synthetic contact sheet:

```sh
dist/Dusk.app/Contents/MacOS/Dusk --render-effects docs/effects-preview.png
```

On a supported MacBook, follow the [manual verification checklist](docs/TESTING.md). If you cannot test physical hardware, say so. Passing CI is not evidence that a sensor works on an untested model.

## Pull requests

Describe the problem, resulting behavior, testing performed, and known limits. Use the PR template and disclose material AI assistance: tool, affected areas, and how you checked the output. You remain responsible for every submitted line and must have the right to contribute it.

Contributions are offered under this repository's [license](LICENSE). Do not submit incompatible code, private prompts, proprietary context, or generated output whose provenance you cannot explain. No contributor license agreement or mandatory sign-off is currently required.

The repository owner reviews and merges changes. Review and release timing depend on maintainer availability; there is no response-time guarantee.
