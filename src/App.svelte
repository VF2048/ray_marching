<script>
  import { onMount } from "svelte";
  import GL3D from "./3D/Gl3D.svelte";
  import CanvImgD from "./CanvImgD.svelte";

  let canvasElement;
  let my = 0,
    mx = 0,
    sight = { x: 0, y: 0 },
    canv = { w: 1000, h: 900 },
    dots = [],
    dots3D = [];
  let selector = 3;
  let circle = { x: 600, y: 400, z: 100, r: 50 };
  let boxes = [{ x: canv.w * 0.5, y: canv.h * 0.3, z: 100, s: canv.h * 0.05 }];
  let cam = { x: 100, y: 400, z: 10 };
  let alpha = 23.5619;
  let beta = 50;

  function render3D(beta) {
    dots3D = [];
    let fov = 39; // field of view "zoom"
    let dista = 1;
    let rows = canv.h - 600;
    let cols = canv.w - 800;

    let pixelSize = Math.tan(fov / 2) / (rows / 2);

    let camX = dista * Math.cos(beta) * Math.cos(alpha);
    let ux = -pixelSize * Math.sin(alpha);
    let vx = pixelSize * Math.sin(beta) * Math.cos(alpha);
    let x0 = -Math.cos(beta) * Math.cos(alpha);

    let camY = dista * Math.sin(beta);
    let vy = -pixelSize * Math.cos(beta);
    let y0 = -Math.sin(beta);

    let camZ = dista * Math.cos(beta) * Math.sin(alpha);
    let uz = pixelSize * Math.cos(alpha);
    let vz = pixelSize * Math.sin(beta) * Math.sin(alpha);
    let z0 = -Math.cos(beta) * Math.sin(alpha);

    for (let c = -cols; c < cols; c++) {
      let cx = x0 + ux * (c - cols / 2);
      let cz = z0 + uz * (c - cols / 2);
      for (let l = -rows; l < rows; l++) {
        let lx = vx * (l - rows / 2);
        let ly = y0 + vy * (l - rows / 2);
        let lz = vz * (l - rows / 2);
        let n =
          1 /
          Math.sqrt(
            Math.pow(lx + ly, 2) + Math.pow(ly, 2) + Math.pow(lz + cz, 2)
          );
        let x = (lx + cx) * n;
        let y = ly * n;
        let z = (lz + cz) * n;
        let dist3D = distance3D(camX, camY, camZ, x, y, z);
        if (dist3D) dots3D.push({ x: c + 50, y: l + 50, z: dist3D });
      }
    }
    return dots3D;
  }

  function distance3D(camX, camY, camZ, x, y, z) {
    let dist0 = 0;
    let dist1 = 0;
    let dist2 = 0;
    let dotx = 0,
      doty = 0,
      dotz = 0;
    for (let i = 0; i < 50; i++) {
      dist0 = dist1;
      dist1 = dist2;
      if (dist2 != 0) {
        dotx = x;
        doty = y;
        dotz = z;
      }
      dist2 =
        dist1 +
        Math.max(
          Math.abs(camX + dotx * dist1) - 0.3,
          Math.abs(camY + doty * dist1) - 0.3,
          Math.abs(camZ + dotz * dist1) - 0.3,
          -Math.sqrt(
            Math.pow(camX + dotx * dist1, 2) +
              Math.pow(camY + doty * dist1, 2) +
              Math.pow(camZ + dotz * dist1, 2)
          ) + 0.375
        );
      if (dist2 - dist1 < 0.0001)
        return console.log((dist2 - dist1) / (dist1 - dist0));
    }
    return false;
  }

  function onMouseUpdate(e) {
    mx = e.pageX;
    my = e.pageY;
    dots = [];
    if (selector !== 2) return;

    for (let i = -Math.PI; i < Math.PI; i += 0.01) {
      let x = e.pageX;
      let y = e.pageY;
      let dx = Math.cos(i);
      let dy = Math.sin(i);

      for (let i = 0; i < 30; i++) {
        let distance = dist(x, y);
        if (distance > canv.w) continue;
        if (distance < 1) {
          dots.push({ x: x + dx * 5, y: y + dy * 5 });
        }
        x += dx * distance;
        y += dy * distance;
        // z += dz * distance;
      }
    }
  }

  function dist(x, y, z) {
    let dist1 = distCircle(x, y, z);
    let dist2 = distBox(x, y, z);
    return Math.min(dist1, dist2);
  }

  function distCircle(x, y, z) {
    if (selector === 3)
      return (
        Math.sqrt(
          Math.pow(x - circle.x, 2) +
            Math.pow(y - circle.y, 2) +
            Math.pow(z - circle.z, 2)
        ) - circle.r
      );
    else
      return (
        Math.sqrt(Math.pow(x - circle.x, 2) + Math.pow(y - circle.y, 2)) -
        circle.r
      );
  }

  function distBox(x, y) {
    let s = boxes[0].s;
    let dx = Math.abs(x - boxes[0].x) - s;
    let dy = Math.abs(y - boxes[0].y) - s;
    let l = Math.sqrt(
      Math.pow(Math.max(dx, 0), 2) + Math.pow(Math.max(dy, 0), 2)
    );
    return l + Math.min(Math.max(dx, dy), 0);
  }

  onMount(() => {
    if (selector > 3) return;
    const ctx = canvasElement.getContext("2d");
    let frame;

    (function loop() {
      frame = requestAnimationFrame(loop);
      ctx.clearRect(0, 0, 1000, 900);

      ctx.beginPath();

      if (selector === 3) {
        render3D(beta);
        if (beta < 26.6) beta += 0.01;
        else beta = 20.3;
        for (let i = 0; i < dots3D.length; i++) {
          ctx.fillStyle = "rgb(4,0," + (255 - Math.pow(dots3D[i].z, 1.5)) + ")";
          ctx.fillRect(dots3D[i].x, dots3D[i].y, 1, 1);
        }
      } else if (selector === 2)
        for (let i = 0; i < dots.length; i++) {
          ctx.fillStyle = "#0400ff";
          ctx.fillRect(dots[i].x, dots[i].y, 1, 1);
        }

      ctx.fill();

      if (selector !== 1) return;

      for (let i = 0; i < boxes.length; i++) {
        ctx.beginPath();
        ctx.fillStyle = "#0072ff";
        ctx.rect(
          boxes[i].x - boxes[i].s,
          boxes[i].y - boxes[i].s,
          boxes[i].s * 2,
          boxes[i].s * 2
        );
        ctx.fill();
      }

      ctx.beginPath();
      ctx.fillStyle = "#0008ff";
      ctx.arc(cam.x, cam.y, 2, 0, 2 * Math.PI);
      ctx.arc(circle.x, circle.y, circle.r, 0, 2 * Math.PI);
      ctx.fill();

      sight.x = cam.x;
      sight.y = cam.y;
      let angle = Math.atan2(my - sight.y, mx - sight.x);
      let dx = Math.cos(angle);
      let dy = Math.sin(angle);
      for (let i = 0; i < 30; i++) {
        let distance = dist(sight.x, sight.y);
        if (distance > canv.w) continue;
        if (distance < 0) continue;

        ctx.beginPath();
        ctx.arc(sight.x, sight.y, distance, 0, 2 * Math.PI);
        ctx.moveTo(sight.x + dx, sight.y + dy);
        sight.x += dx * distance;
        sight.y += dy * distance;
        ctx.lineTo(sight.x, sight.y);
        ctx.stroke();
      }
    })();
  });
</script>

<main src="https://cdn.jsdelivr.net/npm/gl-matrix@3.0.0/gl-matrix-min.js">
  <input type="range" bind:value={beta} step="0.001" min="20" max="30" />
  <input
    type="range"
    bind:value={alpha}
    step="0.001"
    min="21.99"
    max="23.555"
  />
  <select
    value={selector}
    on:change={(e) => (selector = parseInt(e.target.value))}
  >
    <option value={1}>Пример</option>
    <option value={2}>2D</option>
    <option value={3}>3D</option>
    <option value={4}>CanvImgD</option>
    <option value={5}>GL3D</option>
  </select>
  {#if selector === 4}
    <CanvImgD render={render3D} {canv} />
  {:else if selector === 5}
    <GL3D />
  {:else}
    <canvas
      on:mousemove={onMouseUpdate}
      bind:this={canvasElement}
      width={canv.w}
      height={canv.h}
    />
  {/if}
</main>
