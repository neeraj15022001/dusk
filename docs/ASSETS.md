# Asset provenance

## Repository banner

- File: `docs/banner.png`
- Created: September 14, 2026.
- Tool: OpenAI built-in image generation, requested through Codex.
- Purpose: repository artwork. The laptop illustration is not a screenshot or a promise of exact effect appearance.
- No third-party reference image, Apple logo, or external stock asset was supplied. The generated file is retained without image edits, including its embedded provenance metadata.

### Generation prompt

```text
Use case: ads-marketing
Asset type: GitHub README banner for Dusk, an open-source native macOS utility.
Primary request: Create a polished wide landscape repository banner, approximately 2.6:1 aspect ratio. Dusk makes a MacBook screen blur and darken as its lid closes. Elegant restrained editorial product art, deep midnight blue and muted teal palette, warm ivory typography, generous negative space. Left half has large precise text "Dusk" with smaller text "A softer way to close your Mac." Right half shows a single beautifully minimal unbranded aluminum laptop viewed at three-quarter angle, lid half closed, screen softly glowing teal with misty abstract gradients fading into darkness. Subtle atmospheric bloom suggesting screen blur. Keep everything inside generous safe margins. Typography crisp and readable at GitHub README width. No additional text, no Apple logo, no phone, no watermarks, no badges, no fake UI screenshots. Finished artwork, not a webpage mockup.
```

## Effect contact sheet

`docs/effects-preview.png` is produced by `EffectContactSheet` from the synthetic landscape and document illustration in `EffectPreviewView`. It shows five effects at five closure positions. It contains no personal desktop capture.

Regenerate after building:

```sh
dist/Dusk.app/Contents/MacOS/Dusk --render-effects docs/effects-preview.png
```

Project-authored assets are included under the repository's MIT license to the extent the contributors hold applicable rights. This grants no rights to third-party trademarks. See [AI_POLICY.md](../AI_POLICY.md) and [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).
