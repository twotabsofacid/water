precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec3 u_colorNear;
uniform vec3 u_colorFar;

varying vec2 v_texcoord;

// Water at Night
// by Sean Scanlan
// heavily based off of:
// Stockholms Ström
// by Peder Norrby / Trapcode in 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

// Description : Array and textureless GLSL 2D/3D/4D simplex 
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
// 

#define box_y 1.0
#define box_x 2.0
#define box_z 2.0
#define bg vec4(0.0, 0.0, 0.0, 1.0)
#define traceStep 0.5
#define steps 8
#define cameraDistance 80.0
#define noiseMultipler 42.0
#define red vec4(5.0, 0.0, 0.0, 1.0)
#define waterColor vec4(0.0, 0.3, 0.5, 1.0)
#define redHue vec4(2.0, 0.5, 0.5, 1.0)
#define orangeHue vec4(1.0, 0.4, 0.25, 1.0)
#define PI_HALF 1.5707963267949

vec3 mod289(vec3 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
	return mod289(((x * 34.0) + 1.0) * x);
}

vec4 taylorInvSqrt(vec4 r) {
	return 1.79284291400159 - 0.85373472095314 * r;
}

vec4 lighten(vec4 c, float amt) {
	return vec4(c.x * amt, c.y * amt, c.z * amt, 1.0);
}

float noise(vec3 v) { 
	const vec2 C = vec2(1.0/6.0, 1.0/3.0);
	const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

	// First corner
	vec3 i  = floor(v + dot(v, C.yyy));
	vec3 x0 = v - i + dot(i, C.xxx);

	// Other corners
	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0 - g;
	vec3 i1 = min(g.xyz, l.zxy);
	vec3 i2 = max(g.xyz, l.zxy);

	vec3 x1 = x0 - i1 + C.xxx;
	vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
	vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

	// Permutations
	i = mod289(i); 
	vec4 p = permute(permute(permute( 
		i.z + vec4(0.0, i1.z, i2.z, 1.0))
		+ i.y + vec4(0.0, i1.y, i2.y, 1.0)) 
		+ i.x + vec4(0.0, i1.x, i2.x, 1.0));

	// Gradients: 7x7 points over a square, mapped onto an octahedron.
	// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
	float n_ = 0.142857142857; // 1.0/7.0
	vec3  ns = n_ * D.wyz - D.xzx;

	vec4 j = p - 49.0 * floor(p * ns.z * ns.z);// mod(p,7*7)

	vec4 x_ = floor(j * ns.z);
	vec4 y_ = floor(j - 7.0 * x_);// mod(j,N)

	vec4 x = x_ * ns.x + ns.yyyy;
	vec4 y = y_ * ns.x + ns.yyyy;
	vec4 h = 1.0 - abs(x) - abs(y);

	vec4 b0 = vec4(x.xy, y.xy);
	vec4 b1 = vec4(x.zw, y.zw);

	vec4 s0 = floor(b0) * 2.0 + 1.0;
	vec4 s1 = floor(b1) * 2.0 + 1.0;
	vec4 sh = -step(h, vec4(0.0));

	vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy ;
	vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww ;

	vec3 p0 = vec3(a0.xy, h.x);
	vec3 p1 = vec3(a0.zw, h.y);
	vec3 p2 = vec3(a1.xy, h.z);
	vec3 p3 = vec3(a1.zw, h.w);

	//Normalise gradients
	vec4 norm = taylorInvSqrt(vec4(dot(p0, p0),
		dot(p1, p1),
		dot(p2, p2),
		dot(p3,p3)));
		p0 *= norm.x;
		p1 *= norm.y;
		p2 *= norm.z;
		p3 *= norm.w;

	// Mix final noise value
	vec4 m = max(0.6 - vec4(dot(x0, x0),
		dot(x1,x1),
		dot(x2,x2),
		dot(x3,x3)),
		0.0);
	// This looks nice, you can tweak 
	// multiplying m by itself to change the severity of
	// the waves
	m = m * m * (m * 1.25);
	return noiseMultipler * dot(m * m, vec4(dot(p0, x0),
		dot(p1, x1), 
		dot(p2, x2),
		dot(p3, x3)));
}

float fnoise(vec3 p) {
	float add = noise(p);
	float msc = clamp(add + 0.7, 0.0, 1.0);
	float sum = 0.6 * add;

	p = p * 2.0;
	add = noise(p);

	add *= msc;
	sum += 0.5 * add;
	msc *= add + 0.7;
	msc = clamp(msc, 0.0, 1.0);

	p.xy = p.xy * 2.0;
	add = noise(p);
	add *= msc;
	sum += 0.25 * abs(add);
	msc *= add + 0.7;
	msc = clamp(msc, 0.0, 1.0);

	p = p * 2.0;
	add = noise(p);
	add *= msc;
	sum += 0.125 * abs(add);
	msc *= add + 0.2;
	msc = clamp(msc, 0.0, 1.0);

	p = p * 2.0;
	add = noise(p);
	add *= msc;
	sum += 0.0625*abs(add);

	return sum * 0.516129;
}

