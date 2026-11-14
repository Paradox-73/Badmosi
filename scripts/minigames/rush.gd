extends Minigame
## Food Committee: 2 AM rush. Order tickets pop up; build each tray with the
## item keys and send it before the student's patience runs out.

const ITEMS := [
	{"name": "CHAI", "col": "tan"}, {"name": "PUFF", "col": "gold"}, {"name": "MAGGI", "col": "orange"},
	{"name": "DOSA", "col": "sand"}, {"name": "COFFEE", "col": "brown"},
]

var tickets := []   # {items: Array[int], patience, max}
var tray := []
var served := 0
var lost := 0
var spawn_t := 0.0
var need := 15


func info() -> Dictionary:
	return {"goal": "SERVE 15 ORDERS. BUILD THE TRAY FOR THE LEFTMOST TICKET, THEN SEND IT.",
		"keys": ["1 CHAI  2 PUFF  3 MAGGI  4 DOSA  5 COFFEE", "ENTER OR J: SEND   BACKSPACE OR K: CLEAR"], "time": 90.0}


func _ready() -> void:
	super._ready()
	if short_round:
		need = 2


func begin() -> void:
	_spawn()


func goal_text() -> String:
	return "SERVED %d/%d   LOST %d   TIME %d" % [served, need, lost, ceili(time_left)]


func _spawn() -> void:
	if tickets.size() >= 4:
		return
	var n := randi_range(1, 2 if served < 4 else 3)
	var items := []
	for i in n:
		items.append(randi() % ITEMS.size())
	items.sort()
	var pat := (16.0 - minf(served, 10) * 0.5) * Game.time_mult()
	tickets.append({"items": items, "patience": pat, "max": pat})


func _input(e: InputEvent) -> void:
	super._input(e)
	if not running or over or not (e is InputEventKey) or not e.pressed or e.echo:
		return
	var k: InputEventKey = e
	if k.physical_keycode >= KEY_1 and k.physical_keycode <= KEY_5:
		if tray.size() < 4:
			tray.append(k.physical_keycode - KEY_1)
			Audio.play("move", 0.1)
	elif k.physical_keycode in [KEY_ENTER, KEY_J, KEY_Z, KEY_SPACE]:
		_send()
	elif k.physical_keycode in [KEY_BACKSPACE, KEY_K, KEY_X]:
		tray.clear()
		Audio.play("back", 0.0)


func _send() -> void:
	if tickets.is_empty() or tray.is_empty():
		return
	var tk: Dictionary = tickets[0]
	var mine := tray.duplicate()
	mine.sort()
	if mine == tk.items:
		served += 1
		tickets.pop_front()
		Audio.play("buy", 0.0)
		Fx.word(["YUM!", "THANKS ANNA!", "PERFECT TRAY!"].pick_random(), Vector2(60, 70), Px.C.lime)
		Game.add_pixels(5)
	else:
		penalty(10.0, "WRONG TRAY!", Vector2(60, 70))
	tray.clear()


func tick(delta: float) -> void:
	spawn_t -= delta
	if spawn_t <= 0.0:
		spawn_t = (4.5 - minf(served, 10) * 0.2) * Game.time_mult()
		_spawn()
	for tk in tickets:
		tk.patience -= delta
	for tk in tickets.duplicate():
		if tk.patience <= 0.0:
			tickets.erase(tk)
			lost += 1
			penalty(10.0, "CUSTOMER LEFT!", Vector2(Px.W / 2.0, 70))
	if served >= need:
		finish(true, float(served) / (served + lost))


func judge() -> Array:
	return [served >= need, float(served) / maxf(1, served + lost)]


func _item_icon(i: int, p: Vector2) -> void:
	var c: Color = Px.col(ITEMS[i].col)
	match i:
		0:
			draw_rect(Rect2(p + Vector2(2, 3), Vector2(8, 9)), Px.C.white)
			draw_rect(Rect2(p + Vector2(3, 4), Vector2(6, 5)), c)
			draw_rect(Rect2(p + Vector2(10, 5), Vector2(2, 4)), Px.C.white)
		1:
			draw_rect(Rect2(p + Vector2(1, 5), Vector2(10, 6)), c)
			draw_rect(Rect2(p + Vector2(2, 4), Vector2(8, 1)), c.lightened(0.3))
		2:
			draw_rect(Rect2(p + Vector2(1, 6), Vector2(10, 6)), Px.C.white)
			for j in 4:
				draw_rect(Rect2(p + Vector2(2 + j * 2, 4 + (j % 2)), Vector2(1, 4)), c)
		3:
			draw_rect(Rect2(p + Vector2(0, 7), Vector2(12, 3)), c)
			draw_rect(Rect2(p + Vector2(2, 6), Vector2(8, 1)), c.darkened(0.2))
		4:
			draw_rect(Rect2(p + Vector2(3, 3), Vector2(6, 9)), Px.C.steel)
			draw_rect(Rect2(p + Vector2(4, 4), Vector2(4, 3)), c)


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.brown.darkened(0.7), 0.96))
	Px.text_c(self, "BHASKARA CANTEEN - 2:00 AM", Px.W / 2.0, 30, Px.C.gold)
	for i in tickets.size():
		var tk: Dictionary = tickets[i]
		var r := Rect2(12 + i * 92, 44, 84, 72)
		Px.panel(self, r, Px.C.sand if i == 0 else Px.C.mist, Px.C.gold if i == 0 else Px.C.slate)
		Px.text(self, "ORDER #%d" % (served + i + 1), r.position + Vector2(5, 4), Px.C.dark, 8, false)
		for j in tk.items.size():
			_item_icon(tk.items[j], r.position + Vector2(6, 16 + j * 14))
			Px.text(self, ITEMS[tk.items[j]].name, r.position + Vector2(22, 19 + j * 14), Px.C.dark, 8, false)
		var f: float = tk.patience / tk.max
		Px.bar(self, Rect2(r.position.x + 4, r.end.y - 8, r.size.x - 8, 4), f, Px.C.lime if f > 0.5 else (Px.C.gold if f > 0.25 else Px.C.red))
	# The tray.
	var tr := Rect2(Px.W / 2.0 - 80, 130, 160, 34)
	Px.panel(self, tr, Px.C.steel, Px.C.white)
	for j in tray.size():
		_item_icon(tray[j], tr.position + Vector2(10 + j * 36, 10))
	Px.text_c(self, "YOUR TRAY", Px.W / 2.0, 168, Px.C.white)
	for i in ITEMS.size():
		_item_icon(i, Vector2(48 + i * 62, 184))
		Px.text(self, "%d %s" % [i + 1, ITEMS[i].name], Vector2(42 + i * 62, 198), Px.C.mist)
	draw_timer()
	draw_card()
