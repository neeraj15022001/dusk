# Maintainer release checklist

The initial public release is source-first. GitHub's source archives are available from the release page; no Developer ID signed or notarized application is currently supplied.

1. Review the diff and provenance of new code and assets. Confirm no secrets, personal logs, generated tool caches, or `.build`/`dist` contents are tracked.
2. Update `CFBundleShortVersionString` and increment `CFBundleVersion` in `Resources/Info.plist`. Update `CHANGELOG.md` with the public release date and links.
3. Run `bash scripts/test.sh`, `bash scripts/build-app.sh`, and `codesign --verify --deep --strict dist/Dusk.app` from the intended commit.
4. Run applicable [manual checks](TESTING.md). Record the hardware and OS used and any unchecked areas.
5. Ensure GitHub CI passes for that exact commit. Verify README links, license recognition, issue forms, and private vulnerability reporting.
6. Create a `vX.Y.Z` tag and a GitHub release with changes, verification, known limits, and source-build instructions. Do not describe an ad-hoc signed bundle as notarized.

If downloadable applications are added later, explicitly document supported architectures and OS versions, include licensing notices, publish SHA-256 checksums, and establish Developer ID signing and notarization before claiming trusted distribution. Keep signing secrets outside the repository and outside pull-request workflows.

Avoid uploading local debug files, personal paths, machine logs, or synthetic artifacts that contain removed features.
