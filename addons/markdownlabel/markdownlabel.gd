@tool
class_name MarkdownLabel
extends RichTextLabel
## A control for displaying Markdown-style text.
## 
## A custom node that extends [RichTextLabel] to use Markdown instead of BBCode.
## [br][br]
## [b][u]Usage:[/u][/b]
## Simply add a MarkdownLabel to the scene and write its [member markdown_text] field in Markdown format.
## [br][br]
## On its [RichTextLabel] properties: [member RichTextLabel.bbcode_enabled] property must be enabled. Do not touch the [member RichTextLabel.text] property, since it's used by MarkdownLabel to properly format its text. You can use the rest of its properties as normal.
## [br][br]
## You can still use BBCode tags that don't have a Markdown equivalent, such as `[u]underlined text[/u]`, allowing you to have the full functionality of RichTextLabel with the simplicity and readibility of Markdown.
## [br][br]
## Check out the full guide in the Github repo readme file (linked below). If encountering any unreported bug or unexpected bahaviour, please ensure that your Markdown is written as clean as possible, following best practices.
## 
## @tutorial(Github repository): https://github.com/daenvil/MarkdownLabel

const _ESCAPE_PLACEHOLDER := ";$\uFFFD:%s$;"
const _ESCAPEABLE_CHARACTERS := "\\*_~`[]()\"<>#-+.!"
const _ESCAPEABLE_CHARACTERS_REGEX := "[\\\\\\*\\_\\~`\\[\\]\\(\\)\\\"\\<\\>#\\-\\+\\.\\!]"

# Public:
## The text to be displayed in Markdown format.
@export_multiline var markdown_text: String : set = _set_markdown_text

@export_group("Header formats")
## Formatting options for level-1 headers
@export var h1 := H1Format.new() : set = _set_h1_format
## Formatting options for level-2 headers
@export var h2 := H2Format.new() : set = _set_h2_format
## Formatting options for level-3 headers
@export var h3 := H3Format.new() : set = _set_h3_format
## Formatting options for level-4 headers
@export var h4 := H4Format.new() : set = _set_h4_format
## Formatting options for level-5 headers
@export var h5 := H5Format.new() : set = _set_h5_format
## Formatting options for level-6 headers
@export var h6 := H6Format.new() : set = _set_h6_format

# Private:
var _converted_text: String
var _indent_level: int
var _escaped_characters_map := {}
var _within_table := false
var _table_row := -1
var _line_break := true
var _debug_mode := false

# Built-in methods:
func _init(markdown_text: String = "") -> void:
	bbcode_enabled = true
	self.markdown_text = markdown_text
	
func _ready() -> void:
	h1.connect("_updated",_update)
	h1.connect("changed",_update)
	h2.connect("_updated",_update)
	h2.connect("changed",_update)
	h3.connect("_updated",_update)
	h3.connect("changed",_update)
	h4.connect("_updated",_update)
	h4.connect("changed",_update)
	h5.connect("_updated",_update)
	h5.connect("changed",_update)
	h6.connect("_updated",_update)
	h6.connect("changed",_update)
	if Engine.is_editor_hint():
		bbcode_enabled = true
	#else:
		#pass

# Should hide properties in the editor, not working for some reason:
#func _validate_property(property: Dictionary):
#	print(property.name)
#	if property.name in ["bbcode_enabled", "text"]:
#		property.usage = PROPERTY_USAGE_NO_EDITOR

# Public methods:
## Reads the specified file and displays it as markdown.
func display_file(file_path: String):
	markdown_text = FileAccess.get_file_as_string(file_path)

#Private methods:
func _update() -> void:
	text = _convert_markdown(markdown_text)
	queue_redraw()

func _set_markdown_text(new_text: String):
	markdown_text = new_text
	_update()

func _set_h1_format(new_format: H1Format):
	h1 = new_format
	_update()

func _set_h2_format(new_format: H2Format):
	h2 = new_format
	_update()

func _set_h3_format(new_format: H3Format):
	h3 = new_format
	_update()

func _set_h4_format(new_format: H4Format):
	h4 = new_format
	_update()

func _set_h5_format(new_format: H5Format):
	h5 = new_format
	_update()

func _set_h6_format(new_format: H6Format):
	h6 = new_format
	_update()

