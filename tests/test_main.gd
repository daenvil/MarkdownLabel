@tool
class_name Tests extends EditorScript

func _run() -> void:
	print("Testing ...")
	main()

func main() -> void:
	# Import file:
	var file := "res://tests/test_cases.json"
	var json_as_text := FileAccess.get_file_as_string(file)
	var test_cases: Array = JSON.parse_string(json_as_text)
	if not test_cases:
		return
	
	# Prepare test subject:
	var md_label := MarkdownLabel.new()
	md_label._debug_mode = false
	## Add case titles to study those cases only. Leave empty to study all cases.
	var specific_cases := []
	
	# Perform tests:
	var failed_tests := []
	var case_count := 0
	for case in test_cases:
		if not specific_cases.is_empty() and not case.title in specific_cases:
			continue
		case_count += 1
		var result = md_label._convert_markdown(case.input)
		var success = result == case.output
		if not success:
			failed_tests.append({"title":case.title,"input":case.input,"output":case.output,"result":result})
	
	# Display test results:
	if failed_tests.size() > 0:
		print_rich("[color=#ff6666]Tests: %d errors:[/color]"%failed_tests.size())
		for case in failed_tests:
			print_rich("[color=#ff6666]- %s[/color]"%case["title"])
			print_rich("[color=#ff6666]  - Input:[/color]")
			print(case["input"])
			print_rich("[color=#ff6666]  - Expected result:[/color]")
			print(case["output"])
			print_rich("[color=#ff6666]  - Result:[/color]")
			print(case["result"])
	else:
		if specific_cases.is_empty():
			print_rich("[color=#66ff66]All tests: OK[/color]")
		elif case_count>0:
			print_rich("[color=#66ff66]Specific tests: OK (%d/%d tests)[/color]" % [case_count,specific_cases.size()])
	if case_count < specific_cases.size():
		print_rich("[color=#ff6666]WARNING: not all specific cases were found.[/color]")
	md_label.queue_free()
