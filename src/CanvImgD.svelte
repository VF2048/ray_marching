<script>
  import { onMount } from "svelte";
  export let canv;
  export let render;

  let canvas,
    beta = 20.4;

  onMount(() => {
    const ctx = canvas.getContext("2d");

    let frame;
    let a = false;

    (function loop() {
      frame = requestAnimationFrame(loop);

      const imageData = ctx.createImageData(canv.w, canv.h);
      let pic = render(beta);
      if (beta < 26.6) beta += 0.01;
      else beta = 20.3;
      for (let i = 0; i < pic.length; i++) {
        let c = (pic[i].x * canv.w + pic[i].y) * 4;
        imageData.data[c + 0] = 4; // R value
        imageData.data[c + 1] = 0; // G value
        imageData.data[c + 2] = 255 - pic[i].z; // B value
        imageData.data[c + 3] = 255; // A value
      }

      // Draw image data to the canvas
      ctx.putImageData(imageData, 20, 20);
    })();
  });
</script>

<main>
  <canvas width={canv.w} height={canv.h} bind:this={canvas} />
</main>
