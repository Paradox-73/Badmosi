extends Minigame
## GDSC: Stack Builder. A row of tech blocks slides left and right; J drops it
## on the tower. Whatever hangs over the edge is chopped off and shatters into
## pixels. Reach the top before the block runs out of width.

const BASE_Y := 196
const ROW_H := 12
const START_W := 96.0
const WORDS := ["HTML", "CSS", "JS", "GIT", "API", "SQL", "NODE", "REACT", "GO", "RUST", "CLOUD", "SHIP"]
const COLS := ["cyan", "lime", "gold", "orange", "pink", "violet", "blue", "teal"]

var need := 12
var tower: Array[Rect2] = []
var mx := 0.0
var mw := START_W
var dir := 1.0
var perfects := 0
var bot_aim := 0.0
var drop_cd := 0.0


func info() -> Dictionary:
	return {"goal": "STACK 12 ROWS TO THE TOP. STOP EACH BLOCK RIGHT OVER THE LAST ONE.",
		"keys": ["J: DROP THE BLOCK", "OVERHANG GETS CHOPPED OFF"], "time": 60.0}


func _ready() -> void:
	super._ready()
	if short_round:
		need = 4
	tower.append(Rect2(Px.W / 2.0 - START_W / 2.0, BASE_Y, START_W, ROW_H))
	mx = 40.0


func goal_text() -> String:
	return "ROWS %d/%d   WIDTH %d   PERFECT %d" % [tower.size() - 1, need, int(mw), perfects]


func _speed() -> float:
	return (70.0 + (tower.size() - 1) * 9.0) * speedup * (1.3 if short_round else 1.0) / Game.window_mult()


func tick(delta: float) -> void:
	drop_cd -= delta
	mx += dir * _speed() * delta
	if mx < 24.0:
		mx = 24.0
		dir = 1.0
	elif mx + mw > Px.W - 24.0:
		mx = Px.W - 24.0 - mw
		dir = -1.0
	var press := Input.is_action_just_pressed("attack")
	if Game.autoplay and drop_cd <= 0.0 and absf(mx - (tower[-1].position.x + bot_aim)) < _speed() * delta * 0.6 + 0.5:
		press = true
	if press and drop_cd <= 0.0:
		_drop()


func _drop() -> void:
	drop_cd = 0.15
	var top: Rect2 = tower[-1]
	var y := top.position.y - ROW_H
	var l := maxf(mx, top.position.x)
	var r := minf(mx + mw, top.end.x)
	var col: Color = Px.col(COLS[tower.size() % COLS.size()])
	if r - l <= 0.0:
		Fx.burst(Vector2(mx + mw / 2.0, y + 6), [col, Px.C.white], 40)
		Audio.play("shatter", 0.0)
		penalty(15.0, "MISSED THE TOWER!", Vector2(Px.W / 2.0, 100))
		mw = 0.0
		finish(false, float(tower.size() - 1) / need * 0.5)
		return
	if absf(mx - top.position.x) <= 2.0 * Game.window_mult():
		# Close enough: snap and call it perfect.
		l = top.position.x
		r = top.end.x
		perfects += 1
		Audio.play("perfect", 0.0)
		Fx.word("PERFECT!", Vector2(Px.W / 2.0, y - 10), Px.C.lime)
	else:
		var cut_x := mx if mx < l else r
		var cut_w := mw - (r - l)
		Fx.burst(Vector2(cut_x + cut_w / 2.0, y + 6), [col, col.darkened(0.3), Px.C.white], int(clampf(cut_w, 6, 40)))
		Audio.play("squash", 0.0)
		if cut_w >= 10.0:
			penalty(4.0, "CHOPPED!", Vector2(cut_x + cut_w / 2.0, y - 10))
	mw = floorf(r - l)
	tower.append(Rect2(floorf(l), y, mw, ROW_H))
	if tower.size() - 1 >= need:
		Audio.play("sting", 0.0)
		Fx.burst(Vector2(Px.W / 2.0, y), [Px.C.gold, Px.C.lime, Px.C.cyan], 60)
		finish(true, clampf(0.35 + 0.65 * mw / START_W + perfects * 0.03, 0.0, 1.0))
		return
	if mw < 3.0:
		penalty(10.0, "TOO THIN!", Vector2(Px.W / 2.0, 100))
		finish(false, float(tower.size() - 1) / need * 0.5)
		return
	# The next block starts from a wall, so the tower never drops itself.
	dir = 1.0 if randf() < 0.5 else -1.0
	mx = 24.0 if dir > 0.0 else Px.W - 24.0 - mw
	bot_aim = randf_range(-4.0, 4.0)


func judge() -> Array:
	return [false, float(tower.size() - 1) / need * 0.5]


func _block(r: Rect2, i: int) -> void:
	var c: Color = Px.col(COLS[i % COLS.size()])
	draw_rect(r, Px.C.dark)
	draw_rect(r.grow(-1), c)
	draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 1)), c.lightened(0.35))
	draw_rect(Rect2(r.position.x + 1, r.end.y - 2, r.size.x - 2, 1), c.darkened(0.3))
	var w: String = WORDS[i % WORDS.size()]
	if r.size.x >= Px.text_w(w) + 4:
		Px.text(self, w, Vector2(roundi(r.get_center().x - Px.text_w(w) / 2.0), r.position.y + 1), Px.C.dark, 8, false)


func _draw() -> void:
	draw_rect(PLAY, Px.C.navy)
	for y in range(28, 216, 8):
		for x in range((y / 8 % 2) * 8, Px.W, 16):
			draw_rect(Rect2(x, y, 1, 1), Px.C.slate)
	# Goal line and row ticks.
	var goal_y := BASE_Y - need * ROW_H
	for x in range(24, Px.W - 24, 6):
		draw_rect(Rect2(x, goal_y, 3, 1), Px.C.gold)
	Px.text(self, "TOP", Vector2(4, goal_y - 4), Px.C.gold)
	draw_rect(Rect2(0, BASE_Y + ROW_H, Px.W, Px.H - BASE_Y - ROW_H), Px.C.ink)
	for i in tower.size():
		_block(tower[i], i)
	if not over and mw > 0.0:
		_block(Rect2(roundi(mx), tower[-1].position.y - ROW_H, mw, ROW_H), tower.size())
	Px.text(self, "GDSC", Vector2(8, 30), Px.C.cyan)
	draw_timer()
	draw_card()
