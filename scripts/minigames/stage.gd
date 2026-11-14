extends "res://scripts/minigames/walk_game.gd"
## Parvaaz: stage fright. Spotlights sweep the stage. Sneak between them and
## collect 3 props for the play. Caught in the light: back to the wings.

var lights := []     # {c, r, ph, ax, ay, sp}
var props := []      # {pos, got, kind}
var got := 0
var need := 3
var lit_t := 0.0


func info() -> Dictionary:
	return {"goal": "SNEAK ON STAGE AND GRAB 3 PROPS. STAY OUT OF THE SPOTLIGHTS.",
		"keys": ["MOVE: WASD OR ARROWS   K: DODGE"], "time": 90.0}


func _ready() -> void:
	super._ready()
	if short_round:
		need = 1
	for i in 3:
		lights.append({"r": 26.0 + i * 4, "ph": i * 2.1, "ax": 110.0 - i * 20, "ay": 50.0, "sp": 0.5 + i * 0.18, "cx": 120.0 + i * 80})
	var cells := room.floor_cells()
	cells.shuffle()
	var n := 0
	for c in cells:
		if c.x > 6 and n < need:
			props.append({"pos": room.cell_center(c), "got": false, "kind": n})
			n += 1


func goal_text() -> String:
	return "PROPS %d/%d   TIME %d" % [got, need, ceili(time_left)]


func _light_pos(l: Dictionary) -> Vector2:
	return Vector2(l.cx + sin(t * l.sp + l.ph) * l.ax, 120 + cos(t * l.sp * 1.3 + l.ph) * l.ay)


func tick(delta: float) -> void:
	var in_light := false
	for l in lights:
		if _light_pos(l).distance_to(pix.position + Vector2(0, -4)) < l.r:
			in_light = true
	if in_light and pix.state != Player.S.DODGE:
		lit_t += delta
		if lit_t > 0.15:
			lit_t = 0.0
			penalty(20.0, "STAGE FRIGHT!", pix.position + Vector2(0, -20))
			pix.position = room.cell_center(room.entrance) + Vector2(16, 6)
			Fx.burst(pix.center(), [Px.C.gold, Px.C.white], 16)
	else:
		lit_t = 0.0
	for p in props:
		if not p.got and p.pos.distance_to(pix.position + Vector2(0, -4)) < 12.0:
			p.got = true
			got += 1
			Audio.play("coin", 0.0)
			Fx.word(["A RUBBER SWORD!", "A CROWN!", "A FAKE MOUSTACHE!"][p.kind], p.pos + Vector2(0, -16), Px.C.gold)
	if got >= need:
		finish(true, 1.0 - mistakes * 0.15)


func judge() -> Array:
	return [got >= need, float(got) / need]


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.dark, 0.72))
	# Curtain at the top.
	for x in range(0, Px.W, 8):
		draw_rect(Rect2(x, 24, 6, 14 + (x / 8) % 3 * 2), Px.C.maroon)
	for p in props:
		if not p.got:
			var c: Color = [Px.C.steel, Px.C.gold, Px.C.dark][p.kind]
			draw_rect(Rect2(p.pos - Vector2(4, 4), Vector2(8, 8)), Px.C.ink)
			draw_rect(Rect2(p.pos - Vector2(3, 3), Vector2(6, 6)), c)
			if int(t * 3) % 2 == 0:
				draw_rect(Rect2(p.pos + Vector2(-1, -8), Vector2(2, 2)), Px.C.white)
	for l in lights:
		var c2 := _light_pos(l)
		# Dithered pixel spotlight.
		var r: float = l.r
		for y in range(int(c2.y - r), int(c2.y + r), 2):
			for x in range(int(c2.x - r), int(c2.x + r), 2):
				var d := Vector2(x, y).distance_to(c2)
				if d < r and ((x + y) / 2) % 2 == 0:
					draw_rect(Rect2(x, y, 2, 2), Color(Px.C.gold, 0.5 if d < r * 0.7 else 0.3))
	draw_timer()
	draw_card()
