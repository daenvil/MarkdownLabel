class_name H2Format
extends Resource

## Relative font size of this header level (will be multiplied by [code]normal_font_size[/code])
@export var font_size: float = 1.714 : set = _set_font_size
## Whether this header level is drawn as bold or not
@export var is_bold := false : set = _set_is_bold
## Whether this header level is drawn as italics or not
@export var is_italic := false : set = _set_is_italic
## Whether this header level is underlined or not
@export var is_underlined := false : set = _set_is_underlined
## Override font color
@export var font_color: Color = Color.WHITE : set = _set_font_color

signal _updated

func _init() -> void:
	resource_local_to_scene = true

func _set_font_size(new_font_size: float) -> void:
	font_size = new_font_size
	_updated.emit()

func _set_font_color(new_font_color: Color) -> void:
	font_color = new_font_color
	_updated.emit()

func _set_is_bold(new_is_bold: bool) -> void:
	is_bold = new_is_bold
	_updated.emit()

func _set_is_italic(new_is_italic: bool) -> void:
	is_italic = new_is_italic
	_updated.emit()

func _set_is_underlined(new_is_underlined: bool) -> void:
	is_underlined = new_is_underlined
	_updated.emit()
