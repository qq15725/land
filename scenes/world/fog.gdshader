shader_type canvas_item;

// 视野迷雾遮罩。全屏 ColorRect 用此 shader：把每个屏幕像素映射到世界坐标，
// 再映射到迷雾网格纹理采样三态，输出黑色 + 对应不透明度。
// fog_tex 的 r 通道直接存"目标 alpha"：未探索=1.0(全黑) / 已探索≈0.55(半暗) / 可见=0.0(透明)。

uniform sampler2D fog_tex : filter_linear;
uniform vec2 grid_world_origin;   // 网格左上角的世界坐标 (_origin * CELL)
uniform vec2 grid_world_size;     // 网格世界尺寸 (_w*CELL, _h*CELL)
uniform vec4 cam_world_rect;      // 相机可视世界矩形 (x, y, w, h)

void fragment() {
	// 屏幕 UV(0..1) → 世界坐标
	vec2 world = cam_world_rect.xy + UV * cam_world_rect.zw;
	// 世界 → 网格纹理 UV(0..1)
	vec2 g = (world - grid_world_origin) / grid_world_size;
	float a = 1.0; // 网格外一律全黑（未探索）
	if (g.x >= 0.0 && g.x <= 1.0 && g.y >= 0.0 && g.y <= 1.0) {
		// 十字模糊软化视野/格子边缘
		vec2 texel = 1.0 / vec2(textureSize(fog_tex, 0));
		a = texture(fog_tex, g).r * 0.4
			+ texture(fog_tex, g + vec2(texel.x, 0.0)).r * 0.15
			+ texture(fog_tex, g - vec2(texel.x, 0.0)).r * 0.15
			+ texture(fog_tex, g + vec2(0.0, texel.y)).r * 0.15
			+ texture(fog_tex, g - vec2(0.0, texel.y)).r * 0.15;
	}
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
