import './style.css';
import { effects, progressAtAngle, smoothstep } from './effects.js';
import { createLaptop, createFlatPreview } from './laptop.js';

const stage = document.querySelector('#stage');
const canvas = document.querySelector('#laptop');
const fallback = document.querySelector('#fallback');
const slider = document.querySelector('#lid-angle');
const angleValue = document.querySelector('#angle-value');
const closureValue = document.querySelector('#closure-value');
const play = document.querySelector('#play');
const motion = window.matchMedia('(prefers-reduced-motion: reduce)');
let angle = Number(slider.value);
let selected = 'softBlur';
let view;
let frame = 0;
let playback = null;
let visible = true;

function showFallback() {
  view?.dispose();
  canvas.hidden = true; fallback.hidden = false;
  view = createFlatPreview(fallback);
  stage.dataset.renderer = 'canvas';
  document.querySelector('#render-status').textContent = '3D graphics are unavailable here. You can still explore the flat preview.';
  requestRender();
}

try {
  view = createLaptop(canvas, stage, showFallback);
  stage.dataset.renderer = 'three';
} catch (error) {
  console.warn('Dusk 3D preview unavailable:', error.message);
  showFallback();
}

function updateControls() {
  slider.value = String(Math.round(angle));
  slider.style.setProperty('--range-fill', `${angle / 110 * 100}%`);
  angleValue.value = `${Math.round(angle)}°`;
  slider.setAttribute('aria-valuetext', `${Math.round(angle)} degrees`);
  closureValue.textContent = `${Math.round(progressAtAngle(angle) * 100)}% closed`;
}

function render(now) {
  frame = 0;
  if (!visible || document.hidden) return;
  if (playback) {
    const elapsed = (now - playback.start) / 1000;
    if (elapsed >= 4) {
      angle = playback.angle;
      stopPlayback();
    } else {
      const close = elapsed < 2 ? smoothstep(elapsed / 2) : smoothstep((4 - elapsed) / 2);
      angle = playback.angle * (1 - close);
    }
  }
  updateControls();
  view.render(angle, effects[motion.matches ? 'fade' : selected].index, progressAtAngle(angle), motion.matches);
  if (playback) requestRender();
}

function requestRender() {
  if (!frame && visible && !document.hidden) frame = requestAnimationFrame(render);
}

function stopPlayback() {
  playback = null;
  play.innerHTML = '<span aria-hidden="true">▷</span> Close & reopen';
}

function setAngle(value) {
  stopPlayback();
  angle = Math.max(0, Math.min(110, value));
  updateControls(); requestRender();
}

slider.addEventListener('input', () => setAngle(Number(slider.value)));
play.addEventListener('click', () => {
  if (playback) { stopPlayback(); requestRender(); return; }
  playback = { start: performance.now(), angle: angle > 65 ? angle : 95 };
  play.innerHTML = '<span aria-hidden="true">Ⅱ</span> Stop preview';
  requestRender();
});

const picker = document.querySelector('#preview-effect');
function selectEffect(value) {
  selected = value;
  picker.value = value;
  for (const option of document.querySelectorAll('[data-effect]')) {
    const active = option.dataset.effect === value;
    option.classList.toggle('active', active);
    option.setAttribute('aria-pressed', String(active));
  }
  document.querySelector('#effect-description').textContent = effects[value].description;
  setAngle(angle > 60 || angle < 12 ? 36.5 : angle);
}
picker.addEventListener('change', () => selectEffect(picker.value));
for (const button of document.querySelectorAll('[data-effect]')) {
  button.addEventListener('click', (event) => {
    selectEffect(button.dataset.effect);
    if (event.detail > 0) {
      document.querySelector('#playground').scrollIntoView({ behavior: motion.matches ? 'instant' : 'smooth', block: 'start' });
    }
  });
}

let drag;
for (const surface of [canvas, fallback]) {
  surface.addEventListener('pointerdown', (event) => {
    if (event.button !== 0) return;
    drag = { x: event.clientX, y: event.clientY, angle };
    surface.setPointerCapture(event.pointerId);
  });
  surface.addEventListener('pointermove', (event) => {
    if (!drag) return;
    const dx = event.clientX - drag.x, dy = event.clientY - drag.y;
    if (event.pointerType === 'touch' && Math.abs(dx) <= Math.abs(dy)) return;
    setAngle(drag.angle + dx * 0.3 - dy * 0.15);
  });
  surface.addEventListener('pointerup', () => { drag = null; });
  surface.addEventListener('pointercancel', () => { drag = null; });
}

function syncMotion() {
  document.querySelector('#motion-note').hidden = !motion.matches;
  stopPlayback(); requestRender();
}
motion.addEventListener('change', syncMotion);
syncMotion();

new ResizeObserver(() => { view.resize(); requestRender(); }).observe(stage);
new IntersectionObserver(([entry]) => {
  visible = entry.isIntersecting;
  if (!visible) stopPlayback(); else requestRender();
}, { rootMargin: '120px' }).observe(stage);
document.addEventListener('visibilitychange', () => {
  if (document.hidden) stopPlayback(); else requestRender();
});
window.addEventListener('pagehide', () => {
  stopPlayback(); cancelAnimationFrame(frame); frame = 0;
});
window.addEventListener('pageshow', requestRender);

document.querySelector('#copy').addEventListener('click', async () => {
  const button = document.querySelector('#copy');
  const code = document.querySelector('#commands');
  const status = document.querySelector('#copy-status');
  try {
    await navigator.clipboard.writeText(code.textContent);
    button.textContent = 'Copied'; status.textContent = 'Build commands copied.';
    setTimeout(() => { button.textContent = 'Copy commands'; }, 2200);
  } catch {
    window.getSelection()?.selectAllChildren(code);
    status.textContent = 'Commands selected. Press Command C or Control C to copy.';
    button.textContent = 'Commands selected';
  }
});

updateControls(); requestRender();
