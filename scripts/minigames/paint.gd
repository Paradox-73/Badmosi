extends Minigame
## Vinci: paint from memory. A pixel painting shows for 3 s; repaint it on an
## empty grid with a 4-colour palette. Rounds: 8 x 8, 10 x 10, 12 x 12.

const SIZES := [8, 10, 12]
const ROUND_TIME := 22.0

var round_i := 0
var rounds := 3
var target := []       # Array of ints (palette indexes), n*n
var canvas := []
var pal := []          # 4 Colors
var n := 8
var show_t := 0.0
var round_t := 0.0
var brush := 1
var scores := []
var painting := false


func info() -> Dictionary:
	return {"goal": "MEMORISE THE PAINTING FOR 3 SECONDS, THEN PAINT IT BACK. 80% AVERAGE TO PASS.",
		"keys": ["MOUSE: CLICK/DRAG TO PAINT   1-4: COLOUR", "OR CURSOR + J   ENTER: DONE EARLY"], "time": 999.0}


func uses_timer() -> bool:
	return false


func _ready() -> void:
	super._ready()
	if short_round:
		rounds = 1
	cursor_speed = 90.0


func begin() -> void:
	_new_round()


func _new_round() -> void:
	n = SIZES[round_i] if not short_round else 6
	var ids := Clubs.ORDER.duplicate()
	ids.shuffle()
	var src := Px.char_tex(Clubs.get_club(ids[0]).head_look, "idle").get_image()
	# Shrink the sprite to n x n and keep its 4 most common colours.
	var counts := {}
	var cells := []
	for y in n:
		for x in n:
			var sx := int((x + 0.5) * src.get_width() / n)
			var sy := int((y + 0.5) * src.get_height() / n)
			var c := src.get_pixel(sx, sy)
			var key := c.to_html() if c.a > 0.5 else "bg"
			cells.append(key)
			counts[key] = counts.get(key, 0) + 1
	var keys := counts.keys()
	keys.erase("bg")
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	pal = [Px.C.white]
	for i in mini(3, keys.size()):
		pal.append(Color(keys[i]))
	while pal.size() < 4:
		pal.append(Px.C.dark)
	target = []
	for k in cells:
		if k == "bg":
			target.append(0)
		else:
			var best := 1
			var bd := 99.0
			var col := Color(k)
			for i in range(1, 4):
				var d: float = Vector3(col.r - pal[i].r, col.g - pal[i].g, col.b - pal[i].b).length()
				if d < bd:
					bd = d
					best = i
			target.append(best)
	canvas = []
	canvas.resize(n * n)
	canvas.fill(0)
	show_t = 3.0 * Game.time_mult()
	round_t = ROUND_TIME * Game.time_mult() * (0.5 if short_round else 1.0)
	brush = 1


func goal_text() -> String:
	var avg := 0.0
	for s in scores:
		avg += s
	avg = avg / maxf(1.0, scores.size())
	return "ROUND %d/%d   %s   AVERAGE %d%%" % [round_i + 1, rounds, "LOOK!" if show_t > 0.0 else "PAINT! %d" % ceili(round_t), roundi(avg * 100)]


func _grid_rect() -> Rect2:
	var cell := 120 / n
	return Rect2(Px.W / 2.0 - cell * n / 2.0 - 30, 40, cell * n, cell * n)


func tick(delta: float) -> void:
	if show_t > 0.0:
		show_t -= delta
		return
	round_t -= delta
	for k in 4:
		if Input.is_physical_key_pressed(KEY_1 + k):
			brush = k
	var pressed := cursor_step(delta)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or pressed or Input.is_action_pressed("attack"):
		_paint_at(cursor)
	if _clicked:
		_clicked = false
	for k in 4:
		if pressed and _swatch(k).has_point(cursor):
			brush = k
	if round_t <= 0.0 or Input.is_physical_key_pressed(KEY_ENTER):
		_score()


func _paint_at(p: Vector2) -> void:
	var g := _grid_rect()
	if not g.has_point(p):
		return
	var cell := g.size.x / n
	var x := int((p.x - g.position.x) / cell)
	var y := int((p.y - g.position.y) / cell)
	if canvas[y * n + x] != brush:
		canvas[y * n + x] = brush
		Audio.play("type", 0.2)


func _score() -> void:
	var same := 0
	for i in target.size():
		if target[i] == canvas[i]:
			same += 1
	var s := float(same) / target.size()
	scores.append(s)
	if s < 0.6:
		penalty(10.0, "THAT'S... ABSTRACT. %d%%" % roundi(s * 100))
	else:
		Audio.play("right", 0.0)
		Fx.word("MATCH %d%%!" % roundi(s * 100), Vector2(Px.W / 2.0, 100), Px.C.lime, 16)
	round_i += 1
	if round_i >= rounds:
		var avg := 0.0
		for v in scores:
			avg += v
		avg /= scores.size()
		finish(avg >= 0.8, avg)
	else:
		_new_round()


func _swatch(k: int) -> Rect2:
	return Rect2(Px.W - 96, 52 + k * 26, 22, 22)


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.sand.darkened(0.7), 0.96))
	if pal.is_empty():
		draw_card()
		return
	var g := _grid_rect()
	var cell := g.size.x / n
	# Easel frame.
	draw_rect(g.grow(4), Px.C.brown)
	draw_rect(g.grow(2), Px.C.dark)
	var grid: Array = target if show_t > 0.0 else canvas
	for y in n:
		for x in n:
			draw_rect(Rect2(g.position + Vector2(x, y) * cell, Vector2(cell, cell)), pal[grid[y * n + x]])
			if show_t <= 0.0:
				draw_rect(Rect2(g.position + Vector2(x, y) * cell, Vector2(cell, 1)), Color(Px.C.dark, 0.15))
				draw_rect(Rect2(g.position + Vector2(x, y) * cell, Vector2(1, cell)), Color(Px.C.dark, 0.15))
	if show_t > 0.0:
		Px.text_c(self, "MEMORISE! %d" % ceili(show_t), g.get_center().x, g.end.y + 10, Px.C.gold)
	else:
		Px.text_c(self, "PAINT IT BACK", g.get_center().x, g.end.y + 10, Px.C.white)
		Px.bar(self, Rect2(g.position.x, g.end.y + 22, g.size.x, 3), round_t / (ROUND_TIME * Game.time_mult()), Px.C.pink)
	for k in 4:
		var r := _swatch(k)
		Px.panel(self, r, pal[k], Px.C.gold if k == brush else Px.C.slate)
		Px.text(self, str(k + 1), r.position + Vector2(26, 7), Px.C.white)
	var mp := Px.char_tex(Clubs.get_club("vinci").head_look, "idle")
	draw_texture_rect(mp, Rect2(Vector2(24, 120), mp.get_size() * 2), false)
	Px.text_c(self, "MONA PIXA", 40, 164, Px.C.pink)
	if show_t <= 0.0:
		draw_cursor(Px.C.white)
	draw_card()
