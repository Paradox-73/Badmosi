extends Node2D
## One scene for every club: builds the room from its text file, runs the
## club head's challenge, the minigame, the F-it switch, and the fight.

var pausable := true
var id := "impulse"
var data := {}
var room: Room
var player: Player
var head: Actor
var hud: Hud
var game: Minigame = null
var fight: Fight = null
var phase := "intro"
var fit_hold := 0.0
var start_fight := false


func setup(args: Dictionary) -> void:
	id = args.get("id", "impulse")
	start_fight = args.get("fight", false)
	data = Clubs.get_club(id)


func _ready() -> void:
	room = Room.new()
	room.load_club(id)
	add_child(room)
	player = Player.new()
	player.room = room
	player.position = room.cell_center(room.entrance) + Vector2(12, 6)
	player.input_enabled = false
	add_child(player)
	head = Actor.new()
	head.room = room
	if id == "admin":
		var b := Boss.new()
		b.fight = null
		b.setup_boss("admin")
		head = b
	else:
		head.set_look(data.head_look)
	head.position = room.cell_center(room.boss_cell) + Vector2(0, 6)
	head.facing = Vector2.LEFT
	head.sprite.flip_h = true
	add_child(head)
	hud = Hud.new()
	hud.mode = "minigame"
	hud.goal = data.name + " - " + data.full
	Game.main.ui.add_child(hud)
	if not Game.detained.is_connected(_on_detained):
		Game.detained.connect(_on_detained)
	Game.proxy_used.connect(_on_proxy)
	Audio.play_music("hub")
	if Game.attendance <= 0.0:
		Game.attendance = 100.0
	if start_fight:
		_flip_table()
	else:
		_intro()


func _exit_tree() -> void:
	Game.end_club_buffs()
	if Game.detained.is_connected(_on_detained):
		Game.detained.disconnect(_on_detained)
	if Game.proxy_used.is_connected(_on_proxy):
		Game.proxy_used.disconnect(_on_proxy)


func _intro() -> void:
	phase = "intro"
	var pages := [{"who": data.head, "text": data.challenge, "look": data.head_look}]
	if id == "admin":
		pages = [
			{"who": "THE ADMIN", "text": "AS PER CIRCULAR 404, FUN IS PENDING APPROVAL.", "tex": head.sprite.texture},
			{"who": "THE ADMIN", "text": data.challenge, "tex": head.sprite.texture},
		]
	var dlg := DialogueBox.new()
	dlg.pages = pages
	Game.main.ui.add_child(dlg)
	await dlg.finished
	_start_minigame()


func _start_minigame() -> void:
	if not is_inside_tree():
		return
	phase = "minigame"
	var path := "res://scripts/minigames/%s.gd" % data.game
	if not ResourceLoader.exists(path):
		_flip_table()
		return
	game = load(path).new()
	game.setup(id, hud)
	game.finished.connect(_on_game_finished)
	room.dim = 0.0
	add_child(game)
	if data.music != "":
		Audio.play_music(data.music)
	elif Audio.music_name != "":
		Audio.stop_music()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if phase == "minigame" and game and game.can_flip():
		if "--autofit" in OS.get_cmdline_user_args() and game.t > 1.5:
			fit_hold = 1.0
		if Game.fit_held() or fit_hold >= 1.0:
			fit_hold += delta
			hud.hold_f = fit_hold
			if fit_hold >= 1.0:
				fit_hold = 0.0
				hud.hold_f = 0.0
				_flip_table()
		else:
			fit_hold = 0.0
			hud.hold_f = 0.0


## The F-it switch: the censored words, the minigame shatters, the fight starts.
func _flip_table() -> void:
	phase = "flipping"
	Audio.stop_music()
	var ov := FitOverlay.new()
	if game:
		ov.capture = get_viewport().get_texture().get_image()
		game.queue_free()
		game = null
	Game.main.ui.add_child(ov)
	Audio.play("bleep", 0.0)
	await get_tree().create_timer(0.35).timeout
	Audio.play("crash", 0.0)
	Fx.shake(3, 0.4)
	await ov.finished
	_start_fight()


func _start_fight() -> void:
	phase = "fight"
	hud.mode = "fight"
	room.dim = 0.0
	if head and is_instance_valid(head):
		Fx.burst(head.center(), [Px.C.white], 12)
		head.queue_free()
		head = null
	fight = Fight.new()
	add_child(fight)
	fight.setup(id, room, player)
	player.input_enabled = true
	fight.won.connect(_on_fight_won)
	fight.lost.connect(_on_detained)
	Audio.play_music("fight")
	Game.main.set_palette(Clubs.palette4(id), 0.3)
	fight.start()
	_watch_boss()


