extends "res://scripts/minigames/walk_game.gd"
## Aikyam: green campus. Saplings dry out over time. Walk to one and press J
## to water it. A sapling that dries out crumbles into pixels and costs
## Attendance. Keep at least all but one alive until the timer ends.

const REACH := 16.0

var saps := []   # {pos, water, rate, dead}
var bot_stuck := 0.0


func info() -> Dictionary:
	return {"goal": "KEEP THE SAPLINGS ALIVE UNTIL TIME RUNS OUT. LOSE AT MOST ONE.",
		"keys": ["MOVE: WASD OR ARROWS", "J: WATER THE SAPLING NEXT TO YOU"], "time": 60.0}


func _ready() -> void:
	super._ready()
	var n := 2 if short_round else 6
	var cells := room.floor_cells().filter(func(c: Vector2i) -> bool: return _open(c))
	cells.shuffle()
	for c in cells:
		if saps.size() >= n:
			break
		var p := room.cell_center(c)
		if p.distance_to(pix.position) < 48.0 or saps.any(func(s: Dictionary) -> bool: return s.pos.distance_to(p) < 64.0):
			continue
		var rate := randf_range(1.0 / 16.0, 1.0 / 11.0) * speedup / Game.time_mult()
		saps.append({"pos": p, "water": randf_range(0.55, 1.0), "rate": rate, "dead": false})


## A floor cell with open floor all round, so Pix can reach it from any side.
func _open(c: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if room.at(c + Vector2i(dx, dy)) != ".":
				return false
	return true


func begin() -> void:
	super.begin()
	if Game.autoplay:
		pix.input_enabled = false


func _alive() -> int:
	return saps.filter(func(s: Dictionary) -> bool: return not s.dead).size()


func goal_text() -> String:
	return "ALIVE %d/%d   TIME %d" % [_alive(), saps.size(), ceili(time_left)]


func _near() -> Dictionary:
	for s in saps:
		if not s.dead and s.pos.distance_to(pix.position) < REACH:
			return s
	return {}


func tick(delta: float) -> void:
	for s in saps:
		if s.dead:
			continue
		s.water -= s.rate * delta
		if s.water <= 0.0:
			s.dead = true
			Fx.burst(s.pos + Vector2(0, -6), [Px.C.olive, Px.C.brown, Px.C.tan], 26, null, 0, 70.0)
			penalty(10.0, "IT DRIED UP!", s.pos + Vector2(0, -20))
	if Game.autoplay:
		_bot(delta)
	elif Input.is_action_just_pressed("attack"):
		_water()
	if saps.size() - _alive() > 1:
		finish(false, float(_alive()) / saps.size())


func _water() -> void:
	var s := _near()
	if s.is_empty():
		return
	s.water = 1.0
	Audio.play("coin", 0.0)
	Fx.burst(s.pos + Vector2(0, -8), [Px.C.cyan, Px.C.blue, Px.C.white], 14, null, 0, 40.0)
	Fx.word(["WATER!", "GROW!", "+1 TREE"].pick_random(), s.pos + Vector2(0, -22), Px.C.cyan)


## Autoplay: walk to the driest sapling and water it.
func _bot(delta: float) -> void:
	var best = null
	for s in saps:
		if not s.dead and (best == null or s.water < best.water):
			best = s
	if best == null:
		return
	if best.water > 0.8:
		return
	var to: Vector2 = best.pos - pix.position
	if to.length() < REACH - 4.0:
		_water()
		return
	var dir := to.normalized()
	if bot_stuck > 0.0:
		bot_stuck -= delta
		dir = Vector2(-dir.y, dir.x)
	var before := pix.position
	pix.position = room.move(pix.position, dir * Player.SPEED * delta)
	pix.facing = dir
	if pix.position.distance_to(before) < 0.2:
		bot_stuck = 0.4


func judge() -> Array:
	var alive := _alive()
	return [saps.size() - alive <= 1, float(alive) / maxf(1, saps.size())]


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.green.darkened(0.6), 0.25))
	for s in saps:
		var p: Vector2 = s.pos.floor()
		# Soil patch.
		draw_rect(Rect2(p + Vector2(-7, 2), Vector2(14, 5)), Px.C.dark)
		draw_rect(Rect2(p + Vector2(-6, 3), Vector2(12, 3)), Px.C.brown)
		if s.dead:
			draw_rect(Rect2(p + Vector2(-3, 2), Vector2(6, 1)), Px.C.tan)
			continue
		var w: float = s.water
		var leaf: Color = Px.C.lime if w > 0.5 else (Px.C.olive if w > 0.25 else Px.C.tan)
		var droop := 0 if w > 0.25 else 2
		draw_rect(Rect2(p + Vector2(0, -8), Vector2(1, 10)), Px.C.green)
		draw_rect(Rect2(p + Vector2(-4, -8 + droop), Vector2(4, 2)), leaf)
		draw_rect(Rect2(p + Vector2(1, -10 + droop), Vector2(4, 2)), leaf)
		draw_rect(Rect2(p + Vector2(-2, -12), Vector2(5, 2)), leaf)
		Px.bar(self, Rect2(p + Vector2(-8, 9), Vector2(16, 3)), w, Px.C.cyan if w > 0.3 else Px.C.red)
		if w < 0.3 and int(t * 4) % 2 == 0:
			Px.text_c(self, "!", p.x, p.y - 24, Px.C.red)
	var s2 := _near()
	if not s2.is_empty():
		Px.text_c(self, "J: WATER", s2.pos.x, s2.pos.y - 32, Px.C.white)
	draw_timer()
	draw_card()
