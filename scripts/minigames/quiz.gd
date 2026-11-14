extends Minigame
## Quiz Society: 6 questions, 10 s each, then 4 picture questions. A picture
## starts as 4 x 4 blocks and sharpens every second; early answers score more.
## Lifelines cost pixels: 50:50 (Q) for 40 px, Ask a Senior (E) for 30 px.

const PER_Q := 10.0

var questions := []   # {q, opts, ans, pic (Texture2D or null)}
var qi := 0
var q_t := 0.0
var right := 0
var answered := -1
var answer_t := 0.0
var sel := 0
var removed := []      # option indexes removed by 50:50
var senior_says := -1
var score := 0.0


static func load_bank() -> Array:
	var out := []
	var f := FileAccess.open("res://data/quiz.txt", FileAccess.READ)
	if f == null:
		return out
	var cur := {}
	for line in f.get_as_text().split("\n"):
		var l := line.strip_edges()
		if l.begins_with("#"):
			continue
		if l.begins_with("Q: "):
			cur = {"q": l.substr(3), "opts": [], "ans": 0}
		elif l.length() > 3 and l[1] == ":" and "ABCD".find(l[0]) >= 0 and cur.has("q"):
			cur.opts.append(l.substr(3))
		elif l.begins_with("ANS: "):
			cur.ans = "ABCD".find(l.substr(5, 1))
		elif l.begins_with("TOPIC: "):
			cur.topic = l.substr(7)
			out.append(cur)
			cur = {}
	return out


func info() -> Dictionary:
	return {"goal": "ANSWER 7 OF 10. THE PICTURE ROUND SHARPENS - ANSWER EARLY FOR MORE PIXELS.",
		"keys": ["ARROWS + J, OR KEYS 1-4", "Q: 50:50 (40 PX)   E: ASK A SENIOR (30 PX)"], "time": 999.0}


func uses_timer() -> bool:
	return false


func _ready() -> void:
	super._ready()
	var bank := load_bank()
	bank.shuffle()
	var n_text := 6 if not short_round else 1
	for i in mini(n_text, bank.size()):
		questions.append(bank[i])
	var heads := Clubs.ORDER.duplicate()
	heads.shuffle()
	var n_pic := 4 if not short_round else 1
	for i in n_pic:
		var id: String = heads[i]
		var opts := [Clubs.get_club(id).head]
		var others := Clubs.ORDER.duplicate()
		others.erase(id)
		others.shuffle()
		for j in 3:
			opts.append(Clubs.get_club(others[j]).head)
		opts.shuffle()
		questions.append({"q": "PICTURE ROUND: WHICH CLUB HEAD IS THIS?", "opts": opts,
			"ans": opts.find(Clubs.get_club(id).head), "pic": Px.char_tex(Clubs.get_club(id).head_look, "idle")})


func begin() -> void:
	q_t = 0.0


func goal_text() -> String:
	return "QUESTION %d/%d   CORRECT %d/%d" % [mini(qi + 1, questions.size()), questions.size(), right, 7 if not short_round else 1]


func _per_q() -> float:
	return PER_Q * Game.time_mult() * (0.8 if short_round else 1.0)


func tick(delta: float) -> void:
	if qi >= questions.size():
		return
	if answered >= 0:
		answer_t -= delta
		if answer_t <= 0.0:
			_next()
		return
	q_t += delta
	var q: Dictionary = questions[qi]
	if Input.is_action_just_pressed("up"):
		sel = _step(sel, -2)
	if Input.is_action_just_pressed("down"):
		sel = _step(sel, 2)
	if Input.is_action_just_pressed("left"):
		sel = _step(sel, -1)
	if Input.is_action_just_pressed("right"):
		sel = _step(sel, 1)
	for k in 4:
		if Input.is_physical_key_pressed(KEY_1 + k) and not removed.has(k):
			sel = k
			_answer(k)
			return
	if Input.is_action_just_pressed("attack") and not removed.has(sel):
		_answer(sel)
		return
	if Input.is_physical_key_pressed(KEY_Q) and removed.is_empty():
		_fifty()
	if Input.is_physical_key_pressed(KEY_E) and senior_says < 0:
		_senior()
	if _clicked:
		_clicked = false
		for k in 4:
			if _opt_rect(k).has_point(cursor) and not removed.has(k):
				sel = k
				_answer(k)
				return
	if q_t >= _per_q():
		answered = 99
		answer_t = 1.0
		penalty(15.0, "TIME'S UP!")


func _step(s: int, d: int) -> int:
	var n := (s + d + 4) % 4
	Audio.play("move", 0.0)
	return n


func _fifty() -> void:
	if Game.pixels < 40:
		Fx.word("NEED 40 PX", Vector2(Px.W / 2.0, 180), Px.C.red)
		return
	Game.add_pixels(-40)
	var q: Dictionary = questions[qi]
	var wrong := [0, 1, 2, 3]
	wrong.erase(q.ans)
	wrong.shuffle()
	removed = [wrong[0], wrong[1]]
	Audio.play("buy", 0.0)


