extends SceneTree
## Loads every script under res://scripts and reports any that fail to compile.
## godot --headless --path . --script res://tools/check_scripts.gd


var _done := false


func _process(_d: float) -> bool:
	if _done:
		return true
	_done = true
	var bad := 0
	var files := _walk("res://scripts")
	for f in files:
		var s: Script = load(f)
		if s == null or not s.can_instantiate():
			print("FAIL ", f)
			bad += 1
	print("checked %d scripts, %d failed" % [files.size(), bad])
	quit(1 if bad > 0 else 0)
	return true


func _walk(dir: String) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		out.append_array(_walk(dir + "/" + sub))
	return out