func _watch_boss() -> void:
	while is_inside_tree() and fight and fight.boss == null:
		await get_tree().process_frame
	if fight:
		hud.boss = fight.boss


func _on_game_finished(won: bool, acc: float) -> void:
	if won:
		var earned := int((60 + 140 * acc) * 1.5)
		Game.add_pixels(earned)
		_victory("straight", ["CLUB BEATEN: PLAYED IT STRAIGHT", "ACCURACY %d%%" % roundi(acc * 100), "RESPECT BONUS +50%%", "+%d PX" % earned])
	else:
		phase = "failed"
		Audio.play("wrong", 0.0)
		var cp := CardPages.new()
		cp.pages = [CardPages.results_page("NOT QUITE", ["THE CLUB WAS NOT IMPRESSED.", "ACCURACY %d%%" % roundi(acc * 100)], false)]
		cp.choices = ["TRY AGAIN", "FLIP THE TABLE (FIGHT)", "BACK TO HUB"]
		Game.main.ui.add_child(cp)
		var c: int = await cp.chosen
		if game:
			game.queue_free()
			game = null
		match c:
			0: _start_minigame()
			1: _flip_table()
			2: _leave()


func _on_fight_won() -> void:
	_victory("flipped", ["CLUB BEATEN: FLIPPED THE TABLE", "PIXELS COLLECTED IN THE FIGHT"])


func _victory(how: String, lines: Array) -> void:
	phase = "won"
	Game.main.set_palette([], 0.0)
	Audio.play_music("ending")
	Audio.play("card", 0.0)
	if game:
		game.queue_free()
		game = null
	player.input_enabled = false
	# The head's parting line.
	var line: String = data.lose_straight if how == "straight" else data.lose_flip
	var pages := [{"who": data.head, "text": line, "look": data.head_look}]
	if data.hint != "":
		pages.append({"who": data.head, "text": data.hint, "look": data.head_look})
	if id == "admin":
		pages = [{"who": "THE ADMIN", "text": line, "tex": Px._cache.get("admin")}]
	if Clubs.ALLIES.has(id):
		pages.append({"who": data.head, "text": "...WAIT. WHERE AM I? THE CIRCULAR... WE WERE BRAINWASHED! THANKS, %s. %s HAS YOUR BACK NOW." % [Game.char_name(), data.name], "look": data.head_look})
	var dlg := DialogueBox.new()
	dlg.pages = pages
	Game.main.ui.add_child(dlg)
	await dlg.finished
	var sem_up := false
	if not Game.practice:
		sem_up = Game.beat_club(id, how)
	var cp := CardPages.new()
	cp.pages.append(CardPages.results_page("CLUB BEATEN!", lines, true))
	if id != "admin":
		cp.pages.append(CardPages.card_page(id))
	if Clubs.ALLIES.has(id):
		cp.pages.append(CardPages.results_page("%s IS FREE!" % data.name, ["NOW YOUR ALLY FOR THE REST OF THE RUN:", Clubs.ALLIES[id].desc], true))
	var headline: String = data.head_straight if how == "straight" else data.head_flip % Game.fit_words().trim_suffix("!")
	headline = headline.replace("FRESHER", Game.char_name())
	cp.pages.append(CardPages.headline_page(headline))
	if sem_up:
		cp.pages.append(CardPages.results_page("SEM UP!", ["NOW IN SEM %d" % Game.sem, "+10% FIGHT DAMAGE", "-5% ATTENDANCE LOSSES"], true))
	var specials := Game.unlocked_specials()
	if not Game.practice and Game.card_count() in [3, 6, 9, 12]:
		cp.pages.append(CardPages.results_page("NEW SPECIAL!", [specials[-1].name, "PRESS I TO SWITCH SPECIALS", "PRESS L IN A FIGHT TO USE IT"], true))
	Game.main.ui.add_child(cp)
	await cp.finished
	if id == "admin":
		Game.goto("ending")
	else:
		_leave()


func _leave() -> void:
	if Game.practice:
		Game.goto("club_select")
	else:
		Game.goto("hub", {"from": id})


func _on_proxy() -> void:
	Audio.play("proxy", 0.0)
	Fx.word("PROXY! A FRIEND MARKED YOU PRESENT", Vector2(Px.W / 2.0, 60), Px.C.lime)


