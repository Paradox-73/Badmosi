extends Node2D
## How to play: the goal, college-life rules, controls and the F-it switch,
## on three pages. Left and right turn pages; K goes back.

var page := 0
var t := 0.0
const PAGES := 3


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if Input.is_action_just_pressed("right") or Input.is_action_just_pressed("attack"):
		if page < PAGES - 1:
			page += 1
			Audio.play("move", 0.0)
		elif Input.is_action_just_pressed("attack"):
			Game.goto("menu")
	elif Input.is_action_just_pressed("left") and page > 0:
		page -= 1
		Audio.play("move", 0.0)
	elif Input.is_action_just_pressed("dodge") or Input.is_action_just_pressed("pause"):
		Game.goto("menu")


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if page < PAGES - 1:
			page += 1
		else:
			Game.goto("menu")


func _draw() -> void:
	draw_rect(Rect2(0, 0, Px.W, Px.H), Px.C.ink)
	Px.text_c(self, "HOW TO PLAY", Px.W / 2.0, 8, Px.C.gold, 16)
	match page:
		0: _page_goal()
		1: _page_rules()
		2: _page_keys()
	for i in PAGES:
		draw_rect(Rect2(Px.W / 2.0 - 14 + i * 10, Px.H - 22, 6, 6), Px.C.gold if i == page else Px.C.slate)
	Px.text_c(self, "< > TURN PAGES   J NEXT   K BACK", Px.W / 2.0, Px.H - 12, Px.C.steel)


func _lines(lines: Array, y: int, col: Color = Px.C.white) -> void:
	for i in lines.size():
		Px.text(self, lines[i], Vector2(24, y + i * 11), col)


func _page_goal() -> void:
	var pix := Px.char_tex(Game.pix_look(), "walk1" if int(t * 3) % 2 == 0 else "idle")
	draw_texture_rect(pix, Rect2(Vector2(Px.W - 72, 44), pix.get_size() * 3), false)
	Px.text(self, "THE GOAL", Vector2(24, 34), Px.C.cyan)
	_lines([
		"THE ADMIN BRAINWASHED EVERY CLUB AND",
		"PUT CAMPUS ON LOCKDOWN. YOUR GANG,",
		"BADMOSI, IS THE LAST ONE STILL FREE.",
		"BEAT ALL 13 CLUBS AT THEIR OWN GAME TO",
		"FREE THEM. THEN THE SAC, THEN THE ADMIN.",
		"",
		"WALK INTO A BUILDING DOOR ON CAMPUS",
		"TO SEE ITS CLUBS. EACH ONE HAS A",
		"MINIGAME. WIN IT FOR A CLUB CARD.",
	], 48)
	Px.text(self, "HATE A MINIGAME? HOLD F FOR 1 SECOND.", Vector2(24, 158), Px.C.pink)
	Px.text(self, "YOU FLIP THE TABLE AND FIGHT THE CLUB.", Vector2(24, 169), Px.C.pink)


func _page_rules() -> void:
	Px.text(self, "COLLEGE LIFE IS THE RULE SET", Vector2(24, 34), Px.C.cyan)
	var rows := [
		["ATTENDANCE", "YOUR HEALTH. MISTAKES AND HITS COST IT.", Px.C.lime],
		["DETAINED", "ATTENDANCE HIT 0%. TRY THE RE-EXAM.", Px.C.red],
		["PROXY", "AN EXTRA LIFE: A FRIEND MARKS YOU PRESENT.", Px.C.gold],
		["PIXELS (PX)", "MONEY. SPEND IT AT THE CANTEEN.", Px.C.gold],
		["SEM UP", "EACH NEW CARD: MORE DAMAGE, LESS LOSS.", Px.C.cyan],
		["SPECIALS", "EVERY 3 CARDS UNLOCK A NEW ONE.", Px.C.violet],
		["HYPE", "LANDED HITS FILL IT. SPECIALS SPEND IT.", Px.C.gold],
	]
	for i in rows.size():
		var y := 52 + i * 15
		Px.text(self, rows[i][0], Vector2(24, y), rows[i][2])
		Px.text(self, rows[i][1], Vector2(112, y), Px.C.white)
	Px.text(self, "STUCK? PAUSE (ESC) HAS ASSISTS: INVINCIBLE,", Vector2(24, 164), Px.C.steel)
	Px.text(self, "DOUBLE DAMAGE AND SKIP CLUB. NO PENALTY.", Vector2(24, 175), Px.C.steel)


func _page_keys() -> void:
	Px.text(self, "CONTROLS", Vector2(24, 34), Px.C.cyan)
	var rows := [
		["MOVE", "WASD OR ARROW KEYS"],
		["ATTACK, CONFIRM", "J  (PRESS 3x FOR A COMBO)"],
		["DODGE, BACK", "K"],
		["SPECIAL", "L"],
		["SWITCH SPECIAL", "I"],
		["FLIP THE TABLE", "HOLD F FOR 1 SECOND"],
		["PAUSE", "ESC"],
		["FULLSCREEN", "F11"],
	]
	for i in rows.size():
		var y := 50 + i * 13
		Px.text(self, rows[i][0], Vector2(24, y), Px.C.gold)
		Px.text(self, rows[i][1], Vector2(140, y), Px.C.white)
	Px.text(self, "EACH MINIGAME SHOWS ITS OWN KEYS FIRST.", Vector2(24, 160), Px.C.mist)
	Px.text(self, "A GAMEPAD WORKS TOO.", Vector2(24, 171), Px.C.mist)
