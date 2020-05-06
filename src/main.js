'use strict';
import * as dat from 'dat.gui';

let canvas, gui, guiIsShowing;

const onKeyup = (e) => {
	if (e.code && e.code === 'Space') {
		if (guiIsShowing) {
			gui.hide();
			guiIsShowing = false;
		} else {
			gui.show();
			guiIsShowing = true;
		}
	}
}

const resizeCanvas = () => {
	console.log('we resize');
	canvas.width = window.innerWidth;
	canvas.height = window.innerHeight;
}

const main = async () => {
	console.log('Hello, WebGL!');

	//////////////////////////////////////////////
	// create a gui
	gui = new dat.GUI();
	guiIsShowing = true;

	const options = {
		numColors: 2
	};
	const palette = {
		colorOne: [0, 40, 128 ],
		colorTwo: [20, 20, 80],
		colorThree: [10, 30, 15],
		colorFour: [55, 30, 15],
		colorSun: [255, 120, 80]
	};
	gui.add(options, 'numColors').min(1).max(3).step(1);
	gui.addColor(palette, 'colorOne');
	gui.addColor(palette, 'colorTwo');
	gui.addColor(palette, 'colorThree');
	gui.addColor(palette, 'colorSun');
	// gui.addColor(palette, 'colorFour');

	//////////////////////////////////////////////
	// get the canvas
	canvas = document.querySelector('#glcanvas');

	//////////////////////////////////////////////
	// Resize the canvas
	resizeCanvas();

	//////////////////////////////////////////////
	// create the context
	const gl = canvas.getContext('webgl');


	//////////////////////////////////////////////
	// load shaders
	const vertex_shader_source = await fetch(canvas.dataset.vert).then(r => r.text());
	console.log(vertex_shader_source);

	const fragment_shader_source = await fetch(canvas.dataset.frag).then(r => r.text());
	console.log(fragment_shader_source);

	//////////////////////////////////////////////
	// compile/link the shader program

	// compile vertex shader
	const vertex_shader = gl.createShader(gl.VERTEX_SHADER);
	gl.shaderSource(vertex_shader, vertex_shader_source);
	gl.compileShader(vertex_shader);

	if (!gl.getShaderParameter(vertex_shader, gl.COMPILE_STATUS)) {
		console.log('Error in vertex shader: \n\n' + gl.getShaderInfoLog(vertex_shader));
		gl.deleteShader(vertex_shader);
		return null;
	}

	// compile fragment shader
	const fragment_shader = gl.createShader(gl.FRAGMENT_SHADER);
	gl.shaderSource(fragment_shader, fragment_shader_source);
	gl.compileShader(fragment_shader);

	if (!gl.getShaderParameter(fragment_shader, gl.COMPILE_STATUS)) {
		console.log('Error in fragment shader: \n\n' + gl.getShaderInfoLog(fragment_shader));
		gl.deleteShader(fragment_shader);
		return null;
	}

	// link fragment and vertex shader
	const shader_program = gl.createProgram();
	gl.attachShader(shader_program, vertex_shader);
	gl.attachShader(shader_program, fragment_shader);
	gl.linkProgram(shader_program);

	if (!gl.getProgramParameter(shader_program, gl.LINK_STATUS)) {
		console.log('Error initializing shader program: \n\n' + gl.getProgramInfoLog(shader_program));
		return null;
	}




	//////////////////////////////////////////////
	// query the shaders for attibute and uniform "locations"
	const vertex_position_location = gl.getAttribLocation(shader_program, 'aVertexPosition');
	const vertex_uv_location = gl.getAttribLocation(shader_program, 'aVertexUV');
	const u_time_location = gl.getUniformLocation(shader_program, "u_time");
	const u_numColors_location = gl.getUniformLocation(shader_program, "u_numColors");
	const u_resolution_location = gl.getUniformLocation(shader_program, "u_resolution");
	const u_colorOne_location = gl.getUniformLocation(shader_program, "u_colorOne");
	const u_colorTwo_location = gl.getUniformLocation(shader_program, "u_colorTwo");
	const u_colorThree_location = gl.getUniformLocation(shader_program, "u_colorThree");
	const u_colorFour_location = gl.getUniformLocation(shader_program, "u_colorFour");
	const u_colorSun_location = gl.getUniformLocation(shader_program, "u_colorSun");

	//////////////////////////////////////////////
	// buffer the vertex data

	// vertex position data
	const position_buffer = gl.createBuffer();
	gl.bindBuffer(gl.ARRAY_BUFFER, position_buffer);
	const positions = [
		1.0, 1.0, // right top
		-1.0, 1.0, // left top
		1.0, -1.0, // right bottom
		-1.0, -1.0, // left bottom
	];
	gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(positions), gl.STATIC_DRAW);
	gl.vertexAttribPointer(vertex_position_location, 2, gl.FLOAT, false, 0, 0);
	gl.enableVertexAttribArray(vertex_position_location);


	// vertex color data
	const uv_buffer = gl.createBuffer();
	gl.bindBuffer(gl.ARRAY_BUFFER, uv_buffer);
	const uvs = [
		1.0, 1.0, // right top
		0.0, 1.0, // left top
		1.0, 0.0, // right bottom
		0.0, 0.0, // left bottom
	];
	gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(uvs), gl.STATIC_DRAW);
	gl.vertexAttribPointer(vertex_uv_location, 2, gl.FLOAT, false, 0, 0);
	gl.enableVertexAttribArray(vertex_uv_location);


	//////////////////////////////////////////////
	// configure gl
	gl.enable(gl.DEPTH_TEST);
	gl.depthFunc(gl.LEQUAL);


	//////////////////////////////////////////////
	// draw

	// clear the background
	gl.clearColor(0.0, 0.0, 0.0, 1.0);
	gl.clearDepth(1.0);
	gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);


	//////////////////////////////////////////////
	// set up animation loop
	let start_time = Date.now();
	function render() {
		// activate our program
		gl.useProgram(shader_program);

		// update uniforms
		gl.uniform2fv(u_resolution_location, [canvas.width, canvas.height]);
		gl.uniform1f(u_time_location, (Date.now() - start_time) * .001);
		gl.uniform1i(u_numColors_location, options.numColors);
		gl.uniform3fv(u_colorOne_location, palette.colorOne.map(item => item/255));
		gl.uniform3fv(u_colorTwo_location, palette.colorTwo.map(item => item/255));
		gl.uniform3fv(u_colorThree_location, palette.colorThree.map(item => item/255));
		gl.uniform3fv(u_colorFour_location, palette.colorFour.map(item => item/255));
		gl.uniform3fv(u_colorSun_location, palette.colorSun.map(item => item/255));

		// draw the geometry
		gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
		requestAnimationFrame(render);
	}
	//////////////////////////////////////////////
	// Add listeners
	document.addEventListener('keyup', onKeyup);

	//////////////////////////////////////////////
	// Run the mother fuckin animation
	requestAnimationFrame(render);
}

// Call the function :)
main();
