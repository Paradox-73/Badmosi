extends Node2D
## The opening flashback, in sepia: campus life before, the Admin's Circular
## No. 404, the clubs brainwashed, the lockdown. Then back to full colour,
## where the gang is the only free crew left. J skips a panel, Esc skips all.

const SEPIA := [Color("1e140c"), Color("6b4a2b"), Color("c09060"), Color("f2e2c0")]
const CLUB_IDS := ["impulse", "symphony", "quiz", "zense", "eightbit", "vinci", "debsoc", "parvaaz"]

var panels := [
	{"draw": "_campus", "lines": ["IIIT-B. ONE SEM AGO.", "CLUBS RAN CAMPUS LIFE. FEST NIGHTS, 2 AM CHAI, PURE BADMOSI."]},
	{"draw": "_admin", "lines": ["THEN THE ADMIN ISSUED CIRCULAR NO. 404:", "FUN IS PENDING APPROVAL. INDEFINITELY."]},
	{"draw": "_brainwash", "lines": ["ONE BY ONE, EVERY CLUB WAS BRAINWASHED", "INTO ENFORCING THE ADMIN'S RULES."]},
	{"draw": "_lockdown", "lines": ["THEN CAME THE LOCKDOWN. LIFTS FALLING. LIGHTS OUT.", "CEILINGS CAVING IN. ALL 'FOR YOUR SAFETY'."]},
	{"draw": "_gang", "lines": ["NOW ONLY ONE CREW IS STILL FREE: BADMOSI.", ""]},
]
var idx := 0
var t := 0.0
var done := false


func _ready() -> void:
	Audio.play_music("theme_" + Game.character)
	_apply_palette()
	var gang_line := "FREE THE CLUBS. TAKE DOWN THE ADMIN AND ITS %s POLICIES." % ("AWFUL" if Game.opts.clean_text else "F***-ASS")
	panels[-1].lines[1] = Game.char_name() + ": " + gang_line


func _apply_palette() -> void:
	Game.main.set_palette(SEPIA if idx < panels.size() - 1 else [], 1.0)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if Game.autoplay and t > 3.0:
		_next()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("attack"):
		_next()
	elif e.is_action_pressed("pause") or e.is_action_pressed("dodge"):
		get_viewport().set_input_as_handled()
		_finish()


func _next() -> void:
	if t < 0.4:
		return
	if _typed() < _full_text().length():
		t = 99.0    # finish typing first
		return
	idx += 1
	t = 0.0
	if idx >= panels.size():
		_finish()
		return
	_apply_palette()
	if idx == 3:
		Audio.play("crash", 0.0)
		Fx.shake(3, 0.4)
	elif idx == panels.size() - 1:
		Audio.play("semup", 0.0)
		Game.main.flash(Color(1, 1, 1, 0.6), 0.3)
	else:
		Audio.play("door", 0.0)


func _finish() -> void:
	if done:
		return
	done = true
	Game.main.set_palette([], 0.0)
	Game.goto("opening")


## The panel's caption, wrapped to the caption box (58 characters a line).
func _full_text() -> String:
	var out := []
	for l in panels[mini(idx, panels.size() - 1)].lines:
		var line := ""
		for w in l.split(" "):
			if line.length() + w.length() + 1 > 58 and line != "":
				out.append(line)
				line = ""
			line = w if line == "" else line + " " + w
		out.append(line)
	return "\n".join(out)


func _typed() -> int:
	return int(t * 40.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, Px.W, Px.H), Px.C.ink)
	var p: Dictionary = panels[mini(idx, panels.size() - 1)]
	call(p.draw)
	# Caption box, typed out.
	Px.panel(self, Rect2(8, 170, Px.W - 16, 40), Px.C.night, Px.C.gold)
	var shown := _full_text().substr(0, _typed())
	var y := 175
	for line in shown.split("\n"):
		Px.text(self, line, Vector2(16, y), Px.C.white)
		y += 11
	if idx < panels.size() - 1:
		Px.text(self, "FLASHBACK", Vector2(8, 6), Px.C.gold)
	Px.text(self, "J: NEXT  ESC: SKIP", Vector2(Px.W - Px.text_w("J: NEXT  ESC: SKIP") - 8, 6), Px.C.steel)


func _ground() -> void:
	for y in range(24, 168, 16):
		for x in range(0, Px.W, 16):
			draw_texture(Px.tile_tex("grass" if y > 90 else "path", {}), Vector2(x, y))


func _member(id: String, pos: Vector2, frame := "idle") -> void:
	draw_texture(Px.char_tex(Clubs.get_club(id).look, frame), pos)


func _campus() -> void:
	_ground()
	# The fountain on the lawn.
	var f := Vector2(Px.W / 2.0, 70)
	draw_rect(Rect2(f + Vector2(-26, 6), Vector2(52, 12)), Px.C.steel)
	draw_rect(Rect2(f + Vector2(-20, 8), Vector2(40, 8)), Px.C.cyan)
	draw_rect(Rect2(f + Vector2(-3, -10), Vector2(6, 16)), Px.C.steel)
	for i in 6:
		var a := t * 4.0 + i
		draw_rect(Rect2(f + Vector2(sin(a) * 10, -10 - absf(cos(a)) * 8), Vector2(2, 2)), Px.C.cyan)
	# Clubs having fun: dancing, music notes, quiz buzzers.
	for i in CLUB_IDS.size():
		var x := 24 + i * 44
		var bob := int(t * 6.0 + i) % 2
		_member(CLUB_IDS[i], Vector2(x, 120 - bob * 2), "walk1" if bob == 0 else "walk2")
		if i % 2 == 0:
			Px.text(self, ["5-6-7-8!", "LA LA", "BZZT!", "SHIP IT"][i / 2], Vector2(x - 6, 104 - bob * 2), Px.C.gold)


