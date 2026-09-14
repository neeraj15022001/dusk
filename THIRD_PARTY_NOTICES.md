# Third-party references and assets

Dusk has no third-party Swift package dependencies and vendors no third-party source code.

## Hardware research

The hinge sensor approach was informed by [Sam Gold's LidAngleSensor project](https://github.com/samhenrigold/LidAngleSensor), its [hardware notes](https://github.com/samhenrigold/LidAngleSensor#faq), and the local MacBook's IORegistry descriptor. Dusk implements its own sensor discovery, polling, report decoding, and failure handling. This acknowledgement does not imply affiliation or endorsement.

## Platform APIs and visual references

- AppKit, SwiftUI, IOKit, Core Image, and other linked frameworks are provided by macOS and remain subject to Apple's terms. They are not copied into this repository.
- Interface symbols are requested from macOS system symbol APIs. Standalone SF Symbols assets are not bundled.
- [Adobe's iris transition explanation](https://helpx.adobe.com/ph_fil/premiere-pro/how-to/apply-transitions-premiere-cc.html) informed the aperture concept. No Adobe code or imagery is included.
- The banner and synthetic effect sheet are described in [asset notes](docs/ASSETS.md).

Apple, MacBook, macOS, and other third-party names belong to their respective owners. Dusk is an independent project and is not affiliated with or endorsed by Apple.

Future contributions that introduce third-party material must document its source and license and retain required notices.
