extends SceneTree
## Drives the hub's directory board, food stops, guards and pause menu, and fails on any
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


func close_dialogues() -> void:
	for c in main.ui.get_children():
		if c.has_method("_end"):
			c._end()


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
			G.slot = 0  # autosaves go to a file no player slot uses
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
			tap("cancel")
			wait = 5
		4:
			check(not main.screen.busy, "K closes the board")
			main.screen._open_shop("$")
			wait = 5
		5:
			G.attendance = 50.0
			tap("accept")
			wait = 5
		6:
			check(is_equal_approx(G.attendance, 70.0) and G.pixels == 470, "chai heals 20% for 30 px")
			tap("cancel")
			wait = 5
		7:
			main.screen.set("pausable", true)
			tap("pause")
			wait = 5
		8:
			check(paused, "Esc pauses")
			tap("down")   # CONTROLS
			tap("down")   # ASSISTS
			tap("accept")
			wait = 5
		9:
			tap("accept")
			wait = 5
		10:
			check(G.assist_invincible, "assists page toggles Invincible")
			G.assist_invincible = false
			tap("cancel")
			wait = 3
		11:
			tap("cancel")
			wait = 5
		12:
			check(not paused, "back out of pause resumes")
			main.screen._open_shop("c")
			wait = 5
		13:
			tap("accept")
			wait = 5
		14:
			check(G.has_buff("speed") and G.pixels == 410, "cold coffee gives the speed buff for 60 px")
			tap("cancel")
			wait = 5
		15:
			main.screen._open_shop("P")
			wait = 5
		16:
			tap("accept")
			wait = 5
		17:
			check(G.truffles_t > 0.0 and G.pixels == 260, "a Truffles order on the phone costs 150 px and starts the timer")
			tap("cancel")
			G.truffles_t = 0.0
			G.attendance = 40.0
			main.screen.player.position = main.screen._stand(Vector2i(25, 16))  # away from the gate the rider starts at
			wait = 5
		18:
			check(main.screen.rider != null, "the rider sets off when the timer runs out")
			main.screen.rider.position = main.screen.player.position
			wait = 5
		19:
			check(is_equal_approx(G.attendance, 100.0) and G.has_buff("power") and G.tallies.get("truffles", 0) == 1 and G.truffles_t < 0.0, "the rider delivers a full heal and the power buff")
			G.end_club_buffs()
			close_dialogues()
			wait = 5
		20:
			var hub = main.screen
			check(hub.guards.size() == 3, "3 guards on SD")
			check(hub.guards.all(func(g): return hub.room.at(g.cell) in "jp"), "guards stay on the paths")
			G.pixels = 100
			hub.safe_t = 0.0
			hub.guards[0].stop_t = 0.0
			hub.guards[0].position = hub.player.position
			wait = 5
		21:
			var gd = main.screen.guards[0]
			check(G.pixels == 70 and G.tallies.get("fines", 0) == 30 and G.tallies.get("caught", 0) == 1 and gd.stop_t > 2.9, "a guard fines 30 px and stands still")
			close_dialogues()
			check(main.screen.player.position == main.screen._gate_pos(), "a caught player goes back to the gate")
			wait = 5
		22:
			var hub2 = main.screen
			G.tallies.erase("laps")
			for pc in hub2.POSTS + [hub2.POSTS[0]]:
				hub2.player.position = hub2._stand(pc)
				hub2._walk(0.0)
			check(int(G.tallies.get("laps", 0)) == 1, "all 16 track posts and back to post 1 make a lap")
			var cat = hub2.cats[0]
			cat.pet_cd = 0.0
			cat.rest_t = 5.0
			cat.position = hub2.player.position
			wait = 3
		23:
			check(int(G.tallies.get("cats", 0)) == 1, "walking into a cat pets it")
			close_dialogues()
			main.screen._open_board("3")
			wait = 5
		24:
			tap("accept")
			wait = 40
		25:
			check(main.screen_name == "club", "board opens a club")
			print("ui smoke: %d problems" % fails)
			quit(1 if fails > 0 else 0)
			return true
	step += 1
	return false
