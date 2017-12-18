#define T_MAX 25.0

varying vec2 f_uv;

uniform float u_time;
uniform vec2 u_resolution;
uniform sampler2D u_previous_conemarch;
uniform bool u_is_first_pass;
uniform bool u_is_final_pass;

/***** Geometry SDF Functions
http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
							  *****/

float SDF_Sphere( vec3 pos, float radius ) {
	return length(pos) - radius;
}

// Return the distance of the closest object in the scene
float sceneMap( vec3 pos ) {
	return SDF_Sphere( pos, 1.0 );
}

// Compute the normal of an implicit surface using the gradient method
vec3 computeNormal( vec3 pos ) {
	vec2 point = vec2(0.001, 0.0);
	vec3 normal = normalize(
			   vec3(sceneMap(pos + point.xyy) - sceneMap(pos - point.xyy),
					sceneMap(pos + point.yxy) - sceneMap(pos - point.yxy),
					sceneMap(pos + point.yyx) - sceneMap(pos - point.yyx)));
	return normal;
}

// Check for intersection with the scene for increasing t-values
vec2 RaymarchScene( vec3 origin, vec3 direction ) {
	float dist;
	float t = 0.01;
	for(int i = 0; i < 15; ++i) {
		float dist = sceneMap(origin + t * direction);
		if(dist < 0.0001) {
			return vec2(t, 1.0); // intersection
		} else if(t > T_MAX) {
			break;
		}
		t += dist;
	}
	return vec2(0.0, -1.0); // no intersection
}

vec3 CastRay( vec2 sp, vec3 origin )
{
    // Compute local camera vectors
    vec3 refPoint = vec3(0.0, 0.0, 0.0);
    vec3 camLook = normalize(refPoint - origin);
    vec3 camRight = normalize(cross(camLook, vec3(0.0, 1.0, 0.0)));
    vec3 camUp = normalize(cross(camRight, camLook));
    
    vec3 rayPoint = refPoint + sp.x * camRight + sp.y * camUp;
    return normalize(rayPoint - origin);
}

void main() {	
	vec2 screenPoint = (2.0 * gl_FragCoord.xy - u_resolution) / u_resolution.y;
    
	if(u_is_first_pass) {
		gl_FragColor = vec4(0, 0, 1, 1); return;
	} else {
		gl_FragColor = texture2D(u_previous_conemarch, gl_FragCoord.xy / u_resolution.xy); return;
	}

    // Compute ray direction
    vec3 rayOrigin = vec3(-3.5, 0, -3.5);
    vec3 rayDirection = CastRay(screenPoint, rayOrigin);
    
    vec2 result = RaymarchScene(rayOrigin, rayDirection);
	vec3 isectPos = rayOrigin + result.x * rayDirection;
	
	if(result.y > 0.0) { // we did intersect with something
		vec3 normal = computeNormal( isectPos );
		gl_FragColor = vec4(normal, 1.0);
		vec4 color = texture2D(u_previous_conemarch, gl_FragCoord.xy / u_resolution.xy);
		gl_FragColor = color * 1.1;
	} else {
		// Background color
		gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
	}
}
