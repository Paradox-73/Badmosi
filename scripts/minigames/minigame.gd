class_name Minigame
extends Node2D
## Base for every club minigame. Shows the 3-second key card, runs the timer,
## applies Attendance penalties and reports a pass or a fail.
## A subclass overrides info(), begin(), tick(delta) and draws in _draw().

signal finished(won: bool, accuracy: float)

const PLAY := Rect2(0, 24, 384, 192)

var club := ""
var hud: Hud
var card_t := 3.0
var card_wait := 0.0     # seconds the key card has been up; it waits for a press
var running := false
var over := false
var time_left := 60.0
var time_total := 60.0
var mistakes := 0
var t := 0.0
var speedup := 1.0       # Form 404 rounds run faster
var short_round := false # Form 404: a 10 s version


func setup(club_id: String, h: Hud) -> void:
	club = club_id
	hud = h


## {goal, keys (Array of Strings), time}
func info() -> Dictionary:
	return {"goal": "WIN", "keys": [], "time": 60.0}


func begin() -> void:
	pass


func tick(_delta: float) -> void:
	pass


func goal_text() -> String:
	return ""


func can_flip() -> bool:
	return running and not over


## Rhythm games read the music's beat clock, so the hurry-up tempo stays off.
func rhythm() -> bool:
	return false


func _exit_tree() -> void:
	if not get_parent() is Minigame:   # Form 404's sub-rounds leave the lock to it
		Audio.tempo_lock = false


func _ready() -> void:
	if not get_parent() is Minigame:
		Audio.tempo_lock = rhythm()
	var inf := info()
	time_total = float(inf.get("time", 60.0)) * Game.time_mult()
	if short_round:
		time_total = 12.0 * Game.time_mult()
		card_t = 1.2
	time_left = time_total
	if hud:
		hud.mode = "minigame"
		hud.goal = inf.goal


func _process(delta: float) -> void:
	queue_redraw()
	if over or get_tree().paused:
		return
	if card_t > 0.0:
		card_wait += delta
		var auto := short_round or Game.autoplay
		if auto:
			card_t -= delta
		var pressed := card_wait > 0.4 and (Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("accept"))
		if (auto and card_t <= 0.0) or pressed:
			card_t = 0.0
			running = true
			begin()
		return
	t += delta
	if uses_timer():
		time_left -= delta
		# Last 10 seconds: the music hurries up, and the last 5 tick.
		if time_left < 10.0:
			Audio.urge(1.0 - time_left / 10.0)
			if time_left < 5.0 and ceili(time_left) != ceili(time_left + delta):
				Audio.play("tick", 0.0, -6.0)
	if Game.attendance < 35.0:
		Audio.urge((35.0 - Game.attendance) / 25.0)
	tick(delta)
	if hud:
		hud.goal = goal_text() if goal_text() != "" else info().goal
	if uses_timer() and time_left <= 0.0 and not over:
		time_up()


func uses_timer() -> bool:
	return true


## Called when time runs out. By default the game decides with judge().
func time_up() -> void:
	var r := judge()
	finish(r[0], r[1])


## Returns [won, accuracy] at the end of the time.
func judge() -> Array:
	return [false, 0.0]


func penalty(pct: float, word := "", at := Vector2(-1, -1)) -> void:
	mistakes += 1
	Game.hurt(pct)
	Audio.play("wrong", 0.0)
	Fx.shake(1, 0.1)
	if word != "":
		Fx.word(word, at if at.x >= 0 else Vector2(Px.W / 2.0, 100), Px.C.red)


func finish(won: bool, acc: float) -> void:
	if over:
		return
	over = true
	running = false
	finished.emit(won, clampf(acc, 0.0, 1.0))


## Draws the shared key card. Subclasses call this at the end of _draw().
func draw_card() -> void:
	if card_t <= 0.0:
		return
	var inf := info()
	var d: Dictionary = Clubs.get_club(club)
	var r := Rect2(48, 50, 288, 128)
	draw_rect(PLAY, Color(Px.C.ink, 0.6))
	Px.panel(self, r, Px.C.night, Px.C.gold)
	Px.text_c(self, d.game_name, Px.W / 2.0, 58, Px.C.gold, 16)
	var gl := DialogueBox.wrap_text(inf.goal, 44)
	for i in gl.size():
		Px.text_c(self, gl[i], Px.W / 2.0, 82 + i * 10, Px.C.white)
	var y := 104
	for k in inf.get("keys", []):
		Px.text_c(self, k, Px.W / 2.0, y, Px.C.cyan)
		y += 10
	var fit := "HOLD F TO SAY " + Game.fit_words()
	Px.text_c(self, fit, Px.W / 2.0, 158, Px.C.pink)
	if not Game.opts.clean_text:
		var shown := Game.pad_text(fit) if Game.pad else fit
		var x0 := Px.W / 2.0 - Px.text_w(shown) / 2.0 + Px.text_w(Game.pad_text("HOLD F TO SAY F") if Game.pad else "HOLD F TO SAY F")
		var cols := [Px.C.pink, Px.C.violet, Px.C.gold, Px.C.cyan]
		for i in 6:
			for j in 3:
				draw_rect(Rect2(x0 + i * 3, 158 + j * 3, 3, 3), cols[(i + j + int(t * 8 + card_t * 8)) % 4])
	if short_round or Game.autoplay:
		Px.bar(self, Rect2(r.position.x + 8, r.end.y - 6, r.size.x - 16, 3), card_t / 3.0, Px.C.gold)
	elif card_wait > 0.4 and int(t * 2.0 + card_wait * 2.0) % 2 == 0:
		Px.text_c(self, "PRESS J TO START", Px.W / 2.0, r.end.y - 11, Px.C.white)


# ------------------------------------------------------------ shared cursor

var cursor := Vector2(192, 120)
var cursor_speed := 110.0
var _clicked := false
var _mouse_seen := false


func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		cursor = get_global_transform_with_canvas().affine_inverse() * e.position
		_mouse_seen = true
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		cursor = get_global_transform_with_canvas().affine_inverse() * e.position
		_clicked = true


## Moves the cursor with the keys and returns true on a press (click, or J).
func cursor_step(delta: float, bounds: Rect2 = PLAY) -> bool:
	var mv := Game.move_vec()
	if mv.length() > 0.1:
		cursor += mv * cursor_speed * delta
	cursor = cursor.clamp(bounds.position, bounds.end - Vector2.ONE)
	var p := _clicked or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("accept")
	_clicked = false
	return p


func draw_cursor(c: Color = Px.C.white) -> void:
	var p := cursor.floor()
	for d in [Vector2(-5, 0), Vector2(-4, 0), Vector2(-3, 0), Vector2(3, 0), Vector2(4, 0), Vector2(5, 0),
			Vector2(0, -5), Vector2(0, -4), Vector2(0, -3), Vector2(0, 3), Vector2(0, 4), Vector2(0, 5)]:
		draw_rect(Rect2(p + d + Vector2(1, 1), Vector2.ONE), Px.C.dark)
		draw_rect(Rect2(p + d, Vector2.ONE), c)
	draw_rect(Rect2(p, Vector2.ONE), Px.C.red)


## Draws the remaining time as a pixel bar at the bottom of the play area.
func draw_timer() -> void:
	if not uses_timer():
		return
	var f := time_left / time_total
	var c: Color = Px.C.cyan if f > 0.25 else (Px.C.red if int(t * 6) % 2 == 0 else Px.C.gold)
	Px.bar(self, Rect2(4, Px.H - 6, Px.W - 8, 4), f, c)