float getHeight(vec3 p) { // x,z,time
	return 0.3 - (0.5 * fnoise(vec3(0.5 * (p.x + sin(u_time/100.0)), 0.5 * p.z,  0.4 * u_time)));
}

vec4 getSky(vec3 rd) {
	if (rd.y > 0.3) return vec4(0.5, 0.8, 1.0, 1.0); // bright sky
	if (rd.y < 0.0) return waterColor; // no reflection from below

	// if we've got a wave and 
	if (rd.z > 0.9 && rd.x > 0.3) {
		if (rd.y > 0.2) {
			// red hues
			return 1.5 * redHue;
		}
		// orange hues
		return 1.5 * orangeHue;
	} else {
		// return the water but brighter,
		// because we're closer to the sun location
		return lighten(waterColor, 1.05);
	}
}

// This colors the top of the water
vec4 shade(vec3 normal, vec3 pos, vec3 rd) {
	float ReflectionFresnel = 0.99;
	float fresnel = ReflectionFresnel * pow(1.0 - clamp(dot(-rd, normal), 0.0, 1.0), 5.0) + (1.0 - ReflectionFresnel);
	vec3 refVec = reflect(rd, normal);
	vec4 reflection = getSky(refVec);

	// This isn't used... but should/could be?
	vec3 sunDir = normalize(vec3(-1.0, -1.0, 0.5));
	float intens = 0.5 + 0.5 * clamp(dot(normal, sunDir), 0.0, 1.0);

	float deep = 1.0 + 0.5 * pos.y;

	vec4 col = fresnel * reflection;
	
	// mix some colors :)
	// we can use rd bc that splits the screen up well
	vec4 tint1 = vec4(u_colorNear.r, u_colorNear.g, u_colorNear.b, 1.0);
	vec4 tint2 = vec4(u_colorFar.r, u_colorFar.g, u_colorFar.b, 1.0);
	vec4 waterColorMix = mix(tint1, tint2, rd.z);
	// This splits up the water into sections
	float start = 0.61;
	float stop = 0.78;
	if (rd.z < start) {
		col += deep * 0.4 * tint1;
	} else if (rd.z < stop) {
		col += deep * 0.4 * mix(tint1, tint2, (rd.z - start)/(stop - start));
	} else {
		col += deep * 0.4 * tint2;
	}

	return clamp(col, 0.0, 1.0);
}

// Ray tracing :)
vec4 trace_heightfield(vec3 ro, vec3 rd) {
	// intersect with max h plane, y=1
	float t = (1.0 - ro.y) / rd.y;
	vec3 p = ro + t * rd;

	float h, last_h;
	bool not_found = true;
	vec3 last_p = p;

	for (int i = 0; i < steps; i++) {
		p += traceStep * rd;
		h = getHeight(p);

		if (p.y < h) {
			not_found = false;
			break;
		}
		// we stepped through
		last_h = h;
		last_p = p;
	}

	if (not_found) return bg;

	// refine interection
	float dh2 = h - p.y;
	float dh1 = last_p.y - last_h;
	p = last_p + rd * traceStep/(dh2/dh1 + 1.0);

	vec3 pdx = p + vec3(0.01, 0.0, 0.00);
	vec3 pdz = p + vec3(0.00, 0.0, 0.01);

	float hdx = getHeight(pdx);
	float hdz = getHeight(pdz);
	h = getHeight(p);

	p.y = h;
	pdx.y = hdx;
	pdz.y = hdz;

	vec3 normal = normalize(cross(p - pdz, p - pdx));

	return shade(normal, p, rd);
}


// Shadertoy camera code by iq
mat3 setCamera(in vec3 ro, in vec3 ta, float cr) {
	vec3 cw = normalize(ta - ro);
	vec3 cp = vec3(sin(cr), cos(cr), 0.0);
	vec3 cu = normalize(cross(cw, cp));
	vec3 cv = normalize(cross(cu, cw));
	return mat3(cu, cv, cw);
}


void main() {
	vec2 p = (-u_resolution.xy + 2.0 * gl_FragCoord.xy)/ u_resolution.y;
	vec2 m = vec2(0.0, 0.5);

	m.y += 0.3;
	m.x += 0.72;

	// camera
	vec3 ro = cameraDistance*normalize(vec3(sin(5.0 * m.x),
		m.y,
		cos(5.0 * m.x))); // positon
		vec3 ta = vec3(0.0, 0.0, 0.0); // target
		mat3 ca = setCamera(ro, ta, 0.0);

	// ray
	vec3 rd = ca * normalize(vec3(p.xy, 4.0));

	vec4 color = trace_heightfield(ro, rd);
	color.a = 1.0;
	gl_FragColor = color;
}

