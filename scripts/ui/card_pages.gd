class_name CardPages
extends Node2D
## A sequence of full-screen cards (results, membership card, 8-Bit headline,
## SEM UP, DETAINED). Each page is a Callable(ci: Node2D, t: float).
## Attack or click advances. A page may offer a menu instead.

signal finished
signal chosen(idx: int)

var pages: Array = []
var idx := 0
var t := 0.0
var menu: MenuList = null
var choices: Array = []    # for the last page: Array of Strings


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 80
	_on_page()


func _on_page() -> void:
	t = 0.0
	if idx == pages.size() - 1 and not choices.is_empty():
		var items := []
		for i in choices.size():
			var k := i
			items.append({"text": choices[i], "on": func(): _choose(k)})
		menu = MenuList.new(items, 180)
		menu.position = Vector2(Px.W / 2.0, 150)
		add_child(menu)


func _choose(i: int) -> void:
	chosen.emit(i)
	queue_free()


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if Game.autoplay and t > 0.8:
		if menu:
			_choose(0)
		else:
			_next()
		return
	if menu:
		return
	if t > 0.5 and (Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("dodge")):
		_next()


func _unhandled_input(e: InputEvent) -> void:
	if menu == null and t > 0.5 and e is InputEventMouseButton and e.pressed:
		_next()
		get_viewport().set_input_as_handled()


func _next() -> void:
	idx += 1
	Audio.play("select", 0.0)
	if idx >= pages.size():
		finished.emit()
		queue_free()
		return
	_on_page()


func _draw() -> void:
	draw_rect(Rect2(0, 0, Px.W, Px.H), Color(Px.C.ink, 0.88))
	if idx < pages.size():
		pages[idx].call(self, t)
	if menu == null and t > 0.5 and int(t * 3.0) % 2 == 0:
		Px.text(self, "J >", Vector2(Px.W - 30, Px.H - 14), Px.C.gold)


# ------------------------------------------------------------ page builders

static func results_page(title: String, lines: Array, good := true) -> Callable:
	return func(ci: Node2D, t: float):
		Px.panel(ci, Rect2(60, 40, 264, 120), Px.C.night, Px.C.gold if good else Px.C.red)
		Px.text_c(ci, title, Px.W / 2.0, 50, Px.C.gold if good else Px.C.red, 16)
		for i in lines.size():
			if t > 0.25 + i * 0.2:
				Px.text_c(ci, lines[i], Px.W / 2.0, 80 + i * 12, Px.C.white)


static func card_page(club: String) -> Callable:
	return func(ci: Node2D, t: float):
		var d: Dictionary = Clubs.get_club(club)
		var k := clampf(t / 0.3, 0.0, 1.0)
		var w := roundf(160 * k)
		var r := Rect2(Px.W / 2.0 - w / 2.0, 52, w, 104)
		Px.panel(ci, r, Px.col(d.wall).darkened(0.3), Px.C.gold)
		if k < 1.0:
			return
		Px.text_c(ci, "MEMBERSHIP CARD", Px.W / 2.0, 58, Px.C.gold)
		var tex := Px.char_tex(d.head_look, "idle")
		ci.draw_texture_rect(tex, Rect2(r.position + Vector2(10, 22), tex.get_size() * 3), false)
		Px.text(ci, d.name, r.position + Vector2(64, 28), Px.C.white)
		Px.text(ci, "MEMBER: PIX", r.position + Vector2(64, 42), Px.C.mist)
		Px.text(ci, "SIGNED:", r.position + Vector2(64, 56), Px.C.mist)
		Px.text(ci, d.head, r.position + Vector2(64, 66), Px.C.gold)
		for i in 10:
			if (i * 7 + int(t * 10)) % 5 != 0:
				ci.draw_rect(Rect2(r.position + Vector2(64 + i * 8, 84), Vector2(6, 6)), Px.C.gold)
		Px.text_c(ci, "CARDS: %d / %d" % [Game.club_card_count(), Clubs.ORDER.size()], Px.W / 2.0, 164, Px.C.white)


static func headline_page(text: String) -> Callable:
	return func(ci: Node2D, t: float):
		var r := Rect2(56, 28, 272, 160)
		ci.draw_rect(r, Px.C.dark)
		ci.draw_rect(r.grow(-1), Px.C.sand)
		Px.text_c(ci, "8-BIT", Px.W / 2.0, 34, Px.C.dark, 16, false)
		ci.draw_rect(Rect2(64, 52, 256, 1), Px.C.dark)
		Px.text_c(ci, "THE STUDENT MAGAZINE   EXTRA!", Px.W / 2.0, 55, Px.C.brown, 8, false)
		ci.draw_rect(Rect2(64, 65, 256, 1), Px.C.dark)
		var lines := DialogueBox.wrap_text(text, 20)
		for i in lines.size():
			Px.text_c(ci, lines[i], Px.W / 2.0, 72 + i * 18, Px.C.dark, 16, false)
		var tex := Px.char_tex(Player.PIX_LOOK, "idle")
		ci.draw_texture_rect(tex, Rect2(Vector2(72, 140), tex.get_size() * 2), false)
		for i in 5:
			ci.draw_rect(Rect2(110, 142 + i * 8, 200 - (i % 3) * 30, 3), Px.C.tan)


static func censor(ci: Node2D, pos: Vector2, chars: int, t: float, size := 8) -> void:
	var cols := [Px.C.pink, Px.C.violet, Px.C.gold, Px.C.cyan, Px.C.red]
	var b := 3 * (size / 8)
	for i in chars * 2:
		for j in 3:
			ci.draw_rect(Rect2(pos + Vector2(i * b, j * b), Vector2(b, b)), cols[(i * 3 + j + int(t * 8)) % cols.size()])
