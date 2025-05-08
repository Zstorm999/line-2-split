shader_type spatial;
//render_mode wireframe;

const float NOISE_TEXTURE_SIZE = 512.0;

uniform float line_thickness;
uniform float sampling_adjustment;
uniform vec3 outer_line_color: source_color;
uniform vec3 inner_line_color: source_color;
uniform float inner_size;

uniform sampler2D line_noise;
uniform float noise_threshold;

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

struct LineCmp {
	float cmp;
	float shifted_dist;
};

LineCmp compare_to_line(float signed_dist, float height) {

	float smp = sampling_adjustment / 8.0;

	float noise_base = (texture(line_noise, vec2(height * smp )).x);
	float noise_1 = (texture(line_noise, vec2(height * smp * 2.0 )).x);
	float noise_2 = (texture(line_noise, vec2(height * smp * 4.0 )).x);
	float noise_3 = (texture(line_noise, vec2( height * smp  * 8.0  )).x - 0.5);

	float raw_middle = (noise_base
		+ noise_1 / 2.0
		+ noise_2 / 4.0
		+ noise_3 / 8.0
		) / 2.0;
	float middle = pow(raw_middle * 1.2, noise_threshold) - 0.5;

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

	LineCmp compared = compare_to_line(signed_dist, vertex_world.y);

	if (abs(compared.cmp) == 0.0) {
		float interop = smoothstep(0.001, 0.001 + inner_size, abs(compared.shifted_dist));
		ALBEDO = outer_line_color * interop + inner_line_color * (1.0 - interop);
	}
	else if (compared.cmp > 0.0) {
		ALBEDO = texture(diffuse_a, UV).rgb;
		NORMAL_MAP = texture(normal_a, UV).rgb;
		ROUGHNESS = texture(roughness_a, UV).r;
	}
	else {
		ALBEDO = texture(diffuse_b, UV).rgb;
			NORMAL_MAP = texture(normal_b, UV).rgb;
			ROUGHNESS = texture(roughness_b, UV).r;
		}

}

void light() {
	float nDotL = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	nDotL = smoothstep(edge0, edge1, nDotL);
	DIFFUSE_LIGHT += vec3(nDotL);
}
