extends Minigame
## Film Division: boom operator. Keep the mic over whoever is speaking, without
## dipping it into the camera frame (the dashed box).

const SHOT_TOP := 92.0

var actors := []   # {x, dir, look}
var speaker := 0
var speak_t := 0.0
var mic := Vector2(192, 60)
var meter := 0.5
var in_shot_t := 0.0
var shot_cd := 0.0


func info() -> Dictionary:
	return {"goal": "HOLD THE BOOM MIC OVER THE SPEAKER, ABOVE THE FRAME LINE. AUDIO OVER 70% AT THE END.",
		"keys": ["MOUSE, OR ARROWS TO MOVE THE MIC"], "time": 75.0}


func _ready() -> void:
	super._ready()
	if short_round:
		time_total = 12.0
		time_left = 12.0
	var d: Dictionary = Clubs.get_club("parvaaz")
	actors = [
		{"x": 120.0, "dir": 1.0, "look": d.look},
		{"x": 260.0, "dir": -1.0, "look": Clubs.get_club("film").look},
	]
	cursor = mic
	cursor_speed = 120.0


func goal_text() -> String:
	return "AUDIO %d%%   TIME %d" % [roundi(meter * 100), ceili(time_left)]


func tick(delta: float) -> void:
	speak_t -= delta
	shot_cd -= delta
	if speak_t <= 0.0:
		speak_t = randf_range(1.6, 3.2) * Game.time_mult()
		speaker = (speaker + 1) % actors.size() if randf() < 0.75 else speaker
	for a in actors:
		a.x += a.dir * 18.0 * delta * (1.0 if t > 2.0 else 0.0)
		if a.x < 50 or a.x > Px.W - 50:
			a.dir *= -1.0
	cursor_step(delta, Rect2(10, 30, Px.W - 20, 160))
	mic = cursor
	var target_x: float = actors[speaker].x
	var over_speaker := absf(mic.x - target_x) < 18.0
	if mic.y + 6 > SHOT_TOP:
		in_shot_t += delta
		if shot_cd <= 0.0:
			shot_cd = 1.0
			penalty(10.0, "BOOM IN SHOT!", Vector2(mic.x, mic.y - 14))
		meter -= delta * 0.15
	elif over_speaker:
		meter += delta * 0.09
	else:
		meter -= delta * 0.07
	meter = clampf(meter, 0.0, 1.0)


func judge() -> Array:
	return [meter >= 0.7, meter]


func _draw() -> void:
	draw_rect(PLAY, Px.C.ink)
	# Set: a pixel backdrop of a hostel corridor.
	draw_rect(Rect2(0, 100, Px.W, 116), Px.C.plum)
	for x in range(0, Px.W, 48):
		draw_rect(Rect2(x + 10, 108, 26, 46), Px.C.brown.darkened(0.3))
	draw_rect(Rect2(0, 160, Px.W, 56), Px.C.slate.darkened(0.4))
	# Camera frame.
	for x in range(8, Px.W - 8, 6):
		draw_rect(Rect2(x, SHOT_TOP, 3, 1), Px.C.red)
		draw_rect(Rect2(x, 204, 3, 1), Px.C.red)
	Px.text(self, "CAMERA FRAME", Vector2(10, SHOT_TOP + 3), Px.C.red)
	for i in actors.size():
		var a: Dictionary = actors[i]
		var tex := Px.char_tex(a.look, "walk1" if int(t * 4 + i) % 2 == 0 else "idle")
		draw_texture_rect(tex, Rect2(Vector2(a.x - 16, 130), tex.get_size() * 2), false)
		if i == speaker:
			Px.panel(self, Rect2(a.x - 22, 112, 44, 14), Px.C.white, Px.C.dark)
			Px.text_c(self, ["...AND THEN", "NO WAY!", "THE ROOM!", "404?!", "ACTION!"][int(t) % 5], a.x, 115, Px.C.dark, 8, false)
	# Boom pole and mic.
	var m := mic.round()
	draw_line(Vector2(Px.W + 10, 26), m, Px.C.steel, 2.0)
	draw_rect(Rect2(m - Vector2(5, 3), Vector2(10, 7)), Px.C.dark)
	draw_rect(Rect2(m - Vector2(4, 2), Vector2(8, 5)), Px.C.grey)
	# Audio meter.
	Px.text(self, "AUDIO", Vector2(10, 32), Px.C.mist)
	for i in 20:
		var on := float(i) / 20.0 < meter
		var c: Color = Px.C.lime if i < 14 else (Px.C.gold if i < 17 else Px.C.red)
		draw_rect(Rect2(46 + i * 6, 32, 5, 7), c if on else Px.C.night)
	draw_rect(Rect2(46 + 14 * 6 - 1, 30, 1, 11), Px.C.white)
	var dc := Px.char_tex(Clubs.get_club("film").head_look, "idle")
	draw_texture(dc, Vector2(Px.W - 40, 40))
	Px.text(self, "DIRECTOR", Vector2(Px.W - 60, 62), Px.C.gold)
	draw_timer()
	draw_card()
