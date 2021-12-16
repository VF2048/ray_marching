<script>
  import { onMount } from "svelte";
  import * as mat4 from "gl-mat4-esm";
  import fsSource from "./shaders/fsSource.glsl";
  import vsSource from "./shaders/vsSource.glsl";

  let canvas;
  let canv = { w: 900, h: 900 };
  let fov = 1; // field of view "zoom"
  let rows = canv.h;
  let cols = canv.w;
  let cam = {
    alpha: 3.9,
    beta: 0.4,
    x: 5,
    y: 5,
    z: 2
  };
  let speed = 10;
  let buttons = {};
  let pixelSize;
  let iFracAng1 = 0;
  let iFracAng2 = 0;
  let iFracScale = 0.97;
  let iFracShift = { alpha: 0, beta: 0, x: 0.0, y: 0.0, z: 0.0 };

  function main() {
    const canvas = document.querySelector("#glCanvas");
    // Инициализируйте контекст GL
    const gl = canvas.getContext("webgl");

    // Продолжать, только если WebGL доступен и работает
    if (gl === null) {
      alert(
        "Unable to initialize WebGL. Your browser or machine may not support it."
      );
      return;
    }

    // Initialize a shader program; this is where all the lighting
    // for the vertices and so forth is established.
    const shaderProgram = initShaderProgram(gl, vsSource, fsSource);

    // Collect all the info needed to use the shader program.
    // Look up which attributes our shader program is using
    // for aVertexPosition, aVevrtexColor and also
    // look up uniform locations.
    const programInfo = {
      program: shaderProgram,
      attribLocations: {
        vertexPosition: gl.getAttribLocation(shaderProgram, "aVertexPosition")
      },
      uniformLocations: {
        projectionMatrix: gl.getUniformLocation(
          shaderProgram,
          "uProjectionMatrix"
        ),

        camX: gl.getUniformLocation(shaderProgram, "camX"),
        camY: gl.getUniformLocation(shaderProgram, "camY"),
        camZ: gl.getUniformLocation(shaderProgram, "camZ"),

        x0: gl.getUniformLocation(shaderProgram, "x0"),
        y0: gl.getUniformLocation(shaderProgram, "y0"),
        z0: gl.getUniformLocation(shaderProgram, "z0"),

        vx: gl.getUniformLocation(shaderProgram, "vx"),
        vy: gl.getUniformLocation(shaderProgram, "vy"),
        vz: gl.getUniformLocation(shaderProgram, "vz"),

        ux: gl.getUniformLocation(shaderProgram, "ux"),
        uy: gl.getUniformLocation(shaderProgram, "uy"),
        uz: gl.getUniformLocation(shaderProgram, "uz"),

        rows: gl.getUniformLocation(shaderProgram, "rows"),
        cols: gl.getUniformLocation(shaderProgram, "cols"),

        iFracScale: gl.getUniformLocation(shaderProgram, "iFracScale"),
        iFracShift: gl.getUniformLocation(shaderProgram, "iFracShift"),
        iFracAng1: gl.getUniformLocation(shaderProgram, "iFracAng1"),
        iFracAng2: gl.getUniformLocation(shaderProgram, "iFracAng2"),

        modelViewMatrix: gl.getUniformLocation(
          shaderProgram,
          "uModelViewMatrix"
        )
      }
    };

    // Here's where we call the routine that builds all the
    // objects we'll be drawing.
    const buffers = initBuffers(gl);

    let frame;
    (function loop() {
      frame = requestAnimationFrame(loop);

      pixelSize = Math.tan(fov / 2) / (rows / 2);

      if (buttons[87]) calc.move(cam.alpha, cam.beta, true);
      if (buttons[83]) calc.move(cam.alpha, cam.beta, false);
      if (buttons[65]) calc.move(cam.alpha + 1.4, 0, false);
      if (buttons[68]) calc.move(cam.alpha + 1.4, 0, true);
      if (buttons[32]) calc.move(0, cam.beta + 1.4, false);
      if (buttons[17]) calc.move(0, cam.beta + 1.4, true);

      if (buttons[100]) iFracAng1 += 0.001;
      if (buttons[97]) iFracAng1 -= 0.001;
      if (buttons[101]) iFracAng2 += 0.001;
      if (buttons[98]) iFracAng2 -= 0.001;
      if (buttons[102]) iFracScale += 0.001;
      if (buttons[99]) iFracScale -= 0.001;

      // Draw the scene
      drawScene(gl, programInfo, buffers, calc.cord(cam.alpha, cam.beta));
    })();
  }

  //
  // initBuffers
  //
  // Initialize the buffers we'll need. For this demo, we just
  // have one object -- a simple two-dimensional square.
  //
  function initBuffers(gl) {
    // Create a buffer for the square's positions.
    const positionBuffer = gl.createBuffer();

    // Select the positionBuffer as the one to apply buffer
    // operations to from here out.
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);

    // Now create an array of positions for the square.
    const positions = [-1.0, 1.0, 1.0, 1.0, -1.0, -1.0, 1.0, -1.0];

    // Now pass the list of positions into WebGL to build the
    // shape. We do this by creating a Float32Array from the
    // JavaScript array, then use it to fill the current buffer.
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(positions), gl.STATIC_DRAW);

    // Now set up the texture coordinates for the faces.
    const textureCoordBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, textureCoordBuffer);

    const textureCoordinates = [
      // Front
      1.0,
      1.0,
      1.0,
      0.0,
      1.0,
      1.0,
      0.0,
      1.0
    ];

    gl.bufferData(
      gl.ARRAY_BUFFER,
      new Float32Array(textureCoordinates),
      gl.STATIC_DRAW
    );

    return {
      position: positionBuffer,
      textureCoord: textureCoordBuffer
    };
  }

  //
  // Draw the scene.
  //
  function drawScene(gl, programInfo, buffers, cord) {
    gl.clearColor(1.0, 1.0, 1.0, 1.0); // Clear to black, fully opaque
    gl.clearDepth(1.0); // Clear everything
    gl.enable(gl.DEPTH_TEST); // Enable depth testing
    gl.depthFunc(gl.LEQUAL); // Near things obscure far things

    // Clear the canvas before we start drawing on it.
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    // Create a perspective matrix, a special matrix that is
    // used to simulate the distortion of perspective in a camera.
    // Our field of view is 45 degrees, with a width/height
    // ratio that matches the display size of the canvas
    // and we only want to see objects between 0.1 units
    // and 100 units away from the camera.
    const fieldOfView = (45 * Math.PI) / 180; // in radians
    const aspect = gl.canvas.clientWidth / gl.canvas.clientHeight;
    const zNear = 0.1;
    const zFar = 100.0;
    const projectionMatrix = mat4.create();

    // note: glmatrix.js always has the first argument
    // as the destination to receive the result.
    mat4.perspective(projectionMatrix, fieldOfView, aspect, zNear, zFar);

    // Set the drawing position to the "identity" point, which is
    // the center of the scene.
    const modelViewMatrix = mat4.create();

    // Now move the drawing position a bit to where we want to
    // start drawing the square.
    mat4.translate(
      modelViewMatrix, // destination matrix
      modelViewMatrix, // matrix to translate
      [-0.0, 0.0, -1.0]
    ); // amount to translate

    // Tell WebGL how to pull out the positions from the position
    // buffer into the vertexPosition attribute.
    {
      const numComponents = 2; // pull out 2 values per iteration
      const type = gl.FLOAT; // the data in the buffer is 32bit floats
      const normalize = false; // don't normalize
      const stride = 0; // how many bytes to get from one set of values to the next
      // 0 = use type and numComponents above
      const offset = 0; // how many bytes inside the buffer to start from
      gl.bindBuffer(gl.ARRAY_BUFFER, buffers.position);
      gl.vertexAttribPointer(
        programInfo.attribLocations.vertexPosition,
        numComponents,
        type,
        normalize,
        stride,
        offset
      );
      gl.enableVertexAttribArray(programInfo.attribLocations.vertexPosition);
    }

    {
      const num = 2; // every coordinate composed of 2 values
      const type = gl.FLOAT; // the data in the buffer is 32 bit float
      const normalize = false; // don't normalize
      const stride = 0; // how many bytes to get from one set to the next
      const offset = 0; // how many bytes inside the buffer to start from
      gl.vertexAttribPointer(
        programInfo.attribLocations,
        num,
        type,
        normalize,
        stride,
        offset
      );
    }

    // Tell WebGL to use our program when drawing
    gl.useProgram(programInfo.program);

    gl.uniform1f(programInfo.uniformLocations.camX, parseFloat(cord.camX));
    gl.uniform1f(programInfo.uniformLocations.camY, parseFloat(cord.camY));
    gl.uniform1f(programInfo.uniformLocations.camZ, parseFloat(cord.camZ));

    gl.uniform1f(programInfo.uniformLocations.x0, parseFloat(cord.x0));
    gl.uniform1f(programInfo.uniformLocations.y0, parseFloat(cord.y0));
    gl.uniform1f(programInfo.uniformLocations.z0, parseFloat(cord.z0));

    gl.uniform1f(programInfo.uniformLocations.vx, parseFloat(cord.vx));
    gl.uniform1f(programInfo.uniformLocations.vy, parseFloat(cord.vy));
    gl.uniform1f(programInfo.uniformLocations.vz, parseFloat(cord.vz));

    gl.uniform1f(programInfo.uniformLocations.ux, parseFloat(cord.ux));
    gl.uniform1f(programInfo.uniformLocations.uy, parseFloat(cord.uy));
    gl.uniform1f(programInfo.uniformLocations.uz, parseFloat(cord.uz));

    gl.uniform1f(programInfo.uniformLocations.rows, parseFloat(rows));
    gl.uniform1f(programInfo.uniformLocations.cols, parseFloat(cols));

    gl.uniform1f(
      programInfo.uniformLocations.iFracScale,
      parseFloat(iFracScale)
    );
    gl.uniform3f(
      programInfo.uniformLocations.iFracShift,
      parseFloat(iFracShift.x),
      parseFloat(iFracShift.y),
      parseFloat(iFracShift.z)
    );

    gl.uniform1f(programInfo.uniformLocations.iFracAng1, parseFloat(iFracAng1));
    gl.uniform1f(programInfo.uniformLocations.iFracAng2, parseFloat(iFracAng2));

    // Set the shader uniforms
    gl.uniformMatrix4fv(
      programInfo.uniformLocations.projectionMatrix,
      false,
      projectionMatrix
    );
    gl.uniformMatrix4fv(
      programInfo.uniformLocations.modelViewMatrix,
      false,
      modelViewMatrix
    );

    {
      const offset = 0;
      const vertexCount = 4;
      gl.drawArrays(gl.TRIANGLE_STRIP, offset, vertexCount);
    }
  }

  //
  // Initialize a shader program, so WebGL knows how to draw our data
  //
  function initShaderProgram(gl, vsSource, fsSource) {
    const vertexShader = loadShader(gl, gl.VERTEX_SHADER, vsSource);
    const fragmentShader = loadShader(gl, gl.FRAGMENT_SHADER, fsSource);

    // Create the shader program

    const shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.linkProgram(shaderProgram);

    // If creating the shader program failed, alert

    if (!gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)) {
      alert(
        "Unable to initialize the shader program: " +
          gl.getProgramInfoLog(shaderProgram)
      );
      return null;
    }
    return shaderProgram;
  }

  //
  // creates a shader of the given type, uploads the source and
  // compiles it.
  //
  function loadShader(gl, type, source) {
    const shader = gl.createShader(type);

    // Send the source to the shader object

    gl.shaderSource(shader, source);

    // Compile the shader program

    gl.compileShader(shader);

    // See if it compiled successfully

    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      alert(
        "An error occurred compiling the shaders: " +
          gl.getShaderInfoLog(shader)
      );
      gl.deleteShader(shader);
      return null;
    }

    return shader;
  }

  function isPowerOf2(value) {
    return (value & (value - 1)) == 0;
  }

  let calc = {
    cord: (alpha, beta) => {
      return {
        x0: Math.cos(beta) * Math.cos(alpha),
        y0: Math.sin(alpha) * Math.cos(beta),
        z0: -Math.sin(beta),

        vx: -pixelSize * Math.sin(alpha),
        vy: pixelSize * Math.cos(alpha),
        vz: 0,

        ux: pixelSize * Math.sin(beta) * Math.cos(alpha),
        uy: pixelSize * Math.sin(alpha) * Math.sin(beta),
        uz: pixelSize * Math.cos(beta),

        camX: cam.x,
        camY: cam.y,
        camZ: cam.z
      };
    },
    move: (alpha, beta, inc) => {
      let cords = calc.cord(alpha, beta);
      let x = (cords.x0 + cords.vx + cords.ux) / speed;
      let y = (cords.y0 + cords.vy + cords.uy) / speed;
      let z = (cords.z0 + cords.vz + cords.uz) / speed;
      if (inc) {
        cam.x += x;
        cam.y += y;
        cam.z += z;
      } else {
        cam.x -= x;
        cam.y -= y;
        cam.z -= z;
      }
    }
  };

  let cont = {
    lock: () => {
      return (
        document.pointerLockElement === canvas ||
        document.mozPointerLockElement === canvas
      );
    },
    keyListener: (pressed, e) => {
      buttons[e.keyCode] = pressed;
    },

    requestPointerLock: () => {
      canvas.requestPointerLock =
        canvas.requestPointerLock || canvas.mozRequestPointerLock;
      canvas.requestPointerLock();
    },

    mousemove: e => {
      if (buttons[90]) {
        iFracShift.beta += e.movementY / 1000;
        iFracShift.alpha += e.movementX / 1000;
        let cord = calc.cord(iFracShift.alpha,iFracShift.beta);
        iFracShift.x = (cord.x0 + cord.vx + cord.ux)*10;
        iFracShift.y = (cord.y0 + cord.vy + cord.uy)*10;
        iFracShift.z = (cord.z0 + cord.vz + cord.uz)*10;
        console.log(iFracShift.x, iFracShift.y, iFracShift.z);
      } else if (cont.lock()) {
        cam.beta += e.movementY / 1000;
        cam.alpha += e.movementX / 1000;
      }
    },
    mousewheel: e => {
      if (e.wheelDelta < 0) speed += 10;
      else if (speed > 20) speed -= 10;
    }
  };
</script>

<svelte:window
  on:load={main()}
  on:keydown={e => cont.keyListener(1, e)}
  on:keyup={e => cont.keyListener(0, e)}
  on:mousemove={cont.mousemove}
  on:mousewheel={cont.mousewheel} />

<main>
  <canvas
    on:click={cont.requestPointerLock}
    bind:this={canvas}
    id="glCanvas"
    width={canv.w}
    height={canv.h} />
</main>
