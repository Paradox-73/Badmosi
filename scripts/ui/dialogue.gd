class_name DialogueBox
extends Node2D
## Portrait, name and at most 2 lines per box. Attack advances; holding it skips.

signal finished

var pages: Array = []   # each: {who, text, look (optional), tex (optional)}
var idx := 0
var shown := 0.0
var hold := 0.0
var _t := 0.0


static func wrap_text(text: String, max_chars := 46) -> Array:
	var lines := []
	var cur := ""
	for w in text.split(" "):
		if cur.length() + w.length() + 1 > max_chars and cur != "":
			lines.append(cur)
			cur = w
		else:
			cur = w if cur == "" else cur + " " + w
	if cur != "":
		lines.append(cur)
	return lines


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_t += delta
	if pages.is_empty():
		_end()
		return
	var full: String = pages[idx].text
	shown = minf(shown + delta * 60.0, full.length())
	if Input.is_action_pressed("attack"):
		hold += delta
		if hold > 0.8:
			_end()
			return
	else:
		hold = 0.0
	if Input.is_action_just_pressed("attack") or (Input.is_action_just_pressed("dodge")):
		if shown < full.length():
			shown = full.length()
		else:
			idx += 1
			shown = 0.0
			Audio.play("move", 0.0)
			if idx >= pages.size():
				_end()
				return
	if int(shown) % 3 == 1:
		Audio.play("type", 0.2, -10.0)
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var full: String = pages[idx].text
		if shown < full.length():
			shown = full.length()
		else:
			idx += 1
			shown = 0.0
			if idx >= pages.size():
				_end()
		get_viewport().set_input_as_handled()


func _end() -> void:
	if is_queued_for_deletion():
		return
	finished.emit()
	queue_free()


func _draw() -> void:
	if idx >= pages.size():
		return
	var pg: Dictionary = pages[idx]
	var r := Rect2(8, Px.H - 52, Px.W - 16, 46)
	Px.panel(self, r, Px.C.ink, Px.C.mist)
	var tx := 16.0
	var tex: Texture2D = pg.get("tex")
	if tex == null and pg.has("look"):
		tex = Px.char_tex(pg.look, "idle")
	if tex:
		var pr := Rect2(14, Px.H - 46, 34, 34)
		draw_rect(pr, Px.C.night)
		var s := 2 if tex.get_height() <= 20 else 1
		draw_texture_rect(tex, Rect2(pr.position + Vector2((34 - tex.get_width() * s) / 2.0, 34 - tex.get_height() * s), tex.get_size() * s), false)
		tx = 54.0
	Px.text(self, pg.get("who", ""), Vector2(tx, Px.H - 47), Px.C.gold)
	var lines := wrap_text(pg.text.substr(0, int(shown)), int((Px.W - tx - 20) / 6))
	for i in mini(lines.size(), 3):
		Px.text(self, lines[i], Vector2(tx, Px.H - 35 + i * 10), Px.C.white)
	if shown >= pg.text.length() and int(_t * 3.0) % 2 == 0:
		Px.text(self, "J>", Vector2(Px.W - 26, Px.H - 16), Px.C.gold)
