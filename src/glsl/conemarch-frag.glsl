#define T_MAX 15.0

varying vec2 f_uv;

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_aspect;
uniform float u_tan_fovy_over2;
uniform sampler2D u_previous_conemarch;
uniform mat4 u_camera_view;
uniform int u_pass_counter;

#define NUM_CONEMARCH_ITERATIONS 50
#define NUM_RAYMARCH_ITERATIONS 90

#define FINAL_PASS 2 // number of render passes - 1

#define LIGHT_VEC normalize(vec3(1.0, 1.0, 1.0))

//#define MANDELBULB
#define MENGER

vec4 resColor;

mat3 fromAngleAxis( in vec3 angle, in float angleRad ) {
    float cost = cos(angleRad);
    float sint = sin(angleRad);

    mat3 rot;
    rot[0] = vec3(
        cost + angle.x * angle.x * (1.0 - cost),
        angle.y * angle.x * (1.0 - cost) + angle.z * sint,
        angle.z * angle.x * (1.0 - cost) - angle.y * sint
        );
    rot[1] = vec3(
        angle.x * angle.y * (1.0 - cost) - angle.z * sint,
        cost + angle.y * angle.y * (1.0 - cost),
        angle.z * angle.y * (1.0 - cost) + angle.x * sint
        );
    rot[2] = vec3(
        angle.x * angle.z * (1.0 - cost) + angle.y * sint,
        angle.y * angle.z * (1.0 - cost) - angle.x * sint,
        cost + angle.z * angle.z * (1.0 - cost)
        );
    return rot;
}

/*****
Signed Distance Functions:
http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
http://www.iquilezles.org/www/articles/mandelbulb/mandelbulb.htm
http://www.iquilezles.org/www/articles/menger/menger.htm
*****/

float SDF_Sphere( in vec3 pos, in float radius ) {
	return length(pos) - radius;
}