func _convert_markdown(source_text = "") -> String:
	if not bbcode_enabled:
		push_warning("WARNING: MarkdownLabel node will not format Markdown syntax if it doesn't have 'bbcode_enabled=true'")
		return source_text
	_converted_text = ""
	var regex = RegEx.new()
	
	var lines = source_text.split("\n")
	_indent_level = -1
	var indent_spaces := []
	var indent_types := []
	var iline := 0
	var within_backtick_block := false
	var within_tilde_block := false
	var within_code_block := false
	var current_code_block_char_count: int
	_within_table = false
	_table_row = -1
	_line_break = true
	
	for line in lines:
		line = line.trim_suffix("\r")
		_debug("Parsing line: '%s'"%line)
		within_code_block = within_tilde_block or within_backtick_block
		if iline > 0 and _line_break:
			_converted_text += "\n"
			_line_break = true
		iline+=1
		if not within_tilde_block and _denotes_fenced_code_block(line,"`"):
			if within_backtick_block:
				if line.strip_edges().length() >= current_code_block_char_count:
					_converted_text = _converted_text.trim_suffix("\n")
					_converted_text += "[/code]"
					within_backtick_block = false
					_debug("... closing backtick block")
					continue
			else:
				_converted_text += "[code]"
				within_backtick_block = true
				current_code_block_char_count = line.strip_edges().length()
				_debug("... opening backtick block")
				continue
		elif not within_backtick_block and _denotes_fenced_code_block(line,"~"):
			if within_tilde_block:
				if line.strip_edges().length() >= current_code_block_char_count:
					_converted_text = _converted_text.trim_suffix("\n")
					_converted_text += "[/code]"
					within_tilde_block = false
					_debug("... closing tilde block")
					continue
			else:
				_converted_text += "[code]"
				within_tilde_block = true
				current_code_block_char_count = line.strip_edges().length()
				_debug("... opening tilde block")
				continue
		if within_code_block: #ignore any formatting inside code block
			_converted_text += _escape_bbcode(line)
			continue
		
		var _processed_line = line
		
		# Escape characters:
		regex.compile("\\\\"+_ESCAPEABLE_CHARACTERS_REGEX)
		while true:
			var result := regex.search(_processed_line)
			if not result:
				break
			var _start := result.get_start()
			var _escaped_char := result.get_string()[1]
			if not _escaped_char in _escaped_characters_map:
				_escaped_characters_map[_escaped_char] = _escaped_characters_map.size()
			_processed_line = _processed_line.erase(_start,2).insert(_start,_ESCAPE_PLACEHOLDER % _escaped_characters_map[_escaped_char])
		
		# Tables:
		_processed_line = _process_table_syntax(_processed_line)
		
		# Lists:
		_processed_line = _process_list_syntax(_processed_line,indent_spaces,indent_types)
		
		# In-line code
		regex.compile("(`+)(.+?)\\1")
		while true:
			var result = regex.search(_processed_line)
			if result:
				var _start = result.get_start()
				var _end = result.get_end()
				var unescaped_content := _reset_escaped_chars(result.get_string(2),true)
				unescaped_content = _escape_bbcode(unescaped_content)
				unescaped_content = _escape_chars(unescaped_content)
				_processed_line = _processed_line.erase(_start,_end-_start).insert(_start,"[code]%s[/code]"%unescaped_content)
				_debug("... in-line code: "+unescaped_content)
			else:
				break
		
		# Images
		var img_pattern := "\\!\\[(.*?)\\]\\((.*?)\\)"
		while true:
			regex.compile(img_pattern)
			var result = regex.search(_processed_line)
			var found_proper_match := false
			if result:
				var _start = result.get_start()
				var _end = result.get_end()
				regex.compile("\\[(.*?)\\]")
				var texts = regex.search_all(result.get_string())
				for _text in texts:
					if result.get_string()[_text.get_end()] != "(":
						continue
					found_proper_match = true
					# Check if link has a title:
					regex.compile("\\\"(.*?)\\\"")
					var title_result = regex.search(result.get_string(2))
					var title: String
					var url := result.get_string(2)
					if title_result:
						title = title_result.get_string(1)
						url = url.rstrip(" ").trim_suffix(title_result.get_string()).rstrip(" ")
					url = _escape_chars(url)
					_processed_line = _processed_line.erase(_start,_end-_start).insert(_start,"[img]%s[/img]" % url)
					if title_result and title:
						_processed_line = _processed_line.insert(_start+12+url.length()+_text.get_string(1).length(),"[/hint]").insert(_start,"[hint=%s]"%title)
					_debug("... hyperlink: "+result.get_string())
					break
			if not found_proper_match:
				break
		
		# Links
		var link_pattern := "\\[(.*?)\\]\\((.*?)\\)"
		while true:
			regex.compile(link_pattern)
			var result = regex.search(_processed_line)
			var found_proper_match := false
			if result:
				var _start = result.get_start()
				var _end = result.get_end()
				regex.compile("\\[(.*?)\\]")
				var texts = regex.search_all(result.get_string())
				for _text in texts:
					if result.get_string()[_text.get_end()] != "(":
						continue
					found_proper_match = true
					# Check if link has a title:
					regex.compile("\\\"(.*?)\\\"")
					var title_result = regex.search(result.get_string(2))
					var title: String
					var url := result.get_string(2)
					if title_result:
						title = title_result.get_string(1)
						url = url.rstrip(" ").trim_suffix(title_result.get_string()).rstrip(" ")
					url = _escape_chars(url)
					_processed_line = _processed_line.erase(_start+_text.get_start(),_end-_start-_text.get_start()).insert(_start+_text.get_start(),"[url=%s]%s[/url]" % [url,_text.get_string(1)])
					if title_result and title:
						_processed_line = _processed_line.insert(_start+_text.get_start()+12+url.length()+_text.get_string(1).length(),"[/hint]").insert(_start+_text.get_start(),"[hint=%s]"%title)
					_debug("... hyperlink: "+result.get_string())
					break
			if not found_proper_match:
				break
			
		while true:
			regex.compile("\\<(.*?)\\>")
			var result = regex.search(_processed_line)
			if result:
				var _start = result.get_start()
				var _end = result.get_end()
				var url = result.get_string(1)
				regex.compile("^\\s*?([^\\s]+\\@[^\\s]+\\.[^\\s]+)\\s*?$")
				var mail = regex.search(result.get_string(1))
				if mail:
					url = mail.get_string(1)
				url = _escape_chars(url)
				if mail:
					_processed_line = _processed_line.erase(_start,_end-_start).insert(_start,"[url=mailto:%s]%s[/url]"%[url,url])
					_debug("... mail link: "+result.get_string())
				else:
					_processed_line = _processed_line.erase(_start,_end-_start).insert(_start,"[url]%s[/url]"%url)
					_debug("... explicit link: "+result.get_string())
				
			else:
				break
		
		# Bold text
		regex.compile("(\\*\\*|\\_\\_)(.+?)\\1")
		while true:
			var result = regex.search(_processed_line)
			if not result:
				break
			var _start = result.get_start()
			var _end = result.get_end()
			_processed_line = _processed_line.erase(_start,2).insert(_start,"[b]")
			_processed_line = _processed_line.erase(_end-1,2).insert(_end-1,"[/b]")
			_debug("... bold text: "+result.get_string(2))
		
		# Italic text
		while true:
			regex.compile("(\\*|_)(.+?)\\1")
			var result = regex.search(_processed_line)
			if not result:
				break
			var _start = result.get_start()
			var _end = result.get_end()
			# Sanitize nested bold+italics (Godot-specific, b and i tags must not be intertwined):
			var result_string := result.get_string(2)
			var open_b := false
			var close_b := false
			if result_string.begins_with("[b]") and result_string.find("[/b]")==-1:
				open_b = true
			elif result_string.ends_with("[/b]") and result_string.find("[b]")==-1:
				close_b = true
			if open_b:
				_processed_line = _processed_line.erase(_start,4).insert(_start,"[b][i]")
				_processed_line = _processed_line.erase(_end-2,1).insert(_end-2,"[/i]")
			elif close_b:
				_processed_line = _processed_line.erase(_start,1).insert(_start,"[i]")
				_processed_line = _processed_line.erase(_end-3,5).insert(_end-3,"[/i][/b]")
			else:
				_processed_line = _processed_line.erase(_start,1).insert(_start,"[i]")
				_processed_line = _processed_line.erase(_end+1,1).insert(_end+1,"[/i]")
				
			_debug("... italic text: "+result.get_string(2))
		
		# Strike-through text
		regex.compile("(\\~\\~)(.+?)\\1")
		while true:
			var result = regex.search(_processed_line)
			if result:
				#_debug(result.get_string())
				var _start = result.get_start()
				_processed_line = _processed_line.erase(_start,2).insert(_start,"[s]")
				var _end = result.get_end()
				_processed_line = _processed_line.erase(_end-1,2).insert(_end-1,"[/s]")
				_debug("... strike-through text: "+result.get_string(2))
			else:
				break
		
		# Headers
		regex.compile("^#+\\s*[^\\s].*")
		while true:
			var result = regex.search(_processed_line)
			if result:
				var n := 0
				for _char in result.get_string():
					if _char!="#" or n==6:
						break
					n+=1
				var n_spaces := 0
				for _char in result.get_string().substr(n):
					if _char!=" ":
						break
					n_spaces+=1
				var header_format: Resource = _get_header_format(n)
				var n_digits := str(header_format.font_size).length()
				var _start := result.get_start()
				var opening_tags := _get_header_tags(header_format)
				_processed_line = _processed_line.erase(_start,n+n_spaces).insert(_start,opening_tags)
				var _end := result.get_end()
				_processed_line = _processed_line.insert(_end-(n+n_spaces)+opening_tags.length(),_get_header_tags(header_format,true))
				_debug("... header level %d"%n)
			else:
				break
		
		# Re-insert escaped characters:
		_processed_line = _reset_escaped_chars(_processed_line)
		
		_converted_text += _processed_line
	# end for line loop
	# Close any remaining open list:
	_debug("... end of text, closing all opened lists")
	for i in range(_indent_level,-1,-1):
		_converted_text += "[/%s]"%indent_types[i]
	# Close any remaining open tables:
	_debug("... end of text, closing all opened tables")
	if _within_table:
		_converted_text += "\n[/table]"
	
	_debug("** ORIGINAL:")
	_debug(source_text)
	_debug(_converted_text)
	return _converted_text


