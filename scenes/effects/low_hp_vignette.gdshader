shader_type canvas_item;

// 低血屏幕红晕：屏幕边缘泛红、中心透明，血量越低越浓。intensity 由 HUD 按 HP 比例驱动。
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float d = distance(UV, vec2(0.5));
	float edge = smoothstep(0.32, 0.72, d);
	COLOR = vec4(0.75, 0.0, 0.0, edge * intensity);
}
