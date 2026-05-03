shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

uniform sampler2D grass_texture : source_color, hint_default_white;
uniform sampler2D lines_texture : source_color, hint_default_transparent;
uniform float grass_scale : hint_range(1.0, 50.0) = 20.0;
// Number of alternating mowing stripes across pitch length
uniform float stripe_count : hint_range(0.0, 30.0) = 14.0;

void fragment() {
	// Tiled grass base
	vec4 grass = texture(grass_texture, UV * grass_scale);

	// Alternating mowing stripes (±6% brightness, perpendicular to pitch length)
	float stripe = mod(floor(UV.x * stripe_count), 2.0);
	grass.rgb *= mix(0.88, 1.0, stripe);

	// White line overlay from SubViewport (alpha-blended)
	vec4 lines = texture(lines_texture, UV);
	ALBEDO = mix(grass.rgb, vec3(1.0), lines.r * lines.a);
	ROUGHNESS = 0.95;
	METALLIC = 0.0;
}