func _process_list_syntax(line: String, indent_spaces: Array, indent_types: Array) -> String:
	var processed_line := ""
	if line.length() == 0 and _indent_level >= 0:
		for i in range(_indent_level,-1,-1):
			_converted_text += "[/%s]" % indent_types[_indent_level]
			_indent_level-=1
			indent_spaces.pop_back()
			indent_types.pop_back()
		_converted_text += "\n"
		_debug("... empty line, closing all list tags")
		return ""
	if _indent_level == -1:
		if line.length() > 2 and line[0] in "-*+" and line[1]==" ":
			_indent_level = 0
			indent_spaces.append(0)
			indent_types.append("ul")
			_converted_text += "[ul]"
			processed_line = line.substr(2)
			_debug("... opening unordered list at level 0")
		elif line.length() > 3 and line[0] == "1" and line[1]=="." and line[2]==" ":
			_indent_level = 0
			indent_spaces.append(0)
			indent_types.append("ol")
			_converted_text += "[ol]"
			processed_line = line.substr(3)
			_debug("... opening ordered list at level 0")
		else:
			processed_line = line
		return processed_line
	var n_s := 0
	for _char in line:
		if _char == " " or _char == "\t":
			n_s += 1
			continue
		elif _char in "-*+":
			if line.length() > n_s+2 and line[n_s+1] == " ":
				if n_s == indent_spaces[_indent_level]:
					processed_line = line.substr(n_s+2)
					_debug("... adding list element at level %d"%_indent_level)
					break
				elif n_s > indent_spaces[_indent_level]:
					_indent_level += 1
					indent_spaces.append(n_s)
					indent_types.append("ul")
					_converted_text += "[ul]"
					processed_line = line.substr(n_s+2)
					_debug("... opening list at level %d and adding element"%_indent_level)
					break
				else:
					for i in range(_indent_level,-1,-1):
						if n_s < indent_spaces[i]:
							_converted_text += "[/%s]"%indent_types[_indent_level]
							_indent_level -= 1
							indent_spaces.pop_back()
							indent_types.pop_back()
						else:
							break
					_converted_text += "\n"
					processed_line = line.substr(n_s+2)
					_debug("...closing lists down to level %d and adding element"%_indent_level)
					break
		elif _char in "123456789":
			if line.length() > n_s+3 and line[n_s+1] == "." and line[n_s+2] == " ":
				if n_s == indent_spaces[_indent_level]:
					processed_line = line.substr(n_s+3)
					_debug("... adding list element at level %d"%_indent_level)
					break
				elif n_s > indent_spaces[_indent_level]:
					_indent_level += 1
					indent_spaces.append(n_s)
					indent_types.append("ol")
					_converted_text += "[ol]"
					processed_line = line.substr(n_s+3)
					_debug("... opening list at level %d and adding element"%_indent_level)
					break
				else:
					for i in range(_indent_level,-1,-1):
						if n_s < indent_spaces[i]:
							_converted_text += "[/%s]"%indent_types[_indent_level]
							_indent_level -= 1
							indent_spaces.pop_back()
							indent_types.pop_back()
						else:
							break
					_converted_text += "\n"
					processed_line = line.substr(n_s+3)
					_debug("...closing lists down to level %d and adding element"%_indent_level)
					break
	#end for _char loop
	if processed_line.is_empty():
		for i in range(_indent_level,-1,-1):
			_converted_text += "[/%s]"%indent_types[i]
			_indent_level -= 1
			indent_spaces.pop_back()
			indent_types.pop_back()
		_converted_text += "\n"
		processed_line = line
		_debug("... regular line, closing all opened lists")
	return processed_line

