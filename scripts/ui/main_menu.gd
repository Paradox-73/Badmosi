extends Node2D
## New game, Continue, Club select, Options, Credits, Quit.

var menu: MenuList
var t := 0.0
var diff_menu: MenuList


func _ready() -> void:
	Audio.play_music("title")
	Audio.prewarm()
	var items := [
		{"text": "NEW GAME", "on": _new_game},
		{"text": "CONTINUE", "on": _continue, "disabled": not Game.has_save()},
		{"text": "SPEEDRUN", "on": _speedrun},
		{"text": "HOW TO PLAY", "on": func(): Game.goto("how_to_play")},
		{"text": "CLUB SELECT", "on": func(): Game.goto("club_select")},
		{"text": "OPTIONS", "on": func(): Game.goto("options")},
		{"text": "RHYTHM CALIBRATION", "on": func(): Game.goto("calibrate")},
		{"text": "CREDITS", "on": func(): Game.goto("credits")},
	]
	if OS.get_name() != "Web":
		items.append({"text": "QUIT", "on": func(): get_tree().quit()})
	menu = MenuList.new(items, 170)
	menu.position = Vector2(Px.W / 2.0, 92)
	menu.back.connect(func(): Game.goto("title"))
	if not Game.has_save():
		menu.sel = 0
	add_child(menu)


func _new_game() -> void:
	menu.active = false
	menu.visible = false
	diff_menu = MenuList.new([
		{"text": "HD  - EASY", "on": func(): _start(0)},
		{"text": "SD  - NORMAL", "on": func(): _start(1)},
		{"text": "8-BIT - HARD", "on": func(): _start(2)},
	], 170)
	diff_menu.title = "CHOOSE YOUR RESOLUTION"
	diff_menu.sel = 1
	diff_menu.position = Vector2(Px.W / 2.0, 92)
	diff_menu.back.connect(func():
		diff_menu.queue_free()
		menu.visible = true
		menu.active = true)
	add_child(diff_menu)


func _start(d: int) -> void:
	Game.difficulty = d
	Game.new_run()
	Game.speedrun = false
	Game.goto("char_select")


## A speedrun is a normal run on SD with the timer on screen. The flashback
## and the gate scene are skipped: char select leads straight to campus.
func _speedrun() -> void:
	Game.difficulty = 1
	Game.new_run()
	Game.speedrun = true
	Game.goto("char_select")


func _continue() -> void:
	if Game.load_run():
		Game.goto("hub")


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, Px.W, Px.H), Px.C.ink)
	preload("res://scripts/ui/title.gd").draw_skyline(self, t, 200)
	Px.text_c(self, "BADMOSI", Px.W / 2.0, 24, Px.C.gold, 24)
	draw_texture(Px.flame_tex(), Vector2(108, 26))
	draw_texture(Px.flame_tex(), Vector2(260, 26))
	Px.text_c(self, "A PIXEL ADVENTURE AT IIIT-B", Px.W / 2.0, 52, Px.C.steel)
	if diff_menu and is_instance_valid(diff_menu):
		var lines := ["HD: HALF DAMAGE, WIDER WINDOWS, 3 PROXIES", "SD: AS DESIGNED", "8-BIT: HARDER, NO SPARE PROXIES"]
		Px.text_c(self, lines[diff_menu.sel], Px.W / 2.0, 150, Px.C.mist)
	Px.text_c(self, "J/ENTER: SELECT   K/ESC: BACK   ARROWS/WASD: MOVE", Px.W / 2.0, Px.H - 10, Px.C.slate)
