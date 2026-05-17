shader_type canvas_item;

// 受击闪白：所有不透明像素朝纯白渐变。flash_amount=0 原色，=1 全白。
// 冒险岛风格：命中瞬间 0→1→0 在 ~50ms 内完成，给"打到了"反馈。
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a > 0.01) {
		c.rgb = mix(c.rgb, vec3(1.0), flash_amount);
	}
	COLOR = c;
}
