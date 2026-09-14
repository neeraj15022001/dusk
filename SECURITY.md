# Security policy

## Supported versions

Security fixes target the latest published release and `main`. Older releases do not receive guaranteed backports. Dusk is maintained on a best-effort basis; there is no guaranteed response time or bug bounty.

## Report a vulnerability privately

Use [GitHub private vulnerability reporting](https://github.com/neeraj15022001/dusk/security/advisories/new). Include the affected version or commit, impact, reproduction steps, and a minimal proof of concept if available. Avoid including personal desktop content, serial numbers, credentials, or unrelated system logs.

Do not open a public issue for an undisclosed vulnerability. If the private form is unavailable, open an issue asking only for a private reporting channel, without technical details or sensitive information.

The maintainer will assess the report, coordinate a fix when feasible, and agree on disclosure and credit with the reporter. Do not access other people's devices or data while testing.

## Current boundaries

Dusk reads a local HID hinge sensor and draws a click-through overlay on the built-in display. It does not capture the desktop, record audio, send telemetry, connect to a service, install a privileged helper, or modify hardware brightness. Its current behavior requires no Screen Recording or Accessibility permission.

The overlay is a visual effect, not a lock screen or privacy boundary. It does not protect displayed information from other apps, screenshots, or observers. MacOS sleep and authentication remain the operating system's responsibility.

Local app builds are ad-hoc signed and are not Developer ID signed or notarized. Build from source you have reviewed; do not disable Gatekeeper globally. No independent security audit has been performed.
