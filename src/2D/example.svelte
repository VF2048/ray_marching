<script>
  export let canvasElement;
  export let canv;

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
</script>

<main>
  <canvas
    on:mousemove={onMouseUpdate}
    bind:this={canvasElement}
    width={canv.w}
    height={canv.h}
  />
</main>

<style>
  canvas {
    border: 1px solid #000000;
  }
</style>
