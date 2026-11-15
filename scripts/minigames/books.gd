extends Minigame
## Prayas: BOOK DRIVE. Donations rain down. Slide the basket to catch books
## for the shelf; old phones and chips packets are junk and cost Attendance.
## Caught junk shatters into pixels.

const FIELD := Rect2(8, 28, 272, 168)
const SHELF := Rect2(290, 40, 86, 140)
const BOOK_COLS := ["red", "blue", "lime", "gold", "violet", "orange", "cyan", "pink"]
const BASKET_Y := 176.0

var need := 16
var shelf := []        # colours of shelved books
var items := []        # {pos, vel, kind ("book", "phone", "chips"), col}
var basket_x := 144.0
var spawn_t := 0.5


func info() -> Dictionary:
	return {"goal": "CATCH %d DONATED BOOKS FOR THE SHELF. LET THE JUNK FALL." % (4 if short_round else 16),
		"keys": ["LEFT/RIGHT: MOVE THE BASKET"], "time": 60.0}


func _ready() -> void:
	super._ready()
	if short_round:
		need = 4


func goal_text() -> String:
	return "SHELF %d/%d   JUNK CAUGHT %d" % [shelf.size(), need, mistakes]


func tick(delta: float) -> void:
	var mx := Game.move_vec().x
	if Game.autoplay:
		mx = _auto()
	basket_x = clampf(basket_x + mx * 170.0 * delta, FIELD.position.x + 14, FIELD.end.x - 14)
	spawn_t -= delta
	if spawn_t <= 0.0:
		spawn_t = randf_range(0.5, 0.9) * (0.6 if short_round else 1.0) / speedup
		var kind := "book" if randf() < 0.65 else ("phone" if randf() < 0.5 else "chips")
		var speed := lerpf(50.0, 95.0, 1.0 - time_left / time_total) * speedup / Game.time_mult()
		items.append({"pos": Vector2(randf_range(FIELD.position.x + 8, FIELD.end.x - 18), FIELD.position.y),
			"vel": speed, "kind": kind, "col": BOOK_COLS[randi() % BOOK_COLS.size()]})
	for it in items.duplicate():
		it.pos = it.pos + Vector2(0, it.vel * delta)
		var p: Vector2 = it.pos
		if p.y + 12 >= BASKET_Y and p.y < BASKET_Y + 4 and absf(p.x + 5 - basket_x) < 16:
			items.erase(it)
			_catch(it)
		elif p.y > FIELD.end.y:
			items.erase(it)
			if it.kind == "book":
				Fx.burst(Vector2(p.x + 5, FIELD.end.y - 2), [Px.col(it.col)], 6)


func _catch(it: Dictionary) -> void:
	var p: Vector2 = it.pos
	if it.kind == "book":
		shelf.append(it.col)
		Audio.play("coin", 0.0)
		Fx.word("+1 BOOK", Vector2(basket_x, BASKET_Y - 14), Px.C.lime)
		if shelf.size() >= need:
			finish(true, float(need) / (need + mistakes))
	else:
		Fx.burst(p + Vector2(5, 6), [Px.C.orange, Px.C.dark, Px.C.grey] if it.kind == "chips" else [Px.C.ink, Px.C.cyan, Px.C.grey], 30)
		penalty(5.0, "JUNK!" if it.kind == "chips" else "OLD PHONE!", Vector2(basket_x, BASKET_Y - 16))


## Autoplay chases the lowest book and steps aside from junk about to land.
func _auto() -> float:
	var goal := basket_x
	var low := -1.0
	for it in items:
		if it.kind == "book" and it.pos.y > low and it.pos.y < BASKET_Y:
			low = it.pos.y
			goal = it.pos.x + 5
	for it in items:
		if it.kind != "book" and it.pos.y > BASKET_Y - 40 and it.pos.y < BASKET_Y and absf(it.pos.x + 5 - goal) < 20:
			goal += 40.0 if goal < FIELD.get_center().x else -40.0
	return clampf((goal - basket_x) / 8.0, -1.0, 1.0)


func judge() -> Array:
	return [shelf.size() >= need, float(shelf.size()) / float(need)]


func _draw() -> void:
	draw_rect(PLAY, Px.C.sand.darkened(0.55))
	draw_rect(Rect2(0, 186, Px.W, 30), Px.C.brown)
	# The shelf fills from the bottom, 8 books a row.
	Px.panel(self, SHELF, Px.C.brown.darkened(0.3), Px.C.tan)
	Px.text_c(self, "SHELF", SHELF.get_center().x, 30, Px.C.sand)
	var per_row := 8
	var rows := int(ceil(float(need) / per_row))
	var row_h := floori((SHELF.size.y - 8) / rows)
	for r in rows:
		var by := SHELF.end.y - 4 - r * row_h
		draw_rect(Rect2(SHELF.position.x + 2, by, SHELF.size.x - 4, 2), Px.C.tan)
	for i in shelf.size():
		var r := i / per_row
		var x := SHELF.position.x + 5 + (i % per_row) * 10
		var h := 14 + (i * 7) % 6
		var by := SHELF.end.y - 4 - r * row_h
		draw_rect(Rect2(x, by - h, 8, h), Px.col(shelf[i]))
		draw_rect(Rect2(x + 1, by - h + 3, 6, 1), Px.C.white)
	for it in items:
		_draw_item(it)
	# Basket.
	var bx := roundf(basket_x)
	draw_rect(Rect2(bx - 16, BASKET_Y, 32, 12), Px.C.tan)
	for i in 4:
		draw_rect(Rect2(bx - 14 + i * 8, BASKET_Y + 2, 4, 8), Px.C.brown)
	draw_rect(Rect2(bx - 17, BASKET_Y - 1, 34, 2), Px.C.brown.darkened(0.3))
	var didi: Texture2D = Px.char_tex(Clubs.get_club("prayas").head_look, "idle")
	draw_texture_rect(didi, Rect2(Vector2(SHELF.position.x + 30, 184), didi.get_size()), false)
	draw_timer()
	draw_card()


func _draw_item(it: Dictionary) -> void:
	var p: Vector2 = it.pos.floor()
	match it.kind:
		"book":
			draw_rect(Rect2(p, Vector2(10, 12)), Px.col(it.col))
			draw_rect(Rect2(p + Vector2(1, 1), Vector2(1, 10)), Px.C.dark)
			draw_rect(Rect2(p + Vector2(3, 3), Vector2(5, 1)), Px.C.white)
			draw_rect(Rect2(p + Vector2(3, 5), Vector2(4, 1)), Px.C.white)
		"phone":
			draw_rect(Rect2(p, Vector2(8, 12)), Px.C.ink)
			draw_rect(Rect2(p + Vector2(1, 1), Vector2(6, 8)), Px.C.teal)
			draw_rect(Rect2(p + Vector2(2, 3), Vector2(4, 1)), Px.C.dark)    # a crack
			draw_rect(Rect2(p + Vector2(3, 10), Vector2(2, 1)), Px.C.grey)
		_:
			draw_rect(Rect2(p + Vector2(0, 1), Vector2(10, 10)), Px.C.orange)
			for i in 5:
				draw_rect(Rect2(p + Vector2(i * 2, 0), Vector2(1, 1)), Px.C.orange)
				draw_rect(Rect2(p + Vector2(i * 2 + 1, 11), Vector2(1, 1)), Px.C.orange)
			draw_rect(Rect2(p + Vector2(2, 4), Vector2(6, 3)), Px.C.gold)
