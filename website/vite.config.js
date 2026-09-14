import { defineConfig } from 'vite';
import { readFileSync } from 'node:fs';

export default defineConfig({
  base: '/dusk/',
  build: { target: 'es2022' },
  plugins: [{
    name: 'include-license-notices',
    generateBundle() {
      this.emitFile({ type: 'asset', fileName: 'LICENSE.txt', source: readFileSync(new URL('../LICENSE', import.meta.url), 'utf8') });
      const licenses = [
        ['Three.js (runtime)', './node_modules/three/LICENSE'],
        ['Vite and bundled notices (build tooling)', './node_modules/vite/LICENSE.md'],
      ].map(([label, path]) => `${label}\n${'='.repeat(label.length)}\n\n${readFileSync(new URL(path, import.meta.url), 'utf8')}`);
      this.emitFile({ type: 'asset', fileName: 'THIRD_PARTY_LICENSES.txt', source: licenses.join('\n\n') });
    },
  }],
});
