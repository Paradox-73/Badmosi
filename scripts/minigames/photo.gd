extends Minigame
## Chhayachitra: golden hour. A viewfinder follows the cursor across the
## Thinker's Statue lawn. Shoot when the subject is in the centre box and the
## focus, a mosaic pulsing between blocky and sharp, is at its sharpest.

const FRAME := Vector2(88, 64)

var subjects := []
var shots := 0
var good := 0
var total_shots := 6
var focus_t := 0.0
var flash_t := 0.0
var last_ok := false
var photos := []   # small records of results
var spawn_t := 0.0
var need := 4


func info() -> Dictionary:
	return {"goal": "6 SHOTS. GET 4 GOOD ONES: SUBJECT IN THE CENTRE BOX, FOCUS SHARP.",
		"keys": ["MOUSE TO FRAME, CLICK TO SHOOT   OR ARROWS + J"], "time": 75.0}


func _ready() -> void:
	super._ready()
	if short_round:
		total_shots = 2
		need = 1
	cursor = Vector2(Px.W / 2.0, 120)
	cursor_speed = 120.0


func goal_text() -> String:
	return "SHOTS %d/%d   GOOD %d/%d" % [shots, total_shots, good, need]


func _focus() -> float:
	# 0 = sharp, 1 = blocky. Pulses; sharp for a short window.
	return absf(sin(focus_t * 1.7))


func tick(delta: float) -> void:
	focus_t += delta
	flash_t -= delta
	spawn_t -= delta
	if spawn_t <= 0.0 and subjects.size() < 2:
		spawn_t = randf_range(1.0, 2.0)
		var kind: String = ["pigeon", "student", "leaf"][randi() % 3]
		var left := randf() < 0.5
		var y := randf_range(70, 170)
		var sp: float = {"pigeon": 50.0, "student": 34.0, "leaf": 20.0}[kind]
		subjects.append({"kind": kind, "pos": Vector2(-10 if left else Px.W + 10, y if kind != "leaf" else 30), "vel": Vector2(sp if left else -sp, 0 if kind != "leaf" else 18), "t": 0.0})
	for s in subjects:
		s.t += delta
		s.pos += s.vel * delta
		if s.kind == "leaf":
			s.pos.x += sin(s.t * 3.0) * 30.0 * delta
	subjects = subjects.filter(func(s): return s.pos.x > -20 and s.pos.x < Px.W + 20 and s.pos.y < Px.H + 10)
	if cursor_step(delta, Rect2(FRAME / 2.0 + Vector2(0, 24), Vector2(Px.W, 192) - FRAME)):
		_shoot()


func _shoot() -> void:
	shots += 1
	flash_t = 0.15 if not Game.opts.reduce_flash else 0.05
	Audio.play("shutter", 0.0)
	var centre := Rect2(cursor - Vector2(14, 12), Vector2(28, 24))
	var subj := false
	for s in subjects:
		if centre.has_point(s.pos):
			subj = true
	var sharp := _focus() < 0.3
	last_ok = subj and sharp
	if last_ok:
		good += 1
		Audio.play("right", 0.0)
		Fx.word("SHARP!", cursor + Vector2(0, -40), Px.C.lime)
	else:
		var why := "BLURRY!" if subj else "NOTHING IN FRAME!"
		penalty(10.0, why, cursor + Vector2(0, -40))
	photos.append(last_ok)
	if shots >= total_shots:
		finish(good >= need, float(good) / total_shots)


func judge() -> Array:
	return [good >= need, float(good) / total_shots]


func _draw_subject(s: Dictionary, block: int) -> void:
	var p: Vector2 = s.pos.round()
	var c: Color
	var sz := Vector2(8, 6)
	match s.kind:
		"pigeon":
			c = Px.C.steel
			sz = Vector2(8, 6)
		"student":
			c = Px.C.orange
			sz = Vector2(8, 14)
		"leaf":
			c = Px.C.gold
			sz = Vector2(5, 4)
	if block > 1:
		var b := Vector2(block, block)
		draw_rect(Rect2((p / block).floor() * block - b, sz.snapped(b) + b), c.darkened(0.15))
	else:
		draw_rect(Rect2(p - sz / 2.0, sz), c)
		draw_rect(Rect2(p - sz / 2.0, Vector2(sz.x, 1)), c.lightened(0.3))
		if s.kind == "student":
			draw_rect(Rect2(p - Vector2(3, 9), Vector2(6, 4)), Px.C.skin2)
		if s.kind == "pigeon":
			draw_rect(Rect2(p + Vector2(3, -4), Vector2(3, 3)), Px.C.slate)


func _draw() -> void:
	# The lawn at golden hour.
	draw_rect(PLAY, Px.C.orange.darkened(0.2))
	for y in range(24, 100, 4):
		draw_rect(Rect2(0, y, Px.W, 4), Px.C.orange.lerp(Px.C.gold, (y - 24) / 80.0))
	draw_rect(Rect2(0, 100, Px.W, 116), Px.C.green.darkened(0.1))
	for x in range(0, Px.W, 8):
		draw_rect(Rect2(x, 100 + (x * 7) % 5, 2, 2), Px.C.lime)
	# Thinker's Statue.
	draw_rect(Rect2(178, 84, 28, 26), Px.C.grey.darkened(0.3))
	draw_rect(Rect2(184, 56, 14, 28), Px.C.grey)
	draw_rect(Rect2(186, 46, 10, 10), Px.C.grey.lightened(0.15))
	var block := 1 + int(_focus() * 5.0)
	for s in subjects:
		_draw_subject(s, 1)
	# Viewfinder: inside it, the focus mosaic.
	var vf := Rect2(cursor - FRAME / 2.0, FRAME)
	if block > 1:
		draw_rect(vf, Color(Px.C.white, 0.06 * block))
		for s in subjects:
			if vf.has_point(s.pos):
				_draw_subject(s, block * 2)
	for c in [vf.position, Vector2(vf.end.x - 8, vf.position.y), Vector2(vf.position.x, vf.end.y - 2), vf.end - Vector2(8, 2)]:
		draw_rect(Rect2(c, Vector2(8, 2)), Px.C.white)
	for c in [vf.position, Vector2(vf.end.x - 2, vf.position.y), Vector2(vf.position.x, vf.end.y - 8), vf.end - Vector2(2, 8)]:
		draw_rect(Rect2(c, Vector2(2, 8)), Px.C.white)
	draw_rect(Rect2(cursor - Vector2(14, 12), Vector2(28, 24)), Px.C.red if block > 2 else Px.C.lime, false, 1.0)
	Px.text(self, "FOCUS", vf.position + Vector2(2, -10), Px.C.white)
	for i in 6:
		draw_rect(Rect2(vf.position.x + 34 + i * 6, vf.position.y - 9, 5, 5), Px.C.lime if i >= block - 1 else Px.C.dark)
	if flash_t > 0.0:
		draw_rect(PLAY, Color(1, 1, 1, 0.8))
	for i in photos.size():
		var r := Rect2(8 + i * 22, 196, 18, 14)
		draw_rect(r, Px.C.white)
		draw_rect(r.grow(-2), Px.C.lime if photos[i] else Px.C.slate)
	draw_card()
