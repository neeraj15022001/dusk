export function makeDesktop() {
  const canvas = document.createElement('canvas');
  canvas.width = 1200;
  canvas.height = 750;
  const ctx = canvas.getContext('2d');
  const sky = ctx.createLinearGradient(0, 0, 0, 750);
  sky.addColorStop(0, '#173e53');
  sky.addColorStop(1, '#9cbbb0');
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, 1200, 750);
  ctx.fillStyle = '#f0d59d';
  ctx.beginPath(); ctx.arc(890, 224, 70, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = '#4d8280';
  ctx.beginPath(); ctx.moveTo(0, 500);
  ctx.bezierCurveTo(250, 250, 650, 660, 1200, 360);
  ctx.lineTo(1200, 750); ctx.lineTo(0, 750); ctx.fill();
  ctx.fillStyle = '#1a535e';
  ctx.beginPath(); ctx.moveTo(0, 630);
  ctx.bezierCurveTo(370, 720, 760, 380, 1200, 570);
  ctx.lineTo(1200, 750); ctx.lineTo(0, 750); ctx.fill();
  ctx.fillStyle = '#123b4a';
  ctx.beginPath(); ctx.moveTo(0, 710);
  ctx.bezierCurveTo(400, 550, 800, 740, 1200, 650);
  ctx.lineTo(1200, 750); ctx.lineTo(0, 750); ctx.fill();
  ctx.fillStyle = '#ffffff1f'; ctx.fillRect(0, 0, 1200, 27);
  ctx.font = '12px sans-serif'; ctx.fillStyle = '#edf1e4';
  ctx.fillText('Dusk     File     Edit     View', 22, 18);
  ctx.fillText('A moment of calm', 1050, 18);
  ctx.shadowColor = '#082b3c55'; ctx.shadowBlur = 45; ctx.shadowOffsetY = 20;
  ctx.fillStyle = '#f1f0e7'; ctx.beginPath(); ctx.roundRect(172, 170, 420, 332, 16); ctx.fill();
  ctx.shadowBlur = 0; ctx.shadowOffsetY = 0;
  for (const [i, color] of ['#d78e79', '#d9bd76', '#8daf92'].entries()) {
    ctx.fillStyle = color; ctx.beginPath(); ctx.arc(193 + i * 18, 191, 5, 0, Math.PI * 2); ctx.fill();
  }
  ctx.fillStyle = '#204953'; ctx.font = '32px Georgia'; ctx.fillText('Less noise.', 205, 270);
  ctx.fillText('More space.', 205, 310);
  ctx.fillStyle = '#5c777666';
  for (let i = 0; i < 5; i++) ctx.fillRect(205, 346 + i * 19, i === 4 ? 165 : 340, 5);
  ctx.fillStyle = '#f0f4ea40'; ctx.beginPath(); ctx.roundRect(350, 679, 500, 52, 16); ctx.fill();
  for (let i = 0; i < 9; i++) {
    ctx.fillStyle = ['#d3dfd3', '#c7d9dc', '#d8cfc0'][i % 3];
    ctx.beginPath(); ctx.roundRect(365 + i * 53, 689, 35, 33, 8); ctx.fill();
    ctx.fillStyle = '#316275'; ctx.fillRect(375 + i * 53, 701, 15, 3);
  }
  return canvas;
}

export function makeKeyboard() {
  const canvas = document.createElement('canvas');
  canvas.width = 1024; canvas.height = 380;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#18252d'; ctx.fillRect(0, 0, 1024, 380);
  for (let row = 0; row < 5; row++) {
    for (let col = 0; col < 14; col++) {
      ctx.fillStyle = '#34434b';
      ctx.beginPath(); ctx.roundRect(8 + col * 73, 7 + row * 62, 63, 51, 7); ctx.fill();
      ctx.fillStyle = '#8e9a9e'; ctx.fillRect(37 + col * 73, 24 + row * 62, 5, 3);
    }
  }
  ctx.fillStyle = '#34434b';
  for (let i = 0; i < 3; i++) {
    ctx.beginPath(); ctx.roundRect(8 + i * 73, 319, 63, 51, 7); ctx.fill();
    ctx.beginPath(); ctx.roundRect(804 + i * 73, 319, 63, 51, 7); ctx.fill();
  }
  ctx.beginPath(); ctx.roundRect(230, 319, 560, 51, 7); ctx.fill();
  return canvas;
}
