#define T_MAX 11.0

varying vec2 f_uv;

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_aspect;
uniform float u_tan_fovy_over2;
uniform sampler2D u_previous_conemarch;
uniform int u_is_first_pass;
uniform int u_is_final_pass;

#define NUM_CONEMARCH_ITERATIONS 50
#define NUM_RAYMARCH_ITERATIONS 60

#define LIGHT_VEC normalize(vec3(1.0, 1.0, 1.0))

/***** Geometry SDF Functions
http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
							  *****/

float SDF_Mandlebulb( vec3 p , float exponent )
{
	vec3 w = p;
    float m = dot(w,w);
    float dz = 1.0;
    
    for(int i = 0; i < 4; ++i)
    {
        float m2 = m * m;
        float m4 = m2 * m2;
        dz = exponent * sqrt(m4 * m2 * m) * dz + 1.0;

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

        m = dot(w,w);
        if(m > 4.0)
            break;
    }

    return 0.25 * log(m) * sqrt(m) / dz;
}

float SDF_Sphere( in vec3 pos, in float radius ) {
	return length(pos) - radius;
}

float SDF_Box( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// Return the distance of the closest object in the scene
float SceneMap( in vec3 pos ) {	
	float boundingSphere = SDF_Sphere(pos, 1.15); // Bound the mandelbulb in a sphere. The radius was visually chosen. 1.15 is good
	//float boundingBox = SDF_Box(pos, vec3(1.0)); // 1.1 is good

	if(boundingSphere < 0.7) {
		return SDF_Mandlebulb(pos, 8.0);
	} else {
		return boundingSphere;
	}

	// try a less complex scene and see how many fps we get
	//return min(min(min(min(min(SDF_Sphere(pos, 0.5), SDF_Sphere(pos, 0.5)), SDF_Sphere(pos, 0.5)), SDF_Sphere(pos, 0.5)), SDF_Sphere(pos, 0.5)), SDF_Sphere(pos, 0.5));
}

// Compute the normal of an implicit surface using the gradient method
vec3 ComputeNormal( in vec3 pos ) {
	vec2 point = vec2(0.001, 0.0);
	float currDist = SceneMap(pos);
	return normalize(
			   vec3(SceneMap(pos + point.xyy) - currDist,
					SceneMap(pos + point.yxy) - currDist,
					SceneMap(pos + point.yyx) - currDist));
}

vec2 RaymarchScene( in vec3 origin, in vec3 direction, out float numIters ) {
	vec2 textureRead = texture2D(u_previous_conemarch, f_uv).ba;
	if(textureRead.x <= 0.0) {
		numIters = 0.0;
		return vec2(0.0, -1.0); // no intersection
	}
	float t = textureRead.y;
	
	int iters;
	for(int i = 0; i < NUM_RAYMARCH_ITERATIONS; ++i) {
		iters = i;
		float dist = SceneMap(origin + t * direction);
		if(dist < 0.002 * max(1.0, t * 0.6)) {
			numIters = float(i);
			return vec2(t, 1.0); // intersection
		} else if(t > T_MAX) {
			break;
		}
		t += dist;
	}
	numIters = float(iters);
	return vec2(t, -1.0); // no intersection
}

vec2 ConemarchScene( in vec3 origin, in vec3 direction, in float coneTanOver2, out float numIters ) {
	float t;
	if(bool(u_is_first_pass)) {
		t = 0.01;
	} else {
		vec2 textureRead = texture2D(u_previous_conemarch, f_uv).ba;
		if(textureRead.x <= 0.0) {
			numIters = 0.0;
			return vec2(0.0, -1.0); // no intersection
		}
		t = textureRead.y;
	}

	int iters;
	for(int i = 0; i < NUM_CONEMARCH_ITERATIONS; ++i) {
		iters = i;
		float dist = SceneMap(origin + t * direction);
		float coneWidth = t * coneTanOver2;

		if(dist < coneWidth/* / max(1.0, t * 0.05)*/) {
			numIters = float(i);
			return vec2(t, 1.0); // close enough to bailout
		} else if(t > T_MAX) {
			return vec2(t, -1.0);
		}
		t += dist; // sphere trace
	}
	numIters = float(iters);
	return vec2(t, -1.0); // didn't intersect per se, but shouldn't mark as "don't continue at all"
}

void main() {
	vec2 scrPt = f_uv * 2.0 - 1.0;
	vec3 cameraPos = normalize(vec3(cos(u_time * 0.5), 0, sin(u_time * 0.5))) * 5.0 * (sin(u_time * 0.25) * 0.5 + 1.1);
	vec3 refPoint = vec3(0);

	// Camera vectors
	vec3 camLook = refPoint - cameraPos;
	vec3 camRight = normalize(cross(camLook, vec3(0, 1, 0)));
	vec3 camUp = -normalize(cross(camLook, camRight));

	float len = length(camLook);
	vec3 horzVec = camRight * len * u_tan_fovy_over2 * u_aspect;
	vec3 vertVec = camUp * len * u_tan_fovy_over2;
	refPoint += horzVec * scrPt.x + vertVec * scrPt.y;

	camLook = normalize(camLook);
    vec3 rayDirection = normalize(refPoint - cameraPos);

	// Perform cone/ray marched
	vec2 result;
	float numIterations;
	
	// Cone/ray-march
	if(bool(u_is_final_pass)) {
		result = RaymarchScene(cameraPos, rayDirection, numIterations);
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


	//float debugVal;

	// debug
	/*if(!u_is_first_pass && !u_is_final_pass) {
	vec2 texelSize = vec2(1.0) / u_resolution;

	vec2 secondScrPt = (f_uv + texelSize) * 2.0 - 1.0;

	// Cast a ray through the "upper right corner" of the current fragment.
	vec3 secondRefPoint = horzVec * secondScrPt.x + vertVec * secondScrPt.y;
	vec3 secondRayDirection = normalize(secondRefPoint - cameraPos);

	float theta = acos(dot(rayDirection, secondRayDirection));
	gl_FragColor = vec4(vec3(theta * 100.0), 1); return;

	//gl_FragColor = vec4(vec3(numIterations / float(NUM_CONEMARCH_ITERATIONS)), 1);
	//debugVal = numIterations / float(NUM_CONEMARCH_ITERATIONS);

	} else {
		//gl_FragColor = vec4(texture2D(u_previous_conemarch, f_uv).rrr, 1);
		numIterations / float(NUM_CONEMARCH_ITERATIONS) = texture2D(u_previous_conemarch, f_uv).r;
	}*/



	if(result.y > 0.0) { // if we intersected or bailed out
		vec3 isectPos = cameraPos + result.x * rayDirection;

		if(bool(u_is_final_pass)) { // shade
			// normal computation seems to cost ~5 fps. can we do this with less samples
			vec3 normal = ComputeNormal(isectPos);
			gl_FragColor = vec4(vec3(dot(normal, LIGHT_VEC)), 1.0);
			gl_FragColor = vec4(normal, 1.0);
			//gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
		} else { // conemarch and write the necessary parameters for the next iteration
			gl_FragColor = vec4(0.0, 0.0, result.y, result.x); // write the marched t-value to the texture's alpha channel
		}
	} else { // we either missed or missed in a previous iteration
		if(bool(u_is_final_pass)) { // final pass so shade the background color
			gl_FragColor = vec4(vec3(numIterations / float(NUM_RAYMARCH_ITERATIONS)), 1.0);
			//gl_FragColor = vec4(f_uv, 0.0, 1.0);
		} else { // write t-value info
			gl_FragColor = vec4(0.0, 0.0, result.y, result.x); // write the marched t-value to the texture's alpha channel
		}
	}
}