func _on_detained() -> void:
	if phase == "detained":
		return
	phase = "detained"
	if game:
		game.over = true
	if fight:
		fight.over = true
	Audio.stop_music()
	Audio.play("detained", 0.0)
	Game.tally("detained")
	var cp := CardPages.new()
	cp.pages = [_detained_page]
	cp.choices = ["RE-EXAM", "BACK TO HUB"]
	Game.main.ui.add_child(cp)
	var c: int = await cp.chosen
	Game.attendance = 100.0
	Game.stats_changed.emit()
	if c == 0:
		Game.goto("club", {"id": id})
	else:
		Game.goto("hub" if not Game.practice else "club_select", {"from": id})


## Game over: the Admin emails your parents. The mail types itself out.
func _detained_page(ci: Node2D, t: float) -> void:
	Px.text_c(ci, "DETAINED", Px.W / 2.0, 8, Px.C.red, 16)
	var r := Rect2(40, 28, Px.W - 80, 100)
	ci.draw_rect(r, Px.C.white)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 12)), Px.C.blue)
	Px.text(ci, "NEW MAIL", r.position + Vector2(4, 2), Px.C.white, 8, false)
	var lines := [
		"FROM: admin.office@campus",
		"TO: PARENTS OF %s" % Game.char_name(),
		"SUBJECT: ATTENDANCE 0% - IMMEDIATE ACTION",
		"",
		"DEAR PARENT,",
		"YOUR WARD WAS FOUND HAVING FUN WITHOUT",
		"APPROVAL (CIRCULAR NO. 404). ATTENDANCE: 0%.",
		"KINDLY CALL YOUR WARD. TODAY.",
	]
	var shown := int(t * 60.0)
	var y := r.position.y + 15
	for l in lines:
		var s: String = l.substr(0, maxi(0, shown))
		shown -= l.length() + 4
		Px.text(ci, s, Vector2(r.position.x + 6, y), Px.C.ink, 8, false)
		y += 10
	if t > 2.5:
		Px.text_c(ci, "MAIL SENT. YOUR PHONE IS RINGING: MUMMY (14 MISSED CALLS)", Px.W / 2.0, 134, Px.C.gold)


## Pause menu assist.
func skip_club() -> void:
	if phase in ["won", "detained"]:
		return
	if game:
		game.over = true
	if fight:
		fight.over = true
	_victory("straight", ["CLUB SKIPPED (ASSIST)"])


# ------------------------------------------------------------ F-it overlay

class FitOverlay extends Node2D:
	signal finished
	var capture: Image
	var blocks := []
	var t := 0.0

	func _ready() -> void:
		z_index = 70
		if capture:
			var b := 6
			for y in range(Px.TOP, Px.H, b):
				for x in range(0, Px.W, b):
					var c := capture.get_pixel(mini(x + 2, capture.get_width() - 1), mini(y + 2, capture.get_height() - 1))
					var v := Vector2(randf_range(-60, 60), randf_range(-140, -20))
					blocks.append([Vector2(x, y), v, c, randf_range(0, 0.3)])

	func _process(delta: float) -> void:
		t += delta
		if t > 0.35:
			for bl in blocks:
				if t - 0.35 > bl[3]:
					bl[1].y += 420.0 * delta
					bl[0] += bl[1] * delta
		if t > 1.4:
			finished.emit()
			queue_free()
		queue_redraw()

	func _draw() -> void:
		for bl in blocks:
			draw_rect(Rect2(bl[0].round(), Vector2(6, 6)), bl[2])
		var words := Game.fit_words()
		var s := 32 if t > 0.1 else 16
		var band := clampf(t / 0.1, 0.0, 1.0)
		draw_rect(Rect2(0, 100 - 30 * band, Px.W, 60 * band), Color(Px.C.ink, 0.9))
		draw_rect(Rect2(0, 100 - 30 * band, Px.W, 1), Px.C.red)
		draw_rect(Rect2(0, 100 + 30 * band - 1, Px.W, 1), Px.C.red)
		var w := Px.text_w(words, s)
		var x := Px.W / 2.0 - w / 2.0
		var y := 76.0 + (2 if int(t * 30) % 2 == 0 and t < 0.6 else 0)
		Px.text(self, words, Vector2(x, y), Px.C.white, s)
		if not Game.opts.clean_text:
			CardPages.censor(self, Vector2(x + Px.text_w("F", s), y + 2), 3, t, s)
		Px.text_c(self, Game.char_name() + " FLIPS THE TABLE!", Px.W / 2.0, 114, Px.C.gold)
