# Changelog

Changes are grouped by release. Dates refer to public releases, not internal development builds.

## [Unreleased]

No changes yet.

## [1.2.1] - 2026-09-24

- Added a GitHub Actions release workflow that tests Dusk, builds a universal Apple Silicon/Intel app, verifies a compressed DMG, and publishes the DMG and SHA-256 checksum for version tags.
- Added installation instructions and bundled licensing notices. Downloads are ad-hoc signed, not Developer ID signed or notarized.
- Added the GitHub Pages landing website with an interactive Three.js laptop, five effect previews, accessible controls, and a GitHub Actions build/deployment workflow. The native app is unchanged.

## [1.2.0] - 2026-09-14

Initial public source release.

- Five position-driven effects: Soft blur, Fade, Camera aperture, Cinema shutters, and CRT sleep.
- Live hinge polling, configurable angle thresholds, darkness and blur controls, and persistent preferences.
- Synthetic angle simulator, four-second desktop preview, emergency pause shortcut, and menu bar controls.
- Built-in-display-only overlays, Reduce Motion fallback, and cleanup on stale readings, pause, sleep, or quit.
- No desktop capture, Screen Recording permission, network access, or external package dependencies.
- Open-source contribution, conduct, security, support, licensing, and AI-assistance documentation.

[Unreleased]: https://github.com/neeraj15022001/dusk/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/neeraj15022001/dusk/releases/tag/v1.2.1
[1.2.0]: https://github.com/neeraj15022001/dusk/releases/tag/v1.2.0