func _escape_bbcode(source: String) -> String:
	return source.replacen("[",_ESCAPE_PLACEHOLDER).replacen("]","[rb]").replacen(_ESCAPE_PLACEHOLDER,"[lb]")

func _escape_chars(_text: String) -> String:
	var escaped_text = _text
	for _char in _ESCAPEABLE_CHARACTERS:
		if not _char in _escaped_characters_map:
			_escaped_characters_map[_char] = _escaped_characters_map.size()
		escaped_text = escaped_text.replacen(_char,_ESCAPE_PLACEHOLDER % _escaped_characters_map[_char])
	return escaped_text

func _reset_escaped_chars(_text: String,code:=false) -> String:
	var unescaped_text := _text
	for _char in _ESCAPEABLE_CHARACTERS:
		if not _char in _escaped_characters_map:
			continue
		unescaped_text = unescaped_text.replacen(_ESCAPE_PLACEHOLDER%_escaped_characters_map[_char],"\\"+_char if code else _char)
	return unescaped_text

func _debug(string: String):
	if not _debug_mode:
		return
	print(string)

func _denotes_fenced_code_block(line: String, character: String) -> bool:
	var stripped_line := line.strip_edges()
	var count := stripped_line.count(character)
	if count >= 3 and count==stripped_line.length():
		return true
	else:
		return false