func _senior() -> void:
	if Game.pixels < 30:
		Fx.word("NEED 30 PX", Vector2(Px.W / 2.0, 180), Px.C.red)
		return
	Game.add_pixels(-30)
	var q: Dictionary = questions[qi]
	senior_says = q.ans if randf() < 0.8 else (q.ans + 1 + randi() % 3) % 4
	Audio.play("buy", 0.0)


func _answer(k: int) -> void:
	var q: Dictionary = questions[qi]
	answered = k
	answer_t = 1.0
	if k == q.ans:
		right += 1
		var bonus := 1.0
		if q.has("pic"):
			bonus = clampf(1.6 - q_t / _per_q(), 0.6, 1.6)
		score += bonus
		Audio.play("right", 0.0)
		Fx.word("CORRECT!", Vector2(Px.W / 2.0, 110), Px.C.lime)
	else:
		penalty(15.0, "BZZT! WRONG!", Vector2(Px.W / 2.0, 110))


func _next() -> void:
	qi += 1
	q_t = 0.0
	answered = -1
	removed = []
	senior_says = -1
	sel = 0
	if qi >= questions.size():
		var need := 7 if not short_round else 1
		finish(right >= need, clampf(score / questions.size(), 0.0, 1.0))


func _opt_rect(k: int) -> Rect2:
	return Rect2(24 + (k % 2) * 172, 140 + (k / 2) * 24, 164, 20)


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.ink, 0.94))
	if qi < questions.size():
		var q: Dictionary = questions[qi]
		var has_pic := q.has("pic")
		var lines := DialogueBox.wrap_text(q.q, 58 if not has_pic else 40)
		for i in lines.size():
			Px.text(self, lines[i], Vector2(24, 34 + i * 10), Px.C.white)
		if has_pic:
			_draw_pixelated(q.pic, Rect2(Px.W - 108, 32, 80, 100))
		for k in 4:
			var r := _opt_rect(k)
			var col: Color = Px.C.night
			var edge: Color = Px.C.slate
			if k == sel and answered < 0:
				edge = Px.C.gold
			if answered >= 0:
				if k == q.ans:
					col = Px.C.green
				elif k == answered:
					col = Px.C.maroon
			if removed.has(k):
				col = Px.C.ink
			Px.panel(self, r, col, edge)
			if not removed.has(k):
				Px.text(self, "%d %s" % [k + 1, q.opts[k]], r.position + Vector2(5, 6), Px.C.white)
		if senior_says >= 0:
			Px.text(self, "SENIOR: 'IT'S %d. PROBABLY.'" % (senior_says + 1), Vector2(24, 128), Px.C.cyan)
		# Per-question timer.
		Px.bar(self, Rect2(24, 192, Px.W - 48, 4), 1.0 - q_t / _per_q(), Px.C.cyan if q_t < _per_q() * 0.7 else Px.C.red)
		var buzz := Px.char_tex(Clubs.get_club("quiz").head_look, "idle")
		if not has_pic:
			draw_texture_rect(buzz, Rect2(Vector2(Px.W - 56, 70), buzz.get_size() * 2), false)
			Px.text_c(self, "BUZZER", Px.W - 40, 112, Px.C.cyan)
		Px.text(self, "Q 50:50  E SENIOR  PX %d" % Game.pixels, Vector2(24, 202), Px.C.slate)
	draw_card()


## Draws a texture as blocks that sharpen over time: 4 x 4, then 8 x 8, then full.
func _draw_pixelated(tex: Texture2D, area: Rect2) -> void:
	var im := tex.get_image()
	var w := im.get_width()
	var h := im.get_height()
	var per := _per_q()
	var stage := int(q_t / (per / 4.0))
	if answered >= 0:
		stage = 3
	var b: int = [w / 4, w / 8, 2, 1][clampi(stage, 0, 3)]
	b = maxi(1, b)
	var s := mini(int(area.size.x / w), int(area.size.y / h))
	var origin := area.position + (area.size - Vector2(w, h) * s) / 2.0
	Px.panel(self, Rect2(origin - Vector2(3, 3), Vector2(w, h) * s + Vector2(6, 6)), Px.C.night, Px.C.cyan)
	for by in range(0, h, b):
		for bx in range(0, w, b):
			var acc := Color(0, 0, 0, 0)
			var n := 0
			for y in range(by, mini(by + b, h)):
				for x in range(bx, mini(bx + b, w)):
					var c := im.get_pixel(x, y)
					if c.a > 0.5:
						acc += c
						n += 1
			if n * 2 >= b * b * 0.5 and n > 0:
				var c2 := acc / n
				c2.a = 1.0
				draw_rect(Rect2(origin + Vector2(bx, by) * s, Vector2(mini(b, w - bx), mini(b, h - by)) * s), c2)
