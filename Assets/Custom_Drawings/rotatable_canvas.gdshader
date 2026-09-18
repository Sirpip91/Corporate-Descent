shader_type spatial;
render_mode cull_back;

uniform sampler2D albedo_texture : source_color;
uniform float rotation_degrees : hint_range(-180.0, 180.0) = 0.0;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.9;

void fragment() {
	float rad = radians(rotation_degrees);
	vec2 centered_uv = UV - vec2(0.5);
	vec2 rotated_uv = vec2(
		centered_uv.x * cos(rad) - centered_uv.y * sin(rad),
		centered_uv.x * sin(rad) + centered_uv.y * cos(rad)
	) + vec2(0.5);
	ALBEDO = texture(albedo_texture, rotated_uv).rgb;
	ROUGHNESS = roughness_value;
}
