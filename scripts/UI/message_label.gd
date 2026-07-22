class_name MessageLabel
extends Label

var config: FloatingTextConfig

func setup(text: String, config: FloatingTextConfig):
	self.config = config
	self.text = text

	modulate = config.color
	scale = Vector2.ONE * config.scale
	
	texture_filter = config.texture
	z_index = config.z_index
	add_theme_font_size_override("font_size", config.font_size)
	add_theme_constant_override("outline_size", config.outline_size)
	add_theme_color_override("font_outline_color", config.outline_color)

	TweenManager.animate_floating_label(self)
