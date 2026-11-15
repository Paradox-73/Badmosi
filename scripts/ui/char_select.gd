extends Node2D
## Character select: the whole Badmosi gang in a 7 x 3 grid. The highlighted
## character's theme plays, and the panel lists their buffs, nerfs and quirk.

const COLS := 7
const CELL := Vector2(26, 30)
const GRID_POS := Vector2(10, 40)

var sel := 0
var t := 0.0
var hover_t := 0.0
var chosen := false


func _ready() -> void:
	sel = maxi(0, Roster.ORDER.find(Game.character))
	Audio.play_music("title")


func _process(delta: float) -> void:
	t += delta
	hover_t += delta
	if hover_t > 0.35 and not chosen:
		Audio.play_music_soon("theme_" + Roster.ORDER[sel])
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if chosen:
		return
	var n := Roster.ORDER.size()
	var old := sel
	if e.is_action_pressed("left"):
		sel = (sel - 1 + n) % n
	elif e.is_action_pressed("right"):
		sel = (sel + 1) % n
	elif e.is_action_pressed("up"):
		sel = sel - COLS if sel >= COLS else sel
	elif e.is_action_pressed("down"):
		sel = sel + COLS if sel + COLS < n else sel
	elif e.is_action_pressed("accept"):
		_pick()
	elif e.is_action_pressed("cancel") or e.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		Audio.play("back", 0.0)
		Game.goto("menu")
	elif e is InputEventMouseMotion or (e is InputEventMouseButton and e.pressed):
		var i := _cell_at(e.position)
		if i >= 0:
			sel = i
			if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
				_pick()
	if sel != old:
		hover_t = 0.0
		Audio.play("move", 0.0)


func _cell_at(p: Vector2) -> int:
	var c := ((p - GRID_POS) / CELL).floor()
	var i := int(c.y) * COLS + int(c.x)
	if c.x < 0 or c.y < 0 or c.x >= COLS or i >= Roster.ORDER.size():
		return -1
	return i


func _pick() -> void:
	chosen = true
	Game.character = Roster.ORDER[sel]
	Audio.play("select", 0.0)
	Audio.play_music("theme_" + Game.character)
	await get_tree().create_timer(0.6).timeout
	Game.goto("hub" if Game.speedrun else "flashback")


func _draw() -> void:
	draw_rect(Rect2(0, 0, Px.W, Px.H), Px.C.ink)
	for i in 24:
		var x := fmod(i * 53.0 + t * (6 + i % 5), Px.W)
		draw_rect(Rect2(x, (i * 37) % Px.H, 1, 1), Px.C.plum)
	Px.text_c(self, "PICK YOUR BADMOS", Px.W / 2.0, 8, Px.C.gold, 16)
	Px.text_c(self, "EVERY ONE PLAYS DIFFERENTLY", Px.W / 2.0, 26, Px.C.steel)
	# Grid.
	for i in Roster.ORDER.size():
		var id: String = Roster.ORDER[i]
		var r := Rect2(GRID_POS + Vector2(i % COLS, i / COLS) * CELL, CELL - Vector2(2, 2))
		var on := i == sel
		Px.panel(self, r, Px.C.night if not on else Px.C.plum, Px.C.gold if on else Px.C.slate)
		var frame := "idle"
		if on and not chosen:
			frame = "walk1" if int(t * 4.0) % 2 == 0 else "walk2"
		elif on:
			frame = "walk1" if int(t * 10.0) % 2 == 0 else "idle"
		var tex := Px.char_tex(Roster.get_char(id).look, frame)
		draw_texture(tex, r.position + Vector2(5, r.size.y - tex.get_height() - 3))
	# The highlighted character.
	var cid: String = Roster.ORDER[sel]
	var d: Dictionary = Roster.get_char(cid)
	var pr := Rect2(198, 40, 178, 158)
	Px.panel(self, pr, Px.C.night, Px.C.gold)
	var big := Px.char_tex(d.look, "walk1" if int(t * 3.0) % 2 == 0 else "idle")
	draw_texture_rect(big, Rect2(pr.position + Vector2(6, 6), big.get_size() * 3), false)
	Px.text(self, d.name, pr.position + Vector2(60, 8), Px.C.white, 16)
	_wrap(d.tag, pr.position + Vector2(60, 28), 19, Px.C.mist)
	var y := pr.position.y + 62
	for line in Roster.perk_lines(cid):
		Px.text(self, line[0], Vector2(pr.position.x + 6, y), Px.C.lime if line[1] else Px.C.red)
		y += 10
	if d.has("quirk"):
		var q: Array = Roster.QUIRKS[d.quirk]
		Px.text(self, "* " + q[0], Vector2(pr.position.x + 6, y + 2), Px.C.cyan)
		_wrap(q[1], Vector2(pr.position.x + 6, y + 12), 28, Px.C.mist)
	var note: String = "THEME: " + d.name if Audio.music_name == "theme_" + cid else "THEME LOADING..."
	Px.text_c(self, "~ " + note + " ~", 100, 140, Px.C.violet)
	Px.text_c(self, "%d OF %d" % [sel + 1, Roster.ORDER.size()], 100, 154, Px.C.slate)
	Px.text_c(self, "ARROWS: PICK   J: PLAY AS %s   K: BACK" % d.name, Px.W / 2.0, Px.H - 11, Px.C.slate)


## Draws s wrapped at max_chars per line.
func _wrap(s: String, pos: Vector2, max_chars: int, color: Color) -> void:
	var line := ""
	var y := pos.y
	for w in s.split(" "):
		if line.length() + w.length() + 1 > max_chars and line != "":
			Px.text(self, line, Vector2(pos.x, y), color)
			y += 9
			line = ""
		line = w if line == "" else line + " " + w
	if line != "":
		Px.text(self, line, Vector2(pos.x, y), color)
