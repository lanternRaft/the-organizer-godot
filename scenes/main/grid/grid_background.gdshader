shader_type canvas_item;

// Grid spacing in world-space units.
uniform float grid_spacing = 40.0;

// Whether we're in dark theme (white lines) or light theme (black lines).
uniform bool theme_dark = true;

// Camera world position (top-left corner of viewport).
uniform vec2 camera_position;

// Camera zoom factor.
uniform float camera_zoom = 1.0;


void fragment() {
	// Compute world-space position for this fragment.
	vec2 viewport_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 world_pos = (UV - 0.5) * viewport_size / camera_zoom + camera_position;

	// Distance to nearest grid line in world-space.
	vec2 grid_pos = world_pos / grid_spacing;
	vec2 frac_part = fract(grid_pos);
	vec2 dist_to_line = min(frac_part, 1.0 - frac_part) * grid_spacing;

	// Analytical screen pixel size in world units.
	vec2 pixel_size = vec2(1.0 / camera_zoom);

	// Smooth-step across 1.5 screen pixels for stable anti-aliasing when panning.
	float line_x = 1.0 - smoothstep(0.0, pixel_size.x * 1.5, dist_to_line.x);
	float line_y = 1.0 - smoothstep(0.0, pixel_size.y * 1.5, dist_to_line.y);

	float grid_alpha = max(line_x, line_y);

	// Apply theme opacity.
	float opacity = grid_alpha * (theme_dark ? 0.06 : 0.07);

	// Output colour (pre-multiplied alpha for correct blending).
	//vec3 line_color = theme_dark ? vec3(1.0) : vec3(0.0);
	//COLOR = vec4(line_color * opacity, opacity);
	
	// Output colour — straight alpha, NOT pre-multiplied.
	vec3 line_color = theme_dark ? vec3(1.0) : vec3(0.0);
	COLOR = vec4(line_color, grid_alpha * (theme_dark ? 0.5 : 0.6	));
}