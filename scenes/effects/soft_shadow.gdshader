shader_type canvas_item;

// 投影阴影软边：对纹理 alpha 做 9 点高斯模糊，输出纯黑 + 羽化后的半透明，
// 把复制 sprite 的硬像素边缘柔化成真正的软阴影。浓度由顶点 modulate 的 alpha 控制。
uniform float blur : hint_range(0.0, 3.0) = 1.4;

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE * blur;
	float a = texture(TEXTURE, UV).a * 4.0;
	a += texture(TEXTURE, UV + vec2(ps.x, 0.0)).a * 2.0;
	a += texture(TEXTURE, UV - vec2(ps.x, 0.0)).a * 2.0;
	a += texture(TEXTURE, UV + vec2(0.0, ps.y)).a * 2.0;
	a += texture(TEXTURE, UV - vec2(0.0, ps.y)).a * 2.0;
	a += texture(TEXTURE, UV + ps).a;
	a += texture(TEXTURE, UV - ps).a;
	a += texture(TEXTURE, UV + vec2(ps.x, -ps.y)).a;
	a += texture(TEXTURE, UV + vec2(-ps.x, ps.y)).a;
	a /= 16.0;
	COLOR = vec4(0.0, 0.0, 0.0, a * COLOR.a);
}
