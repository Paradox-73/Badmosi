extends SceneTree
## Rule tests: Attendance penalties, Proxies, SEM UP, specials, the 404
## expression check, the room parser and the piano's note columns.
## godot --headless --path . --script res://tools/run_tests.gd

var _done := false
var fails := 0
var passes := 0


func check(cond: bool, name: String) -> void:
	if cond:
		passes += 1
	else:
		fails += 1
		print("FAIL ", name)


func _process(_d: float) -> bool:
	if _done:
		return true
	_done = true
	var G = root.get_node("Game")
	G.slot = 0  # autosaves go to a file no player slot uses
	# Attendance and difficulty, with a character that has no guard perk.
	G.character = "betala"
	G.difficulty = 1
	G.new_run()
	G.hurt(10.0)
	check(is_equal_approx(G.attendance, 90.0), "SD: 10% mistake costs 10%")
	G.difficulty = 0
	G.attendance = 100.0
	G.hurt(10.0)
	check(is_equal_approx(G.attendance, 95.0), "HD halves penalties")
	G.difficulty = 2
	G.attendance = 100.0
	G.hurt(10.0)
	check(is_equal_approx(G.attendance, 85.0), "8-BIT multiplies penalties by 1.5")
	G.difficulty = 1
	G.assist_invincible = true
	G.attendance = 100.0
	G.hurt(50.0)
	check(is_equal_approx(G.attendance, 100.0), "invincible assist blocks losses")
	G.assist_invincible = false
	# Character perks.
	G.character = "tyagi"
	G.attendance = 100.0
	G.hurt(10.0)
	check(is_equal_approx(G.attendance, 93.0), "Tyagi's guard perk cuts a 10% loss to 7%")
	G.character = "dhulli"
	G.pixels = 0
	G.add_pixels(100)
	G.add_pixels(-30)
	check(G.pixels == 100, "Dhulli earns 30% more pixels, spending is not scaled")
	G.add_buff("power")
	var hit: float = G.player_dmg_mult()
	G.end_club_buffs()
	check(not G.has_buff("power") and G.player_dmg_mult() < hit, "a food buff lasts one club")
	for cid in Roster.ORDER:
		var lines: Array = Roster.perk_lines(cid)
		var has_bad: bool = lines.any(func(l): return not l[1]) or Roster.get_char(cid).has("quirk")
		check(lines.any(func(l): return l[1]) and has_bad, cid + " has a buff and a nerf or quirk")
	G.character = "sodhi"
	check(G.unlocked_specials()[0].id == "cartwheel", "Sodhi starts with the cartwheel")
	G.character = "nirbhay"
	check(G.unlocked_specials()[0].id == "blackhole", "Nirbhay starts with the black hole")
	G.character = "sachan"
	G.rage_t = 0.0
	G.dhairya = 100.0
	for i in 12:
		G.attendance = 100.0
		G.hurt(10.0)
	check(G.rage_t > 0.0, "enough hits empty Sachan's patience into rage")
	G.rage_t = 0.0
	G.character = "betala"
	# Freed clubs as allies.
	G.new_run()
	G.pixels = 100
	check(G.fine(30) == 30, "a fine costs full price before DebSoc is freed")
	G.cards["debsoc"] = "straight"
	check(G.fine(30) == 15 and G.pixels == 55, "freed DebSoc halves fines")
	G.cards["vinci"] = "straight"
	G.attendance = 100.0
	G.hurt(10.0)
	check(is_equal_approx(G.attendance, 91.0), "freed Vinci cuts losses by 10%")
	var p0: int = G.proxies
	G.beat_club("parvaaz", "straight")
	check(G.proxies == p0 + 1, "freeing Parvaaz gives a Proxy")
	G.new_run()
	# Proxies.
	G.new_run()
	G.proxies = 1
	G.attendance = 5.0
	G.hurt(10.0)
	check(is_equal_approx(G.attendance, 50.0) and G.proxies == 0, "a Proxy revives at 50%")
	var detained := [false]
	G.detained.connect(func(): detained[0] = true)
	G.attendance = 5.0
	G.hurt(10.0)
	check(detained[0], "no Proxy left means DETAINED")
	# SEM UP and specials.
	G.new_run()
	check(G.unlocked_specials().size() == 1, "only Downscale at the start")
	for id in ["impulse", "symphony", "quiz"]:
		G.beat_club(id, "straight")
	check(G.sem == 4, "each new club is a SEM UP")
	check(G.unlocked_specials().size() == 2, "3 cards unlock Spin Move")
	G.beat_club("impulse", "flipped")
	check(G.sem == 4, "beating a club again is not a SEM UP")
	check(G.flipped_count() == 1 and G.straight_count() == 2, "the ending counts straight and flipped")
	G.attendance = 100.0
	G.hurt(10.0)
	check(G.attendance > 90.0, "SEM UP cuts Attendance losses")
	# The 404 puzzle.
	var M = load("res://scripts/minigames/maths.gd")
	check(M.check_expr("4*100+3+1", [100, 25, 4, 3, 2, 1]) == "", "4*100+3+1 makes 404")
	check(M.check_expr("4*100+4", [100, 25, 4, 3, 2, 1]) != "", "a number can't be used twice")
	check(M.check_expr("404", [100, 25, 4, 3, 2, 1]) != "", "404 itself is not one of the numbers")
	check(M.check_expr("50*8+4", [50, 8, 4, 2, 6, 10]) == "", "50*8+4 makes 404")
	check(M.check_expr("75*5+7*3+9-1", [75, 5, 9, 7, 3, 1]) == "", "puzzle 3 is solvable")
	check(M.check_expr("25*16+4", [25, 16, 4, 10, 2, 6]) == "", "puzzle 4 is solvable")
	# Room parser.
	var RoomS = load("res://scripts/world/room.gd")
	var good: Array[String] = RoomS.parse(FileAccess.open("res://levels/impulse.txt", FileAccess.READ).get_as_text())
	check(RoomS.validate(good).is_empty(), "impulse room is valid")
	var broken: Array[String] = good.duplicate()
	broken[5] = broken[5].replace("@", "#")
	check(not RoomS.validate(broken).is_empty(), "a room without an entrance is rejected")
	# Piano columns rise with pitch.
	var P = load("res://scripts/minigames/piano.gd")
	check(P.col_for(60) < P.col_for(62) and P.col_for(62) < P.col_for(64) and P.col_for(64) < P.col_for(67), "piano columns follow pitch")
	# Save slots: slot 2 saves and loads on its own. The player's own slot files are put back after.
	var kept := {}
	for n in [1, 2]:
		kept[n] = FileAccess.get_file_as_string(G.slot_path(n)) if FileAccess.file_exists(G.slot_path(n)) else null
	G.delete_slot(2)
	G.new_run()
	G.practice = false
	G.slot = 1
	G.pixels = 11
	G.save_run()
	G.slot = 2
	G.pixels = 222
	G.sem = 4
	G.save_run()
	G.new_run()
	check(G.load_run(2) and G.pixels == 222 and G.sem == 4 and G.slot == 2, "slot 2 loads its own run")
	check(int(G.slot_data(1).get("pixels", -1)) == 11, "saving slot 2 leaves slot 1 alone")
	G.delete_slot(2)
	check(not G.slot_used(2) and not G.load_run(2), "a deleted slot is empty")
	for n in kept:
		if kept[n] == null:
			G.delete_slot(n)
		else:
			FileAccess.open(G.slot_path(n), FileAccess.WRITE).store_string(kept[n])
	G.slot = 0
	print("%d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)
	return true
