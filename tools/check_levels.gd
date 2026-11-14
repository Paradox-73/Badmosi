extends SceneTree
## Checks every room file: 24 x 12, one entrance, only known characters,
## and every spawn point and X reachable from the entrance.
## godot --headless --path . --script res://tools/check_levels.gd

var _done := false


func _process(_d: float) -> bool:
	if _done:
		return true
	_done = true
	var RoomS = load("res://scripts/world/room.gd")
	var bad := 0
	var d := DirAccess.open("res://levels")
	var n := 0
	for f in d.get_files():
		if not f.ends_with(".txt"):
			continue
		n += 1
		var txt := FileAccess.open("res://levels/" + f, FileAccess.READ).get_as_text()
		var errs: Array = RoomS.validate(RoomS.parse(txt))
		for e in errs:
			print("FAIL levels/%s: %s" % [f, e])
			bad += 1
	print("checked %d rooms, %d problems" % [n, bad])
	quit(1 if bad > 0 else 0)
	return true