float SDF_Box( in vec3 p, in vec3 b ) {
  vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float SDF_Mandelbulb( in vec3 p, inout vec4 trap )
{
	vec3 w = p;
    float m = dot(w,w);
    float dz = 1.0;
    
    for(int i = 0; i < 4; ++i)
    {
		#if 1

        float m2 = m * m;
        float m4 = m2 * m2;
        dz = 8.0 * sqrt(m4 * m2 * m) * dz + 1.0;

        float x = w.x; float x2 = x * x; float x4 = x2 * x2;
        float y = w.y; float y2 = y * y; float y4 = y2 * y2;
        float z = w.z; float z2 = z * z; float z4 = z2 * z2;

        float k3 = x2 + z2;
        float k2 = inversesqrt( k3 * k3 * k3 * k3 * k3 * k3 * k3 );
        float k1 = x4 + y4 + z4 - 6.0 * y2 * z2 - 6.0 * x2 * y2 + 2.0 * z2 * x2;
        float k4 = x2 - y2 + z2;

        w.x = p.x +  64.0 * x * y * z * (x2 - z2) * k4 * (x4 - 6.0 * x2 * z2 + z4) * k1 * k2;
        w.y = p.y + -16.0 * y2 * k3 * k4 * k4 + k1 * k1;
        w.z = p.z +  -8.0 * y * k4 * (x4 * x4 - 28.0 * x4 * x2 * z2 + 70.0 * x4 * z4 - 28.0 * x2 * z2 * z4 + z4 * z4) * k1 * k2;
		
		#else

		dz = 8.0 * pow(m, 3.5) * dz + 1.0;

        float r = length(w);
        float b = 8.0 * acos(clamp(w.y / r, -1.0, 1.0));
        float a = 8.0 * atan(w.x, w.z);
        w = p + pow(r, 8.0) * vec3(sin(b) * sin(a), cos(b), sin(b) * cos(a));
		
		#endif

        m = dot(w,w);
		trap = min(trap, vec4(abs(w), m));
		
        if(m > 4.0) {
            break;
		}
    }

	trap.x = m;
	resColor = trap;
    return 0.25 * log(m) * sqrt(m) / dz;
}

#ifdef MENGER

#define MENGER_ROT1 fromAngleAxis(normalize(vec3(cos(u_time * 0.5 + 1.0), sin(u_time * 0.75 + 0.1), sin(u_time * 0.35 + 0.3))), 32.0)
#define MENGER_ROT2 fromAngleAxis(normalize(vec3(sin(u_time * 0.25), cos(u_time * 0.15), cos(u_time * 0.15 + 2.0))), 7.0)

vec3 SDF_MengerSponge( in vec3 p, inout float trap )
{
	float d = SDF_Box(p, vec3(1.0));

	float s = 1.0;
	for(int m = 0; m < 2; ++m)
	{
		// Simple domain distortion, per iteration
		// Domain distortion for menger
		//float rotMask = step(mod(float(m), 2.0), 1.0);
		//p *= (1.0 - rotMask) * MENGER_ROT1 + rotMask * MENGER_ROT2;
		float scale = (sin(u_time * 0.5) * 0.5 + 0.5) * 1.0 + 1.0;
		p *= scale;

		vec3 a = mod(p * s, 2.0) - 1.0;
		s *= 3.0;
		vec3 r = abs(1.0 - 3.0 * abs(a));

		float da = max(r.x, r.y);
		float db = max(r.y, r.z);
		float dc = max(r.z, r.x);
		float c = (min(da, min(db, dc)) - 1.0) / s;

		d = max(d, c) / scale;
		trap = min(trap, d);
	}

   return vec3(d, 1.0, 1.0);
}

#endif

// Return the distance of the closest object in the scene
vec2 SceneMap( in vec3 pos ) {
	#ifdef MANDELBULB
	vec4 orbitTrap = vec4(0.0);
	//return vec2(SDF_Mandelbulb(pos, orbitTrap), 0.0);

	// WHY DOES THIS MAKE A DIFFERENCE
	float boundingSphere = SDF_Sphere(pos, 1.15); // Bound the mandelbulb in a sphere. The radius was visually chosen. 1.15 is good
	//float boundingBox = SDF_Box(pos, vec3(1.0)); // 1.1 is good

	if(boundingSphere < 0.7) {
		return vec2(SDF_Mandelbulb(pos, orbitTrap), 0.0);
	} else {
		return vec2(boundingSphere, 0.0);
	}
	#endif

	#ifdef MENGER
	float orbit;
	vec3 result = SDF_MengerSponge(pos, orbit);
	return vec2(result.x, orbit);
	#endif
}

// Marching Functions

vec3 RaymarchScene( in vec3 origin, in vec3 direction, out float numIters ) {
	vec2 textureRead = texture2D(u_previous_conemarch, f_uv).ba;
	if(textureRead.x <= 0.0) {
		numIters = 0.0;
		return vec3(0.0, -1.0, 0.0); // no intersection
	}
	float t = textureRead.y;
	
	int iters;
	for(int i = 0; i < NUM_RAYMARCH_ITERATIONS; ++i) {
		//iters = i;
		vec2 distRes = SceneMap(origin + t * direction);
		if(distRes.x < 0.004) {
			numIters = float(i);
			return vec3(t, 1.0, distRes.y); // intersection
		} else if(t > T_MAX) {
			break;
		}
		t += distRes.x;
	}
	numIters = float(iters);
	return vec3(t, -1.0, 0.0); // no intersection
}

// B-channel is unused at the moment
vec3 ConemarchScene( in vec3 origin, in vec3 direction, in float coneTanOver2, out float numIters ) {
	float t;
	if(u_pass_counter == 0) {
		t = 0.01;
	} else {
		vec2 textureRead = texture2D(u_previous_conemarch, f_uv).ba;
		if(textureRead.x <= 0.0) {
			numIters = 0.0;
			return vec3(0.0, -1.0, 0.0); // no intersection
		}
		t = textureRead.y;
	}

	int iters;
	for(int i = 0; i < NUM_CONEMARCH_ITERATIONS; ++i) {
		iters = i;
		vec2 distRes = SceneMap(origin + t * direction);
		float coneWidth = t * coneTanOver2;

		if(distRes.x < coneWidth /* || distRes.x < 0.004*/) {
			numIters = float(i);
			return vec3(t, 1.0, distRes.x); // close enough to bailout
		} else if(t > T_MAX) {
			return vec3(t, -1.0, distRes.x);
		}
		t += distRes.x; // sphere trace
	}
	numIters = float(iters);
	return vec3(t, -1.0, 0.0); // didn't intersect per se, but shouldn't mark as "don't continue at all"
}

// Shading Functions

// Compute the normal of an implicit surface using the gradient method
vec3 ComputeNormal( in vec3 pos ) {
	vec2 point = vec2(0.001, 0.0);
	float currDist = SceneMap(pos).x;
	return normalize(
			   vec3(SceneMap(pos + point.xyy).x - currDist,
					SceneMap(pos + point.yxy).x - currDist,
					SceneMap(pos + point.yyx).x - currDist));
}

// Presentation by IQ: http://www.iquilezles.org/www/material/nvscene2008/rwwtt.pdf
float ComputeAO( vec3 pos, vec3 normal ) {
	float tStep = 0.02;
	float t = 0.0;
	float ao = 1.0;
	float diff = 0.0;
	float k = 12.0;
	for(int i = 0; i < 5; ++i) {
		vec3 sample = pos + t * normal;
		float dist = SceneMap(sample).x;
		diff += pow(0.5, float(i)) * (t - dist);
		t += tStep;
	}
	ao -= clamp(k * diff, 0.0, 1.0);
	return ao;
}

float paletteHelper( in float a, in float b, in float c, in float d, in float x ) {
    return a + b * cos(6.28318 * (c * x + d));
}

vec3 cosinePalette( in float x ) {
	vec3 col;
	col.r = paletteHelper( 0.5, 0.5, 1.0, 0.0, x);
	col.g = paletteHelper( 0.5, 0.5, 1.0, 0.33, x);
	col.b = paletteHelper( 0.5, 0.5, 1.0, 0.67, x);
	return col;
}

void main() {

	if(u_pass_counter == FINAL_PASS) {
		float lineWidth = 0.001;
		if(abs(f_uv.x - 0.33) < lineWidth) {
			gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0); return;
		} else if(abs(f_uv.x - 0.67) < lineWidth) {
			gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0); return;
		}
	}

	vec2 scrPt = f_uv * 2.0 - 1.0;
	vec3 cameraPos = vec3(u_camera_view[0][3], u_camera_view[1][3], u_camera_view[2][3]); //normalize(vec3(cos(u_time * 0.5), sin(u_time * 0.125), sin(u_time * 0.5))) * 4.0 * (sin(u_time * 0.25) * 0.5 + 1.5);

	// Unpack camera vectors
	vec3 camLook = vec3(u_camera_view[0][0], u_camera_view[0][1], u_camera_view[0][2]); //refPoint - cameraPos;
	vec3 camRight = -vec3(u_camera_view[2][0], u_camera_view[2][1], u_camera_view[2][2]); //normalize(cross(camLook, vec3(0, 1, 0)));
	vec3 camUp = -vec3(u_camera_view[1][0], u_camera_view[1][1], u_camera_view[1][2]);    //-normalize(cross(camLook, camRight));

	vec3 horzVec = camRight * u_tan_fovy_over2 * u_aspect;
	vec3 vertVec = camUp * u_tan_fovy_over2;
	vec3 refPoint = cameraPos + camLook + horzVec * scrPt.x + vertVec * scrPt.y;

    vec3 rayDirection = normalize(refPoint - cameraPos);

	// Perform cone/ray marched
	vec3 result;
	float numIterations;
	
	// Cone/ray-march
	if(u_pass_counter == FINAL_PASS) {
		result = RaymarchScene(cameraPos, rayDirection, numIterations);
		//gl_FragColor = vec4(vec3(texture2D(u_previous_conemarch, f_uv).rrr), 1); return;
	} else {
		vec2 texelSize = vec2(0.5) / u_resolution;

		vec2 secondScrPt = (f_uv + texelSize) * 2.0 - 1.0;

		// Cast a ray through the "upper right corner" of the current fragment.
		vec3 secondRefPoint = vec3(0);
		secondRefPoint += horzVec * secondScrPt.x + vertVec * secondScrPt.y;
		vec3 secondRayDirection = normalize(secondRefPoint - cameraPos);

		float theta = acos(dot(rayDirection, secondRayDirection));

		// compute the half angle of the cone this ray lies within. compute tan(angle) and pass as a parameter
		result = ConemarchScene(cameraPos, rayDirection, tan(theta), numIterations);
	}

	if(result.y > 0.0) { // if we intersected or bailed out
		vec3 isectPos = cameraPos + result.x * rayDirection;
		
		if(u_pass_counter == FINAL_PASS) { // shade
			// normal computation seems to cost ~5 fps. can we do this with less samples
			vec3 color;
			//float lambert = dot(normal, LIGHT_VEC);

			vec3 normal;

			if(f_uv.x < 0.33) {
				// Ao
				normal = ComputeNormal(isectPos);
				float ao = ComputeAO(isectPos, normal);
				color = vec3(ao);
			} else if(f_uv.x < 0.67) {
				// Normal
				normal = ComputeNormal(isectPos);
				color = normal;
			} else if(f_uv.x <= 1.0) {
				// Orbit trap
				#ifdef MENGER
				float colorInput = result.z;
				colorInput = pow(abs(colorInput), 0.5);
				color = cosinePalette(colorInput);
				#else
				
				#ifdef MANDELBULB
				float colorInput = resColor.x;

				colorInput = pow(abs(resColor.x), 0.01);
				color = mix(resColor.xyz, vec3(0.2, 0.5, 0.75), colorInput);
				color = pow(color, vec3(1.999));
				color *= 2.0;

				color.r *= (0.5 * cos(u_time) + 0.5) * 4.0;
				color.g *= (0.5 * sin(u_time * 0.5 + 1.0) + 0.5) * 1.0;
				color.b *= (0.5 * sin(u_time * 0.125) + 0.5) * 1.0;
				#endif

				#endif
			}

			// Fog?
			//vec3 fogColor = vec3(0.1, 0.12, 0.2);
			//color = mix(color, fogColor, exp(-0.04 * result.x));

			gl_FragColor = vec4(color, 1.0);

		} else { // conemarch and write the necessary parameters for the next iteration
			gl_FragColor = vec4(0.0, 0.0, result.y, result.x); // write the marched t-value to the texture's alpha channel

			/*if(u_pass_counter == 3) {
				gl_FragColor = vec4(vec3(result.z), 1); // debug distances for showing stuff
			}*/
		}
	} else { // we either missed or missed in a previous iteration
		if(u_pass_counter == FINAL_PASS) { // final pass so shade the background color
			//gl_FragColor = vec4(vec3(numIterations / float(NUM_RAYMARCH_ITERATIONS)), 1.0);
			gl_FragColor = vec4(0.2, 0.3, 0.4, 1.0);
		} else { // write t-value info
			gl_FragColor = vec4(0.0, 0.0, result.y, result.x); // write the marched t-value to the texture's alpha channel
		}
	}
}
