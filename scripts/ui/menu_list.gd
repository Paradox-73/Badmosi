class_name MenuList
extends Node2D
## A keyboard, gamepad and mouse menu drawn in the pixel font.
## Items: {text, on (Callable)} for buttons, or add "value" (Callable that
## returns a String) and "change" (Callable taking -1 or +1) for settings.

signal back

var items: Array = []
var sel := 0
var width := 160
var row_h := 12
var center := true
var active := true
var title := ""
var _blink := 0.0


func _init(list: Array = [], w := 160) -> void:
	items = list
	width = w


func _process(delta: float) -> void:
	_blink += delta
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if not active or not is_visible_in_tree() or items.is_empty():
		return
	if e.is_action_pressed("up"):
		_move(-1)
	elif e.is_action_pressed("down"):
		_move(1)
	elif e.is_action_pressed("left"):
		_change(-1)
	elif e.is_action_pressed("right"):
		_change(1)
	elif e.is_action_pressed("accept"):
		_activate()
	elif e.is_action_pressed("cancel") or e.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		Audio.play("back", 0.0)
		back.emit()
		return
	elif e is InputEventMouseMotion:
		var i := _row_at(e.position)
		if i >= 0 and i != sel and _enabled(i):
			sel = i
		return
	elif e is InputEventMouseButton and e.pressed:
		var i2 := _row_at(e.position)
		if i2 >= 0:
			sel = i2
			if e.button_index == MOUSE_BUTTON_LEFT:
				_activate()
			elif e.button_index == MOUSE_BUTTON_RIGHT:
				_change(-1)
		else:
			return
	else:
		return
	get_viewport().set_input_as_handled()


func _row_at(screen_pos: Vector2) -> int:
	var p := get_global_transform_with_canvas().affine_inverse() * screen_pos
	var y0 := 12 if title != "" else 0
	if p.x < -width / 2.0 - 4 or p.x > width / 2.0 + 4:
		return -1
	var i := int(floor((p.y - y0) / row_h))
	return i if i >= 0 and i < items.size() else -1


func _enabled(i: int) -> bool:
	return not items[i].get("disabled", false)


func _move(d: int) -> void:
	for n in items.size():
		sel = (sel + d + items.size()) % items.size()
		if _enabled(sel):
			break
	Audio.play("move", 0.0)


func _change(d: int) -> void:
	var it: Dictionary = items[sel]
	if it.has("change"):
		it.change.call(d)
		Audio.play("move", 0.0)


func _activate() -> void:
	var it: Dictionary = items[sel]
	if not _enabled(sel):
		Audio.play("wrong", 0.0)
		return
	if it.has("change") and not it.has("on"):
		it.change.call(1)
		Audio.play("move", 0.0)
	elif it.has("on"):
		Audio.play("select", 0.0)
		it.on.call()


func _draw() -> void:
	var y := 0
	if title != "":
		Px.text_c(self, title, 0, 0, Px.C.gold)
		y = 12
	for i in items.size():
		var it: Dictionary = items[i]
		var s: String = it.text
		if it.has("value"):
			s = "%s  < %s >" % [s, it.value.call()]
		var c: Color = Px.C.white if i == sel else Px.C.steel
		if not _enabled(i):
			c = Px.C.slate
		if i == sel and active:
			draw_rect(Rect2(-width / 2.0, y - 1, width, row_h - 1), Px.C.plum)
			if int(_blink * 3.0) % 2 == 0:
				Px.text(self, ">", Vector2(-width / 2.0 + 2, y + 1), Px.C.gold)
		if center:
			Px.text_c(self, s, 0, y + 1, c)
		else:
			Px.text(self, s, Vector2(-width / 2.0 + 10, y + 1), c)
		y += row_h