func _admin() -> void:
	draw_rect(Rect2(0, 24, Px.W, 144), Px.C.plum.darkened(0.4))
	var tex := Boss.admin_tex()
	draw_texture_rect(tex, Rect2(Vector2(Px.W / 2.0 - tex.get_width(), 40), tex.get_size() * 2), false)
	# The circular, stamped.
	var c := Rect2(40, 60, 90, 70)
	draw_rect(c, Px.C.white)
	for i in 6:
		draw_rect(Rect2(c.position + Vector2(8, 16 + i * 8), Vector2(74 - (i % 3) * 12, 2)), Px.C.slate)
	Px.text(self, "CIRCULAR 404", c.position + Vector2(6, 4), Px.C.ink)
	if t > 1.2:
		var s := 2 if t < 1.4 else 1
		Px.text(self, "APPROVED", c.position + Vector2(12, 40), Px.C.red, 8 * s)
	if t > 1.2 and t < 1.3:
		Fx.shake(2, 0.1)


func _brainwash() -> void:
	draw_rect(Rect2(0, 24, Px.W, 144), Px.C.night)
	var center := Vector2(Px.W / 2.0, 96)
	# Hypno rings out of the Admin's office.
	for k in 4:
		var r := fmod(t * 50.0 + k * 30.0, 120.0)
		for i in 28:
			var a := i * TAU / 28.0
			draw_rect(Rect2((center + Vector2(cos(a), sin(a) * 0.6) * r).round(), Vector2(2, 2)), Px.C.red if i % 2 == 0 else Px.C.violet)
	var tex := Boss.admin_tex()
	draw_texture(tex, center - Vector2(tex.get_width() / 2.0, tex.get_height()))
	for i in CLUB_IDS.size():
		var a2 := i * TAU / CLUB_IDS.size()
		var p := center + Vector2(cos(a2) * 130, sin(a2) * 55) - Vector2(8, 16)
		_member(CLUB_IDS[i], p)
		if t > 0.8 + i * 0.2:
			# Glowing eyes: brainwashed.
			draw_rect(Rect2(p + Vector2(5, 5), Vector2(1, 1)), Px.C.red)
			draw_rect(Rect2(p + Vector2(10, 5), Vector2(1, 1)), Px.C.red)


func _lockdown() -> void:
	_ground()
	# A block with a falling lift, a dead light and a cracked ceiling.
	draw_rect(Rect2(40, 30, 160, 130), Px.C.slate)
	draw_rect(Rect2(60, 40, 40, 110), Px.C.ink)
	var lift_y := minf(40.0 + t * t * 120.0, 118.0)
	draw_rect(Rect2(64, lift_y, 32, 30), Px.C.grey)
	Px.text(self, "LIFT", Vector2(68, lift_y + 10), Px.C.ink)
	if lift_y >= 118.0 and int(t * 10) % 3 == 0:
		Px.text(self, "CRASH!", Vector2(54, 112), Px.C.red)
	for i in 5:
		var fy := fmod(t * 90.0 + i * 37.0, 120.0)
		draw_rect(Rect2(120 + i * 14, 40 + fy, 6, 6), Px.C.tan)
	draw_rect(Rect2(116, 36, 76, 4), Px.C.ink)
	# The gate, chained.
	var g := Vector2(230, 60)
	for i in 8:
		draw_rect(Rect2(g + Vector2(i * 16, 0), Vector2(3, 90)), Px.C.steel)
	draw_rect(Rect2(g + Vector2(0, 40), Vector2(130, 4)), Px.C.gold)
	draw_rect(Rect2(g + Vector2(58, 34), Vector2(14, 14)), Px.C.gold)
	Px.text(self, "LOCKDOWN", g + Vector2(30, 70), Px.C.red)
	# Power cuts: the whole scene blinks out now and then.
	if int(t * 3.0) % 4 == 3:
		draw_rect(Rect2(0, 24, Px.W, 144), Color(Px.C.dark, 0.85))


func _gang() -> void:
	draw_rect(Rect2(0, 24, Px.W, 144), Px.C.ink)
	for i in 30:
		draw_rect(Rect2((i * 61) % Px.W, 24 + (i * 23) % 140, 1, 1), Px.C.slate)
	var others: Array = Roster.ORDER.filter(func(id): return id != Game.character)
	for i in others.size():
		var x := 20 + (i % 10) * 36
		var y := 40 + (i / 10) * 26
		draw_texture(Px.char_tex(Roster.get_char(others[i]).look, "idle"), Vector2(x, y))
	var tex := Px.char_tex(Game.pix_look(), "walk1" if int(t * 3.0) % 2 == 0 else "idle")
	draw_texture_rect(tex, Rect2(Vector2(Px.W / 2.0 - 16, 100), tex.get_size() * 2), false)
	Px.text_c(self, "BADMOSI", Px.W / 2.0, 136, Px.C.gold, 16)
