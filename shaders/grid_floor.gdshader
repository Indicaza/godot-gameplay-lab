// File: shaders/grid_floor.gdshader
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform vec4 base_color : source_color = vec4(0.09, 0.10, 0.12, 1.0);

uniform vec4 line_color_1m : source_color = vec4(0.22, 0.24, 0.28, 1.0);
uniform vec4 line_color_5m : source_color = vec4(0.40, 0.44, 0.50, 1.0);
uniform vec4 line_color_10m : source_color = vec4(0.92, 0.94, 0.98, 1.0);

uniform vec4 axis_x_color : source_color = vec4(0.85, 0.20, 0.20, 1.0);
uniform vec4 axis_z_color : source_color = vec4(0.20, 0.45, 0.90, 1.0);

uniform float spacing_1m : hint_range(0.1, 10.0, 0.1) = 1.0;
uniform float spacing_5m : hint_range(0.5, 50.0, 0.5) = 5.0;
uniform float spacing_10m : hint_range(1.0, 100.0, 1.0) = 10.0;

uniform float width_1m : hint_range(0.001, 0.2, 0.001) = 0.012;
uniform float width_5m : hint_range(0.001, 0.4, 0.001) = 0.03;
uniform float width_10m : hint_range(0.001, 0.6, 0.001) = 0.06;

uniform float axis_width : hint_range(0.001, 1.0, 0.001) = 0.08;

uniform bool show_axes = true;
uniform bool fade_with_distance = true;
uniform float fade_start : hint_range(0.0, 500.0, 1.0) = 60.0;
uniform float fade_end : hint_range(1.0, 1000.0, 1.0) = 140.0;

uniform float roughness_value : hint_range(0.0, 1.0, 0.01) = 0.96;
uniform float metallic_value : hint_range(0.0, 1.0, 0.01) = 0.0;

varying vec3 world_pos;
varying vec3 local_pos;

float grid_mask(float coord, float spacing, float width_world) {
	float cell = coord / spacing;
	float dist_to_center = abs(fract(cell - 0.5) - 0.5) * spacing;
	float aa = fwidth(coord) * 1.5;
	return 1.0 - smoothstep(width_world * 0.5, width_world * 0.5 + aa, dist_to_center);
}

void vertex() {
	vec4 wp = MODEL_MATRIX * vec4(VERTEX, 1.0);
	world_pos = wp.xyz;
	local_pos = VERTEX;
}

void fragment() {
	float g1x = grid_mask(world_pos.x, spacing_1m, width_1m);
	float g1z = grid_mask(world_pos.z, spacing_1m, width_1m);
	float g5x = grid_mask(world_pos.x, spacing_5m, width_5m);
	float g5z = grid_mask(world_pos.z, spacing_5m, width_5m);
	float g10x = grid_mask(world_pos.x, spacing_10m, width_10m);
	float g10z = grid_mask(world_pos.z, spacing_10m, width_10m);

	float grid_1m = max(g1x, g1z);
	float grid_5m = max(g5x, g5z);
	float grid_10m = max(g10x, g10z);

	float axis_x = 1.0 - smoothstep(axis_width * 0.5, axis_width * 0.5 + fwidth(world_pos.z) * 1.5, abs(world_pos.z));
	float axis_z = 1.0 - smoothstep(axis_width * 0.5, axis_width * 0.5 + fwidth(world_pos.x) * 1.5, abs(world_pos.x));

	vec3 color = base_color.rgb;

	color = mix(color, line_color_1m.rgb, clamp(grid_1m * 0.55, 0.0, 1.0));
	color = mix(color, line_color_5m.rgb, clamp(grid_5m * 0.85, 0.0, 1.0));
	color = mix(color, line_color_10m.rgb, clamp(grid_10m, 0.0, 1.0));

	if (show_axes) {
		color = mix(color, axis_x_color.rgb, axis_x);
		color = mix(color, axis_z_color.rgb, axis_z);
	}

	if (fade_with_distance) {
		float dist = distance(CAMERA_POSITION_WORLD, world_pos);
		float fade = 1.0 - smoothstep(fade_start, fade_end, dist);

		vec3 faded_grid =
			mix(base_color.rgb, line_color_1m.rgb, clamp(grid_1m * 0.55, 0.0, 1.0));
		faded_grid =
			mix(faded_grid, line_color_5m.rgb, clamp(grid_5m * 0.85, 0.0, 1.0));
		faded_grid =
			mix(faded_grid, line_color_10m.rgb, clamp(grid_10m, 0.0, 1.0));

		if (show_axes) {
			faded_grid = mix(faded_grid, axis_x_color.rgb, axis_x);
			faded_grid = mix(faded_grid, axis_z_color.rgb, axis_z);
		}

		color = mix(base_color.rgb, faded_grid, fade);
	}

	ALBEDO = color;
	ROUGHNESS = roughness_value;
	METALLIC = metallic_value;
}