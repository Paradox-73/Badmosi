extends Minigame
## The Admin: Form 404. One field per club, each a fast 12 s round of that
## club's game. Between fields the Admin smooths the screen into a blur.
## The last field is a stamp: press Special (L) on the beat to DOWNSCALE IT.

const FIELDS := [
	["impulse", "dance"], ["symphony", "piano"], ["quiz", "quiz"], ["pioneers", "maths"],
	["eightbit", "proofread"], ["zense", "bugs"], ["food", "rush"], ["eclipse", "telescope"],
]

var fi := -1
var sub: Minigame = null
var between_t := 0.0
var stamping := false
var stamp_t := 0.0
var stamped := false
var results := []
var stamp_tries := 0


func info() -> Dictionary:
	return {"goal": "FILL IN EVERY FIELD OF FORM 404: A QUICK ROUND OF EACH CLUB'S GAME. THEN STAMP IT.",
		"keys": ["EACH FIELD SHOWS ITS OWN KEYS", "LAST FIELD: PRESS L ON THE BEAT"], "time": 999.0}


func uses_timer() -> bool:
	return false


func begin() -> void:
	_next_field()


func goal_text() -> String:
	if stamping:
		return "FINAL FIELD: STAMP IT (L) ON THE BEAT"
	return "FORM 404 - FIELD %d/%d: %s" % [fi + 1, FIELDS.size() + 1, Clubs.get_club(FIELDS[clampi(fi, 0, FIELDS.size() - 1)][0]).name]


func _next_field() -> void:
	fi += 1
	if fi >= FIELDS.size():
		stamping = true
		stamp_t = 0.0
		Audio.play_music("admin")
		if hud:
			hud.mode = "minigame"
		return
	# The Admin's blur between fields.
	between_t = 0.8
	Game.main.set_mosaic(6.0)
	var tw := create_tween()
	tw.tween_method(func(v): Game.main.set_mosaic(v), 6.0, 1.0, 0.7)
	var f: Array = FIELDS[fi]
	sub = load("res://scripts/minigames/%s.gd" % f[1]).new()
	sub.short_round = true
	sub.setup(f[0], hud)
	sub.finished.connect(_on_sub)
	add_child(sub)


func _on_sub(won: bool, acc: float) -> void:
	results.append(acc if won else acc * 0.5)
	if sub:
		sub.queue_free()
		sub = null
	Fx.word("FIELD FILLED", Vector2(Px.W / 2.0, 100), Px.C.lime)
	Audio.play("stamp", 0.0)
	_next_field.call_deferred()


func can_flip() -> bool:
	return running and not over


func _exit_tree() -> void:
	if Game.main:
		Game.main.set_mosaic(1.0)


func tick(delta: float) -> void:
	if sub and is_instance_valid(sub):
		sub.over = sub.over or over
	if not stamping:
		return
	stamp_t += delta
	if Input.is_action_just_pressed("special"):
		var bl := Audio.beat_len()
		var st := Audio.song_time()
		var err := absf(st - roundf(st / bl) * bl)
		if err < 0.12 * Game.window_mult():
			stamped = true
			Audio.play("stamp", 0.0)
			Fx.shake(3, 0.3)
			Fx.word("DOWNSCALED! APPROVED!", Vector2(Px.W / 2.0, 90), Px.C.gold, 16)
			var avg := 0.0
			for r in results:
				avg += r
			finish(true, avg / maxf(1, results.size()))
		else:
			stamp_tries += 1
			penalty(5.0, "OFF BEAT! REJECTED!", Vector2(Px.W / 2.0, 90))


func _draw() -> void:
	if stamping:
		draw_rect(PLAY, Color(Px.C.ink, 0.95))
		var r := Rect2(96, 40, 192, 140)
		draw_rect(r, Px.C.white)
		Px.text_c(self, "FORM 404", Px.W / 2.0, 46, Px.C.dark, 16, false)
		Px.text_c(self, "ROOM ALLOTMENT: PIXEL CLUB", Px.W / 2.0, 66, Px.C.dark, 8, false)
		for i in FIELDS.size():
			var d: Dictionary = Clubs.get_club(FIELDS[i][0])
			Px.text(self, "%s: [X]" % d.name, Vector2(108, 80 + i * 10), Px.C.slate, 8, false)
		var bl := Audio.beat_len()
		var ph := fmod(Audio.song_time(), bl) / bl
		var s := 32 if ph < 0.15 or ph > 0.92 else 22
		var c := Vector2(240, 150)
		draw_rect(Rect2(c - Vector2(s, s) / 2.0, Vector2(s, s)), Px.C.red if s > 22 else Px.C.maroon)
		Px.text_c(self, "L", c.x, c.y - 4, Px.C.white)
		Px.text_c(self, "STAMP ON THE BEAT!", Px.W / 2.0, 190, Px.C.gold)
	elif not running:
		draw_rect(PLAY, Color(Px.C.ink, 0.9))
	draw_card()
