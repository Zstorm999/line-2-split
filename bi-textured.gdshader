shader_type spatial;
//render_mode specular_toon;

group_uniforms TextureA;
uniform sampler2D diffuse_a: source_color, repeat_enable;
uniform sampler2D normal_a: hint_normal, repeat_enable;
uniform sampler2D roughness_a: hint_roughness_gray, repeat_enable;

group_uniforms TextureB;
uniform sampler2D diffuse_b: source_color, repeat_enable;
uniform sampler2D normal_b: hint_normal, repeat_enable;
uniform sampler2D roughness_b: hint_roughness_gray, repeat_enable;

group_uniforms Light;
uniform float edge0 = 0.01;
uniform float edge1 = 0.1;

global uniform vec2 split_position;
global uniform vec2 split_direction;

global uniform sampler2D line_noise;
global uniform float noise_threshold;

global uniform float line_thickness;
global uniform float sampling_adjustment;
global uniform vec4 outer_line_color: source_color;

struct LineCmp {
	float cmp;
	float shifted_dist;
};

varying float cmp;

LineCmp compare_to_line(float signed_dist, float height, float proj_dist) {
	float time_factor = TIME * 0.01;
	vec2 smp_point = (vec2(time_factor) + vec2(height, proj_dist )) * sampling_adjustment / 8.0;

	float noise_base = (texture(line_noise, smp_point).x);
	float noise_1 = (texture(line_noise, smp_point * 2.0 ).x);
	float noise_2 = (texture(line_noise, smp_point  * 4.0).x);
	float noise_3 = (texture(line_noise, smp_point  * 8.0).x - 0.5);

	float raw_middle = (noise_base
		+ noise_1 / 2.0
		+ noise_2 / 4.0
		+ noise_3 / 8.0
		) / (1.0 + 0.5 + 0.25 + 0.125);
	float middle = pow(raw_middle * 1.2, noise_threshold) - pow(0.55 * 1.2, noise_threshold);

	float shifted_dist = signed_dist - middle;

	return LineCmp(
		step(line_thickness, abs(shifted_dist) * 2.0) * sign(shifted_dist),
		shifted_dist
	);
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec3 vertex_world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec2 vertex_line_space = vertex_world.xz - split_position;

	// we can just take advantage of the fact that the cross product returns an area
	// and interpret that as a distance
	float signed_dist = cross(vec3(vertex_line_space, 0.0), vec3(split_direction, 0.0)).z;
	float proj_dist = dot(vertex_line_space, split_direction);

	LineCmp compared = compare_to_line(signed_dist, vertex_world.y, proj_dist);

	if (abs(compared.cmp) == 0.0) {
		ALBEDO = outer_line_color.rgb;
	}
	else if (compared.cmp > 0.0) {
		ALBEDO = texture(diffuse_a, UV).rgb;
		NORMAL_MAP = texture(normal_a, UV).rgb;
		//ROUGHNESS = texture(roughness_a, UV).r;
	}
	else {
		ALBEDO = texture(diffuse_b, UV).rgb;
		NORMAL_MAP = texture(normal_b, UV).rgb;
		//ROUGHNESS = texture(roughness_b, UV).r;
	}
	cmp = compared.cmp;

}
void light() {
	if (cmp == 0.0) {
		// ignore light conditions
		DIFFUSE_LIGHT = ALBEDO;
	} else {
		float nDotL = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
		nDotL = smoothstep(edge0, edge1, nDotL);

		float attenuation = smoothstep(0.2, 0.5, ATTENUATION);

		DIFFUSE_LIGHT += vec3(nDotL) * ATTENUATION;

		/*float nDotL = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
		nDotL = smoothstep(0.39, 0.4, nDotL);

		vec3 addedCam = normalize(VIEW + LIGHT);
		float vDotL = clamp(dot(NORMAL, addedCam), 0.0, 1.0);
		vDotL = pow(vDotL, 120);
		vDotL = smoothstep(0.8, 0.81, vDotL);

		float rimLight = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		rimLight = pow(1.0 - rimLight, 5) * nDotL;
		rimLight = smoothstep(0.04, 0.05, rimLight) * 0.5;
		vec3 result = vec3(nDotL) + rimLight;

		// We will add it here
		DIFFUSE_LIGHT += result * ATTENUATION;*/
		//SPECULAR_LIGHT += vec3(vDotL) + rimLight;
	}
}
