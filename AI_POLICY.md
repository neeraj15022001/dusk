# AI assistance and provenance

## How Dusk was created

Dusk was developed with substantial assistance from OpenAI Codex under Neeraj Gupta's direction. AI assistance covered Swift implementation, effect design, debugging, tests, documentation, and repository preparation. This is an AI-assisted project, not a claim that every line was independently authored or audited by a human.

The initial release's automated checks and build were run through the development agent. The agent also exercised app controls on a MacBook, read its hinge sensor, and verified preview cleanup. User feedback shaped the features and removals. These checks do not constitute an independent security audit or compatibility certification.

## Assets and references

- `docs/banner.png`: created with OpenAI's built-in image generation tool. The prompt and provenance are recorded in [asset notes](docs/ASSETS.md).
- `docs/effects-preview.png`: rendered deterministically by Dusk from synthetic artwork; it is not a recording of a personal desktop.
- App interface icons use macOS system symbol APIs. No Apple symbol artwork is redistributed as standalone assets.
- The landing page's Three.js model, shader previews, synthetic artwork, and implementation were also developed with Codex assistance. It does not read a visitor's screen or hinge sensor.
- The universal DMG packaging script, release workflow, and installation documentation received Codex assistance. Automated packaging checks do not constitute signing by an identified publisher, notarization, or physical hardware validation.
- Hardware research and API references are listed in [third-party notes](THIRD_PARTY_NOTICES.md). No external implementation is vendored.

Private development conversations, machine logs, credentials, and tool caches are not part of this repository. Publishing a complete chat transcript is not required to contribute.

## AI-assisted contributions

AI tools are welcome, with the same quality and licensing expectations as any other contribution:

1. Disclose material assistance in your pull request: tool, affected files or behavior, and validation performed. A brief description is enough; private prompts are unnecessary.
2. Read and understand the output. Check API availability, failure paths, accessibility, and licensing. Do not submit changes you cannot explain.
3. Run relevant checks and report failures or untested areas honestly. Never claim tests, reviews, or hardware access that did not occur.
4. Keep private user data, credentials, and third-party confidential material out of prompts and commits.
5. Verify the right to contribute generated material. An AI tool's output is not evidence that third-party rights have been cleared.
6. Avoid bulk speculative changes and generated issue/PR spam. Submit focused, reviewable work.

The maintainer decides what is merged. AI-generated explanations, tests, or reviews do not replace that responsibility. The [project license](LICENSE) governs contributions; AI assistance does not create an additional restriction on downstream use.