func _process_table_syntax(line: String) -> String:
	if line.count("|") < 2:
		if _within_table:
			_debug ("... end of table")
			_within_table = false
			return "\n[/table]\n"+line
		else:
			return line
	_debug("... table row: "+line)
	_table_row += 1
	var split_line := line.trim_prefix("|").trim_suffix("|").split("|")
	var processed_line := ""
	if not _within_table:
		processed_line += "[table=%d]\n" % split_line.size()
		_within_table = true
	elif _table_row == 1:
		# Handle delimiter row
		var is_delimiter := true
		for cell in split_line:
			var stripped_cell := cell.strip_edges()
			if stripped_cell.count("-")+stripped_cell.count(":") != stripped_cell.length():
				is_delimiter = false
				break
		if is_delimiter:
			_line_break = false
			return ""
	for cell in split_line:
		processed_line += "[cell]%s[/cell]" % cell.strip_edges()
	return processed_line

func _get_header_format(level: int) -> Resource:
	match level:
		1:
			return h1
		2:
			return h2
		3:
			return h3
		4:
			return h4
		5:
			return h5
		6:
			return h6
	push_warning("Invalid header level: "+str(level))
	return null

func _get_header_tags(header_format: Resource, closing := false) -> String:
	if not header_format:
		return ""
	var tags: String = ""
	if closing:
		if header_format.is_underlined:
			tags += "[/u]"
		if header_format.is_italic:
			tags += "[/i]"
		if header_format.is_bold:
			tags += "[/b]"
		if header_format.font_size:
			tags += "[/font_size]"
	else:
		if header_format.font_size:
			tags += "[font_size=%d]" % int(header_format.font_size * self.get_theme_font_size("normal_font_size"))
		if header_format.is_bold:
			tags += "[b]"
		if header_format.is_italic:
			tags += "[i]"
		if header_format.is_underlined:
			tags += "[u]"
	return tags
