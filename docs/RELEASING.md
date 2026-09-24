# Maintainer release guide

The [Build and release DMG workflow](../.github/workflows/release.yml) creates a universal `arm64`/`x86_64` application for macOS 13+, packages it in a compressed DMG, and uploads the DMG and SHA-256 checksum to GitHub Releases. App bundles are **ad-hoc signed, not Developer ID signed or notarized**. Including both architectures is not evidence of hardware compatibility.

## Prepare a release

1. Review the diff and provenance of new code and assets. Confirm no secrets, personal logs, generated tool caches, or `.build`/`dist` contents are tracked.
2. Update `CFBundleShortVersionString` and increment `CFBundleVersion` in `Resources/Info.plist`. Update `CHANGELOG.md` and create `docs/releases/X.Y.Z.md` with changes, installation instructions, signing status, AI assistance, and validation limits.
3. Run `bash scripts/test.sh` and `bash scripts/build-dmg.sh`. The packaging script reuses `build-app.sh` for each architecture, combines the binaries, signs and verifies the bundle, creates and mounts the DMG, checks its contents, and writes a checksum. Optional SwiftPM flags such as `--sdk` and `--build-system` are forwarded to both builds; do not pass architecture overrides.
4. Run applicable [manual checks](TESTING.md). Record the hardware and OS used and unchecked areas. Packaging validation does not launch the app or test a hinge.
5. Commit and push to `main`. Ensure macOS CI passes for that exact commit. To validate hosted packaging before tagging, manually run the release workflow on `main`; it creates an Actions artifact without publishing a release.
6. Create and push a matching tag, for example `git tag v1.2.1` followed by `git push origin v1.2.1`. Tag and bundle version must agree. The tag must include this workflow and its matching release notes.
7. Wait for the workflow to finish. Verify both assets appear in Releases, download them, and run `shasum -a 256 -c Dusk-X.Y.Z-universal.dmg.sha256`. Update the website's version/download copy when needed.

Only the publish job receives `contents: write`; the build job is read-only. Pull requests run packaging checks without publishing. A manual workflow run on an existing version tag can retry publication. Draft releases can be resumed; an already-published release is never overwritten. Use a new version for changed binaries.

The workflow creates a draft with assets and release notes, then publishes it after uploads succeed. No personal access token, signing certificate, or notarization secret is needed. Keep any future Developer ID signing/notarization secrets outside the repository and outside pull-request workflows; do not claim notarization until it is implemented and verified.

## References

- [GitHub Actions tag triggers](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow)
- [GitHub CLI release creation](https://cli.github.com/manual/gh_release_create)
- [Apple's app-opening and Gatekeeper guidance](https://support.apple.com/en-us/102445)
