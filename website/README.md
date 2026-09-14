# Dusk website

The landing page lives at <https://neeraj15022001.github.io/dusk/> and is built and deployed by `.github/workflows/pages.yml`.

## Develop

Use Node.js 22.12 or newer:

```sh
cd website
npm ci
npm run dev
```

Open the URL printed by Vite, including `/dusk/`. The base path matches the GitHub project Pages URL.

## Verify and build

```sh
npm test
npm run build
npm run preview
```

The Node tests verify default native angle landmarks, fail-clear invalid readings, bounded closure, and CRT geometry. Browser checks are still necessary for WebGL rendering, mobile layout, keyboard controls, playback, clipboard feedback, and reduced motion.

`src/laptop.js` builds the Three.js laptop and shader effects. `src/artwork.js` draws the synthetic desktop and keyboard; no device content is read. `src/effects.js` ports DuskCore's default 65°/8° smoothstep curve. The preview is an approximation, especially for the native system-controlled backdrop blur. A flat Canvas preview remains available when WebGL fails.

Rendering happens on demand, with animation only during user-triggered playback or input. Playback stops when the demo leaves the viewport or the page is hidden. Reduced motion uses Fade and keeps the laptop still.

## Deployment

GitHub Pages must use **GitHub Actions** as its build source. Pushes affecting `website/` or its workflow build and deploy automatically; pull requests run tests/build without publishing. Only the deploy job receives Pages write and OpenID Connect permissions. A manual `workflow_dispatch` run is also available. The base path and workflow follow [Vite's GitHub Pages deployment guidance](https://vite.dev/guide/static-deploy.html#github-pages).

The workflow deploys only `website/dist`, never native app binaries or repository-private files. The static site has no backend, analytics, forms, runtime CDN imports, or device-permission requests. GitHub Pages receives ordinary web requests; this is separate from the native app's offline behavior.

Three.js (MIT) powers the browser demo. Vite (MIT) is build tooling. Exact versions and transitive dependencies are locked in `package-lock.json`; dependencies are separate from the Swift app. `public/social.png` is a copy of the repository's AI-generated banner; its provenance is recorded in `docs/ASSETS.md` at the repository root.
