import * as THREE from 'three';
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js';
import { makeDesktop, makeKeyboard } from './artwork.js';
import { crtOpening } from './effects.js';

const vertexShader = `
  varying vec2 vUv;
  void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
`;

const fragmentShader = `
  uniform sampler2D uDesktop;
  uniform float uProgress;
  uniform int uEffect;
  varying vec2 vUv;
  const float PI = 3.14159265359;

  void main() {
    float p = uProgress;
    vec3 color = texture2D(uDesktop, vUv).rgb;
    if (uEffect == 0) {
      float radius = sqrt(p) * 0.022;
      vec3 blurred = color * 0.2;
      for (int i = 0; i < 8; i++) {
        float a = float(i) * PI / 4.0;
        vec2 offset = vec2(cos(a) / 1.65, sin(a)) * radius;
        blurred += texture2D(uDesktop, clamp(vUv + offset, 0.0, 1.0)).rgb * 0.075;
        blurred += texture2D(uDesktop, clamp(vUv + offset * 0.45, 0.0, 1.0)).rgb * 0.025;
      }
      color = blurred * (1.0 - pow(p, 1.65) * 0.96);
    } else if (uEffect == 1) {
      color *= 1.0 - p * 0.96;
    } else if (uEffect == 2) {
      vec2 d = (vUv - 0.5) * vec2(1.65, 1.0);
      float angle = atan(d.y, d.x) - p * PI / 2.0;
      float radius = length(vec2(1.65, 1.0)) / (2.0 * cos(PI / 8.0)) * pow(1.0 - p, 1.25);
      float boundary = radius * cos(PI / 8.0) / cos(mod(angle + PI / 8.0, PI / 4.0) - PI / 8.0);
      float mask = p >= 0.999 ? 1.0 : smoothstep(boundary - 0.002, boundary + 0.002, length(d));
      color *= 1.0 - mask * 0.96;
      float seam = 1.0 - smoothstep(0.007, 0.02, abs(sin(angle * 4.0)));
      color += vec3(0.022, 0.028, 0.03) * seam * mask * sin(p * PI);
    } else if (uEffect == 3) {
      float mask = smoothstep((1.0 - p) * 0.5 - 0.002, (1.0 - p) * 0.5 + 0.002, abs(vUv.y - 0.5));
      color *= 1.0 - mask * 0.96;
    } else {
      float h = p >= 0.999 ? 0.0 : max(0.003, pow(1.0 - min(1.0, p / 0.8), 2.3));
      float w = p >= 0.999 ? 0.0 : pow(1.0 - max(0.0, (p - 0.8) / 0.2), 1.3);
      vec2 d = abs(vUv - 0.5);
      float inside = (1.0 - smoothstep(w * 0.5, w * 0.5 + 0.001, d.x)) * (1.0 - smoothstep(h * 0.5, h * 0.5 + 0.001, d.y));
      if (p >= 0.999) inside = 0.0;
      color *= 0.04 + inside * 0.96;
      float glow = p > 0.6 && p < 1.0 ? sin((p - 0.6) / 0.4 * PI) * 0.32 : 0.0;
      color += vec3(0.58, 0.85, 0.85) * exp(-d.y * 230.0) * (1.0 - smoothstep(w * 0.5, w * 0.5 + 0.015, d.x)) * glow;
    }
    gl_FragColor = vec4(color, 1.0);
    #include <tonemapping_fragment>
    #include <colorspace_fragment>
  }
`;

