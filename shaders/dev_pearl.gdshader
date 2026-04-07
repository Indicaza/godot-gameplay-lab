shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.93, 0.94, 0.96, 1.0);
uniform vec4 edge_tint : source_color = vec4(0.82, 0.88, 0.98, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.18;
uniform float metallic : hint_range(0.0, 1.0) = 0.06;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.75;
uniform float fresnel_power : hint_range(0.1, 8.0) = 2.4;
uniform float fresnel_strength : hint_range(0.0, 1.0) = 0.18;
uniform float top_brightness : hint_range(0.0, 1.0) = 0.05;
uniform float bottom_darkness : hint_range(0.0, 1.0) = 0.03;

void fragment() {
	float up_mask = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	float view_fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), fresnel_power);

	vec3 color = base_color.rgb;
	color += vec3(top_brightness) * up_mask;
	color -= vec3(bottom_darkness) * (1.0 - up_mask);
	color = mix(color, edge_tint.rgb, view_fresnel * fresnel_strength);

	ALBEDO = color;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = specular_strength;
}