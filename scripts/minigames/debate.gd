extends Minigame
## DebSoc: point of order. REBUTTAL's speech scrolls line by line. Object (J)
## only to lines with a logical fallacy; stay quiet on fair lines.

const LINE_TIME := 3.6

var lines := []     # {mark, text, called, judged}
var li := -1
var line_t := 0.0
var meter := 0.5    # 1.0 = audience fully on Pix's side
var caught := 0
var falsies := 0
var missed := 0
var show_mark := ""
var show_t := 0.0


static func load_lines() -> Array:
	var out := []
	var f := FileAccess.open("res://data/debsoc.txt", FileAccess.READ)
	if f == null:
		return out
	for raw in f.get_as_text().split("\n"):
		var l := raw.strip_edges()
		if l == "" or l.begins_with("#"):
			continue
		var parts := l.split("|", false, 1)
		if parts.size() == 2:
			out.append({"mark": parts[0].strip_edges(), "text": parts[1].strip_edges()})
	return out


func info() -> Dictionary:
	return {"goal": "PRESS J (POINT OF ORDER!) ONLY ON LINES WITH A FALLACY. KEEP THE AUDIENCE ON YOUR SIDE.",
		"keys": ["J OR CLICK: POINT OF ORDER!"], "time": 60.0}


func uses_timer() -> bool:
	return false


func _ready() -> void:
	super._ready()
	var all := load_lines()
	var first: Dictionary = all.pop_front()
	all.shuffle()
	lines = [first]
	var n := 15 if not short_round else 4
	lines.append_array(all.slice(0, n))
	for l in lines:
		l.called = false
		l.judged = false


func begin() -> void:
	_next_line()


func _next_line() -> void:
	if li >= 0:
		var l: Dictionary = lines[li]
		if not l.called and l.mark != "FAIR":
			missed += 1
			meter -= 0.06
			penalty(5.0, "MISSED: " + l.mark, Vector2(Px.W / 2.0, 150))
	li += 1
	line_t = 0.0
	if li >= lines.size():
		finish(meter >= 0.5, clampf(meter, 0.0, 1.0))


func goal_text() -> String:
	return "LINE %d/%d   CAUGHT %d   FALSE CALLS %d" % [mini(li + 1, lines.size()), lines.size(), caught, falsies]


func tick(delta: float) -> void:
	line_t += delta
	show_t -= delta
	if li >= lines.size():
		return
	var l: Dictionary = lines[li]
	var pressed := Input.is_action_just_pressed("attack") or _clicked
	_clicked = false
	if pressed and not l.called:
		l.called = true
		Audio.play("objection", 0.0)
		if l.mark != "FAIR":
			caught += 1
			meter += 0.1
			show_mark = l.mark + "!"
			show_t = 1.2
			Fx.word("POINT OF ORDER!", Vector2(Px.W / 2.0, 70), Px.C.gold, 16)
			Audio.play("right", 0.0)
		else:
			falsies += 1
			meter -= 0.1
			penalty(10.0, "THAT WAS FAIR!", Vector2(Px.W / 2.0, 150))
	meter = clampf(meter, 0.0, 1.0)
	if line_t >= LINE_TIME * Game.time_mult():
		_next_line()


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.maroon.darkened(0.6), 0.96))
	# Podiums.
	var rb := Px.char_tex(Clubs.get_club("debsoc").head_look, "walk1" if int(t * 3) % 2 == 0 else "idle")
	draw_texture_rect(rb, Rect2(Vector2(40, 96), rb.get_size() * 2), false)
	draw_rect(Rect2(32, 128, 48, 30), Px.C.brown)
	Px.text_c(self, "REBUTTAL", 56, 162, Px.C.white)
	var pix := Px.char_tex(Player.PIX_LOOK, "idle")
	draw_texture_rect(pix, Rect2(Vector2(Px.W - 72, 96), pix.get_size() * 2), false)
	draw_rect(Rect2(Px.W - 80, 128, 48, 30), Px.C.brown)
	Px.text_c(self, "PIX", Px.W - 56, 162, Px.C.gold)
	# Speech bubble.
	if li >= 0 and li < lines.size():
		var l: Dictionary = lines[li]
		var r := Rect2(96, 32, 192, 58)
		Px.panel(self, r, Px.C.white, Px.C.dark)
		var ws := DialogueBox.wrap_text(l.text, 30)
		for i in mini(ws.size(), 4):
			Px.text(self, ws[i], r.position + Vector2(6, 6 + i * 11), Px.C.dark, 8, false)
		Px.bar(self, Rect2(r.position.x, r.end.y + 2, r.size.x, 3), 1.0 - line_t / (LINE_TIME * Game.time_mult()), Px.C.slate)
	if show_t > 0.0:
		Px.text_c(self, show_mark, Px.W / 2.0, 104, Px.C.gold)
	# Audience meter.
	Px.text_c(self, "AUDIENCE", Px.W / 2.0, 172, Px.C.mist)
	var mr := Rect2(Px.W / 2.0 - 100, 184, 200, 10)
	draw_rect(mr, Px.C.dark)
	for i in 40:
		var on := float(i) / 40.0 < meter
		draw_rect(Rect2(mr.position.x + 1 + i * 5, mr.position.y + 1, 4, 8), (Px.C.gold if on else Px.C.navy))
	Px.text(self, "REBUTTAL", Vector2(mr.position.x - 54, 185), Px.C.white)
	Px.text(self, "PIX", Vector2(mr.end.x + 6, 185), Px.C.gold)
	draw_rect(Rect2(Px.W / 2.0, 182, 1, 14), Px.C.white)
	draw_card()