export function createLaptop(canvas, stage, onContextLost) {
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true, powerPreference: 'low-power' });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.75));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.4;
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFShadowMap;
  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(32, 1, 0.1, 60);
  camera.position.set(6.2, 4.6, 10.2);
  camera.lookAt(0, 1.15, 0);
  scene.add(new THREE.HemisphereLight(0xd7eeee, 0x153644, 3));
  const key = new THREE.DirectionalLight(0xf7eee0, 4);
  key.position.set(-3, 8, 5); key.castShadow = true;
  key.shadow.mapSize.set(1024, 1024);
  Object.assign(key.shadow.camera, { left: -7, right: 7, top: 7, bottom: -7 });
  key.shadow.bias = -0.001;
  scene.add(key);
  const rim = new THREE.DirectionalLight(0x83b9c2, 3);
  rim.position.set(5, 3, -5); scene.add(rim);

  const metal = new THREE.MeshStandardMaterial({ color: 0x5b717a, metalness: 0.75, roughness: 0.38 });
  const dark = new THREE.MeshStandardMaterial({ color: 0x10191d, roughness: 0.55, metalness: 0.1 });
  const laptop = new THREE.Group();
  laptop.rotation.y = -0.15; laptop.position.y = -0.23; scene.add(laptop);
  function box(w, h, d, radius, material, parent, x, y, z) {
    const mesh = new THREE.Mesh(new RoundedBoxGeometry(w, h, d, 3, radius), material);
    mesh.position.set(x, y, z); mesh.castShadow = true; mesh.receiveShadow = true; parent.add(mesh);
    return mesh;
  }
  box(5.6, 0.16, 3.65, 0.07, metal, laptop, 0, 0, 0);
  box(1.8, 0.006, 0.93, 0.05, new THREE.MeshStandardMaterial({ color: 0x788b92, metalness: 0.7, roughness: 0.43 }), laptop, 0, 0.084, 0.99);
  const keyboardTexture = new THREE.CanvasTexture(makeKeyboard());
  keyboardTexture.colorSpace = THREE.SRGBColorSpace;
  const keyboard = new THREE.Mesh(new THREE.PlaneGeometry(4.7, 1.72), new THREE.MeshStandardMaterial({ map: keyboardTexture, roughness: 0.7 }));
  keyboard.rotation.x = -Math.PI / 2; keyboard.position.set(0, 0.087, -0.56); laptop.add(keyboard);
  const hinge = new THREE.Group(); hinge.position.set(0, 0.12, -1.68); laptop.add(hinge);
  box(5.57, 3.51, 0.115, 0.06, metal, hinge, 0, 1.755, 0);
  box(5.4, 3.33, 0.008, 0.035, dark, hinge, 0, 1.755, 0.062);
  const desktopTexture = new THREE.CanvasTexture(makeDesktop());
  desktopTexture.colorSpace = THREE.SRGBColorSpace;
  desktopTexture.anisotropy = Math.min(4, renderer.capabilities.getMaxAnisotropy());
  const screenMaterial = new THREE.ShaderMaterial({
    uniforms: { uDesktop: { value: desktopTexture }, uProgress: { value: 0 }, uEffect: { value: 0 } },
    vertexShader, fragmentShader,
  });
  const screen = new THREE.Mesh(new THREE.PlaneGeometry(5.23, 3.17), screenMaterial);
  screen.position.set(0, 1.78, 0.069); hinge.add(screen);
  const webcam = new THREE.Mesh(new THREE.CircleGeometry(0.017, 12), dark);
  webcam.position.set(0, 3.43, 0.069); hinge.add(webcam);
  const floor = new THREE.Mesh(new THREE.PlaneGeometry(50, 50), new THREE.ShadowMaterial({ color: 0x000c13, opacity: 0.25 }));
  floor.rotation.x = -Math.PI / 2; floor.position.y = -0.34; floor.receiveShadow = true; scene.add(floor);

  function resize() {
    const { width, height } = stage.getBoundingClientRect();
    if (!width || !height) return;
    camera.aspect = width / height;
    camera.fov = camera.aspect < 1.3 ? 38 : 32;
    camera.updateProjectionMatrix();
    renderer.setSize(width, height, false);
  }
  resize();
  canvas.addEventListener('webglcontextlost', (event) => { event.preventDefault(); onContextLost(); });
  return {
    resize,
    render(angle, effect, progress, reducedMotion) {
      hinge.rotation.x = THREE.MathUtils.degToRad(90 - (reducedMotion ? 95 : angle));
      screenMaterial.uniforms.uProgress.value = progress;
      screenMaterial.uniforms.uEffect.value = effect;
      renderer.render(scene, camera);
    },
    dispose() {
      scene.traverse((object) => {
        object.geometry?.dispose();
        if (object.material) object.material.dispose();
      });
      desktopTexture.dispose(); keyboardTexture.dispose(); renderer.dispose();
    },
  };
}

export function createFlatPreview(canvas) {
  canvas.width = 1000; canvas.height = 625;
  const ctx = canvas.getContext('2d');
  const desktop = makeDesktop();
  return {
    resize() {},
    dispose() {},
    render(_angle, effect, p) {
      const w = canvas.width, h = canvas.height;
      ctx.clearRect(0, 0, w, h);
      ctx.save();
      ctx.filter = effect === 0 ? `blur(${Math.sqrt(p) * 12}px)` : 'none';
      ctx.drawImage(desktop, 0, 0, w, h); ctx.restore();
      ctx.fillStyle = '#000';
      if (effect < 2) {
        ctx.globalAlpha = 0.96 * (effect === 0 ? p ** 1.65 : p);
        ctx.fillRect(0, 0, w, h);
      } else if (effect === 2) {
        const radius = Math.hypot(w, h) / (2 * Math.cos(Math.PI / 8)) * (1 - p) ** 1.25;
        ctx.beginPath(); ctx.rect(0, 0, w, h);
        for (let i = 0; i < 8; i++) {
          const angle = i * Math.PI / 4 + p * Math.PI / 2;
          const x = w / 2 + Math.cos(angle) * radius, y = h / 2 + Math.sin(angle) * radius;
          if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
        }
        ctx.closePath(); ctx.globalAlpha = 0.96; ctx.fill('evenodd');
      } else if (effect === 3) {
        ctx.globalAlpha = 0.96; ctx.fillRect(0, 0, w, h * p / 2); ctx.fillRect(0, h * (1 - p / 2), w, h * p / 2);
      } else {
        const opening = crtOpening(p);
        ctx.beginPath(); ctx.rect(0, 0, w, h);
        ctx.rect(w * (1 - opening.width) / 2, h * (1 - opening.height) / 2, w * opening.width, h * opening.height);
        ctx.globalAlpha = 0.96; ctx.fill('evenodd');
      }
      ctx.globalAlpha = 1;
    },
  };
}
