extends SceneTree
## Drives the hub's directory board, canteen and pause menu, and fails on any
## script error. godot --headless --path . --script res://tools/ui_smoke.gd

var step := 0
var wait := 0
var fails := 0
var main: Node


func check(cond: bool, name: String) -> void:
	if not cond:
		fails += 1
		print("FAIL ", name)


func tap(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)


func _process(_d: float) -> bool:
	if wait > 0:
		wait -= 1
		return false
	var G = root.get_node("Game")
	match step:
		0:
			main = load("res://scenes/main.tscn").instantiate()
			root.add_child(main)
			wait = 5
		1:
			G.new_run()
			G.pixels = 500
			main.change("hub", {})
			wait = 30
		2:
			check(main.screen_name == "hub", "hub opens")
			main.screen._open_board("1")
			wait = 5
		3:
			check(main.screen.busy, "board makes the hub busy")
			tap("down")
			tap("dodge")
			wait = 5
		4:
			check(not main.screen.busy, "K closes the board")
			main.screen._open_canteen()
			wait = 5
		5:
			G.attendance = 50.0
			tap("attack")
			wait = 5
		6:
			check(is_equal_approx(G.attendance, 70.0) and G.pixels == 470, "chai heals 20% for 30 px")
			tap("dodge")
			wait = 5
		7:
			main.screen.set("pausable", true)
			tap("pause")
			wait = 5
		8:
			check(paused, "Esc pauses")
			tap("down")
			tap("attack")
			wait = 5
		9:
			tap("attack")
			wait = 5
		10:
			check(G.assist_invincible, "assists page toggles Invincible")
			G.assist_invincible = false
			tap("dodge")
			wait = 3
		11:
			tap("dodge")
			wait = 5
		12:
			check(not paused, "back out of pause resumes")
			main.screen._open_board("3")
			wait = 5
		13:
			tap("attack")
			wait = 40
		14:
			check(main.screen_name == "club", "board opens a club")
			print("ui smoke: %d problems" % fails)
			quit(1 if fails > 0 else 0)
			return true
	step += 1
	return false
