import test from 'node:test';
import assert from 'node:assert/strict';
import { effects, progressAtAngle, smoothstep, crtOpening } from '../src/effects.js';

test('preview matches native default angle landmarks', () => {
  assert.equal(progressAtAngle(110), 0);
  assert.equal(progressAtAngle(65), 0);
  assert.equal(progressAtAngle(36.5), 0.5);
  assert.equal(progressAtAngle(8), 1);
  assert.equal(progressAtAngle(0), 1);
});

test('invalid readings fail clear and closure stays bounded and monotonic', () => {
  for (const value of [NaN, Infinity, -Infinity, -1, 181]) assert.equal(progressAtAngle(value), 0);
  const closing = Array.from({ length: 181 }, (_, i) => progressAtAngle(180 - i));
  closing.forEach((p, i) => {
    assert.ok(p >= 0 && p <= 1);
    if (i) assert.ok(p >= closing[i - 1]);
  });
  assert.equal(smoothstep(-1), 0);
  assert.equal(smoothstep(2), 1);
});

test('five effects remain available and CRT opening closes monotonically', () => {
  assert.deepEqual(Object.keys(effects), ['softBlur', 'fade', 'aperture', 'shutters', 'crt']);
  assert.deepEqual(crtOpening(0), { width: 1, height: 1 });
  assert.deepEqual(crtOpening(1), { width: 0, height: 0 });
  let area = 1;
  for (let i = 0; i <= 100; i++) {
    const opening = crtOpening(i / 100);
    assert.ok(opening.width * opening.height <= area);
    area = opening.width * opening.height;
  }
});
