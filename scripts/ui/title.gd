extends Node2D
## "PRESS ANY KEY". Browsers block audio until the first key or click.

var t := 0.0
var stars := []
var leaving := false


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	for i in 70:
		stars.append(Vector2(rng.randi_range(0, Px.W), rng.randi_range(0, 120)))


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if leaving or t < 0.4:
		return
	if (e is InputEventKey or e is InputEventJoypadButton or e is InputEventMouseButton) and e.is_pressed():
		leaving = true
		Audio.play("select", 0.0)
		Audio.play_music("title")
		Game.goto("menu")


static func draw_skyline(ci: CanvasItem, t: float, base_y := 150) -> void:
	# The IIIT-B front at night, in the buildings' real colours (from the campus
	# brochure's photos): cream Visvesvaraya, off-white Aryabhatta with sand-yellow
	# panels and its white tower, white Ramanujan with a mustard panel, the flag and
	# fountain on the lawn, the football field's goalpost. No city: this is campus.
	var night := 0.55
	var blocks := [
		[6, 30, 34, Color("efe3c2").darkened(night)],     # Visvesvaraya hostel
		[44, 196, 40, Color("dcd8cc").darkened(night)],   # Aryabhatta
		[126, 32, 58, Color("ece9e1").darkened(0.45)],    # Aryabhatta tower
		[260, 70, 48, Color("ece9e1").darkened(night)],   # Ramanujan
	]
	for b in blocks:
		var r := Rect2(b[0], base_y - b[2], b[1], b[2])
		ci.draw_rect(r, b[3])
		ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2), b[3].lightened(0.15))
		for wy in range(int(r.position.y) + 6, base_y - 8, 9):
			for wx in range(int(r.position.x) + 4, int(r.end.x) - 4, 8):
				var lit := (wx * 7 + wy * 13 + int(t * 0.5)) % 6 == 0
				ci.draw_rect(Rect2(wx, wy, 4, 4), Px.C.gold if lit else Px.C.ink)
	# Sand panels on Aryabhatta, the blue IIIT-B sign on its tower, Ramanujan's
	# mustard panel.
	for px in [60, 100, 170, 210]:
		ci.draw_rect(Rect2(px, base_y - 40, 8, 40), Color("e6cf98").darkened(night))
	ci.draw_rect(Rect2(132, base_y - 54, 20, 5), Px.C.blue)
	ci.draw_rect(Rect2(296, base_y - 48, 10, 48), Color("d9a62e").darkened(night))
	# Entrance doors and the reception's light.
	ci.draw_rect(Rect2(136, base_y - 18, 12, 18), Px.C.gold.darkened(0.3))
	# Flag on its pole, waving in two frames.
	ci.draw_rect(Rect2(178, base_y - 62, 1, 62), Px.C.mist)
	var wave := int(t * 3.0) % 2
	for i in 3:
		ci.draw_rect(Rect2(179, base_y - 62 + i * 3 + wave * (i % 2), 10, 3), [Px.C.orange, Px.C.white, Px.C.green][i])
	# Trees.
	for tx in [36, 242, 330, 360]:
		ci.draw_rect(Rect2(tx + 3, base_y - 8, 2, 8), Px.C.brown.darkened(0.4))
		ci.draw_rect(Rect2(tx, base_y - 18, 8, 11), Px.C.jade.darkened(0.45))
		ci.draw_rect(Rect2(tx + 1, base_y - 20, 6, 3), Px.C.jade.darkened(0.35))
	# Goalpost of the football ground.
	ci.draw_rect(Rect2(342, base_y - 14, 1, 14), Px.C.white)
	ci.draw_rect(Rect2(370, base_y - 14, 1, 14), Px.C.white)
	ci.draw_rect(Rect2(342, base_y - 14, 29, 1), Px.C.white)
	ci.draw_rect(Rect2(0, base_y, Px.W, Px.H - base_y), Px.C.jade.darkened(0.5))
	for x in range(0, Px.W, 8):
		ci.draw_rect(Rect2(x, base_y, 4, 1), Px.C.jade)
	# The fountain on the lawn.
	ci.draw_rect(Rect2(176, base_y + 2, 24, 3), Px.C.steel)
	ci.draw_rect(Rect2(180, base_y - 1, 16, 3), Px.C.blue)
	for i in 3:
		ci.draw_rect(Rect2(186 + (i - 1) * 3, base_y - 6 + int(t * 6.0 + i) % 4, 1, 2), Px.C.white)


func _draw() -> void:
	draw_rect(Rect2(0, 0, Px.W, Px.H), Px.C.ink)
	for i in stars.size():
		var s: Vector2 = stars[i]
		if (i + int(t * 3.0)) % 7 != 0:
			draw_rect(Rect2(s, Vector2.ONE), Px.C.mist if i % 3 else Px.C.gold)
	draw_skyline(self, t)
	# Logo with a glitch offset.
	var gl := 1 if int(t * 5.0) % 9 == 0 else 0
	Px.text_c(self, "BADMOSI", Px.W / 2.0 + gl * 2, 24, Px.C.red, 48)
	Px.text_c(self, "BADMOSI", Px.W / 2.0 - gl, 22, Px.C.gold, 48)
	# The whole gang on the lawn, bobbing out of step.
	for i in Roster.ORDER.size():
		var look: Dictionary = Roster.get_char(Roster.ORDER[i]).look
		var bob := int(t * 3.0 + i * 0.7) % 2
		var tex := Px.char_tex(look, "walk1" if bob == 0 else "idle")
		draw_texture(tex, Vector2(8 + i * 17.6, 150 - tex.get_height() - bob))
	if int(t * 2.0) % 2 == 0:
		Px.text_c(self, "PRESS ANY KEY", Px.W / 2.0, 166, Px.C.white)
	Px.text_c(self, "CONTAINS FLASHING LIGHTS. SEE OPTIONS.", Px.W / 2.0, 186, Px.C.steel)
