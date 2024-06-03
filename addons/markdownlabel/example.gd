extends Control


func _ready() -> void:
	$MarkdownLabel.display_file("res://addons/markdownlabel/README.md")
	$MarkdownLabel.task_checkbox_clicked.connect(
		func(id: int, line: int, checked: bool, text: String) -> void:
			print("%s task #%d on line %d: %s" % ["Checked" if checked else "Unchecked", id, line, text])
	)
