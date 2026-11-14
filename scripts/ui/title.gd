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
	# Aryabhatta and Ramanujan blocks, the statue and trees, as pixel blocks.
	var bl := [
		[10, 46, 70, Px.C.plum], [86, 30, 50, Px.C.night], [124, 60, 40, Px.C.plum],
		[190, 70, 62, Px.C.night], [266, 40, 46, Px.C.plum], [312, 64, 34, Px.C.night],
	]
	for b in bl:
		var r := Rect2(b[0], base_y - b[2], b[1], b[2])
		ci.draw_rect(r, b[3])
		for wy in range(int(r.position.y) + 6, base_y - 6, 8):
			for wx in range(int(r.position.x) + 4, int(r.end.x) - 4, 7):
				var lit := (wx * 7 + wy * 13 + int(t * 0.5)) % 5 == 0
				ci.draw_rect(Rect2(wx, wy, 3, 4), Px.C.gold if lit else Px.C.ink)
	ci.draw_rect(Rect2(0, base_y, Px.W, Px.H - base_y), Px.C.jade.darkened(0.5))
	for x in range(0, Px.W, 8):
		ci.draw_rect(Rect2(x, base_y, 4, 1), Px.C.jade)


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
	# Pix waits by the gate.
	var tex := Px.char_tex(Game.pix_look(), "walk1" if int(t * 2.0) % 2 == 0 else "idle")
	draw_texture_rect(tex, Rect2(Vector2(Px.W / 2.0 - 16, 118), tex.get_size() * 2), false)
	if int(t * 2.0) % 2 == 0:
		Px.text_c(self, "PRESS ANY KEY", Px.W / 2.0, 166, Px.C.white)
	Px.text_c(self, "CONTAINS FLASHING LIGHTS. SEE OPTIONS.", Px.W / 2.0, 186, Px.C.steel)
	Px.text_c(self, "TEAM CLAUDE LAGGYE  -  SYNERGY '26", Px.W / 2.0, 200, Px.C.slate)
