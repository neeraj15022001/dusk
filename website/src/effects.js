export const effects = {
  softBlur: { index: 0, description: 'The desktop softens, then slips into darkness.' },
  fade: { index: 1, description: 'A clean fade to black. No blur, no movement.' },
  aperture: { index: 2, description: 'Eight iris blades turn toward a quiet center.' },
  shutters: { index: 3, description: 'Two cinema curtains meet in the middle.' },
  crt: { index: 4, description: 'A nostalgic squeeze to a soft line, then a point.' },
};

export function unit(value) {
  return Number.isFinite(value) ? Math.min(1, Math.max(0, value)) : 0;
}

export function smoothstep(value) {
  const t = unit(value);
  return t * t * (3 - 2 * t);
}

// Same default 65°→8° thresholds and reversible curve as DuskCore.EffectCurve.
export function progressAtAngle(angle) {
  if (!Number.isFinite(angle) || angle < 0 || angle > 180) return 0;
  return smoothstep((65 - angle) / 57);
}

export function crtOpening(progress) {
  const p = unit(progress);
  if (p === 1) return { width: 0, height: 0 };
  return {
    width: (1 - Math.max(0, (p - 0.8) / 0.2)) ** 1.3,
    height: Math.max(0.003, (1 - Math.min(1, p / 0.8)) ** 2.3),
  };
}
