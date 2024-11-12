@tool
class_name H4Format
extends Resource

## Relative font size of this header level (will be multiplied by [code]normal_font_size[/code])
@export var font_size: float = 1.142 : set = _set_font_size
## Whether this header level is drawn as bold or not
@export var is_bold := false : set = _set_is_bold
## Whether this header level is drawn as italics or not
@export var is_italic := false : set = _set_is_italic
## Whether this header level is underlined or not
@export var is_underlined := false : set = _set_is_underlined
## When enabled, you can override the color of this header level with a custom color. If disabled, uses the same color as the rest of the text.
@export var override_font_color: bool = false : set = _set_override_font_color
## Custom font color to apply to this header level. Ignored if [code]override_font_color[/code] is disabled.
@export var font_color: Color = Color.WHITE : set = _set_font_color

func _init() -> void:
	resource_local_to_scene = true

func _set_font_size(new_font_size: float) -> void:
	font_size = new_font_size
	emit_changed()

func _set_override_font_color(enabled: bool) -> void:
	override_font_color = enabled
	emit_changed()

func _set_font_color(new_font_color: Color) -> void:
	font_color = new_font_color
	emit_changed()

func _set_is_bold(new_is_bold: bool) -> void:
	is_bold = new_is_bold
	emit_changed()

func _set_is_italic(new_is_italic: bool) -> void:
	is_italic = new_is_italic
	emit_changed()

func _set_is_underlined(new_is_underlined: bool) -> void:
	is_underlined = new_is_underlined
	emit_changed()
