extends Node2D
## Room 404: the door sign changes, every club head shows up, the run is counted.

var t := 0.0
var heads := []
var done := false
var stamped := false


func _ready() -> void:
	Audio.play_music("ending")
	for id in Clubs.ORDER:
		heads.append(Px.char_tex(Clubs.get_club(id).head_look, "idle"))
	if not Game.practice:
		Game.save_run()


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if t > 1.0 and not stamped:
		stamped = true
		Audio.play("stamp", 0.0)
		Fx.shake(3, 0.2)
	if t > 9.0 and not done and (Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("pause")):
		done = true
		Game.goto("credits")


func _draw() -> void:
	draw_rect(Rect2(0, 0, Px.W, Px.H), Px.C.ink)
	for y in range(Px.TOP, Px.H, 16):
		for x in range(0, Px.W, 16):
			draw_texture(Px.tile_tex("floor", {"floor": Px.C.plum}), Vector2(x, y))
	# The door and its sign.
	draw_rect(Rect2(160, 30, 64, 70), Px.C.brown)
	draw_rect(Rect2(164, 34, 56, 66), Px.C.tan.darkened(0.3))
	var sign := "404 NOT FOUND" if t < 3.0 else "404 CLUB FOUND"
	var blocky := t > 2.6 and t < 3.4
	var r := Rect2(130, 10, 124, 16)
	Px.panel(self, r, Px.C.ink, Px.C.gold)
	if blocky:
		for i in 14:
			draw_rect(Rect2(134 + i * 8, 13, 8, 10), [Px.C.gold, Px.C.red, Px.C.lime][i % 3])
	else:
		Px.text_c(self, sign, Px.W / 2.0, 14, Px.C.red if t < 3.0 else Px.C.lime)
	if t > 1.0 and t < 3.0:
		Px.text_c(self, "APPROVED", Px.W / 2.0, 56, Px.C.red, 16)
	# Pix and the first members.
	var pix := Px.char_tex(Game.pix_look(), "walk1" if int(t * 3) % 2 == 0 else "idle")
	draw_texture_rect(pix, Rect2(Vector2(176, 96), pix.get_size() * 2), false)
	var n := clampi(int((t - 3.5) * 3.0), 0, heads.size())
	for i in n:
		var x := 16 + (i % 7) * 52 + (26 if i >= 7 else 0)
		var y := 132 + (i / 7) * 26
		draw_texture(heads[i], Vector2(x, y))
	if t > 8.0:
		Px.panel(self, Rect2(40, 186, 304, 26), Px.C.night, Px.C.gold)
		Px.text_c(self, "PLAYED IT STRAIGHT: %d.  FLIPPED THE TABLE: %d." % [Game.straight_count(), Game.flipped_count()], Px.W / 2.0, 190, Px.C.white)
		Px.text_c(self, "THE PIXEL CLUB IS OPEN. PRESS J.", Px.W / 2.0, 200, Px.C.gold)
