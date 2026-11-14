extends Node2D
## Options: volumes, difficulty, rhythm offset, clean text, shake, flashing, fullscreen, controls.

var menu: MenuList


func _ready() -> void:
	var items: Array = OptionsItems.build(true)
	items.append({"text": "BACK", "on": _back})
	menu = MenuList.new(items, 240)
	menu.position = Vector2(Px.W / 2.0, 34)
	menu.back.connect(_back)
	add_child(menu)


func _back() -> void:
	Game.save_options()
	Game.goto("menu")


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, Px.W, Px.H), Px.C.ink)
	Px.text_c(self, "OPTIONS", Px.W / 2.0, 10, Px.C.gold, 16)
	var controls := [
		"MOVE: WASD / ARROWS   ATTACK, CONFIRM: J / Z / ENTER",
		"DODGE, BACK: K / X   SPECIAL: L / C   SWITCH: I / V",
		"HOLD F: FLIP THE TABLE   PAUSE: ESC   FULLSCREEN: F11",
	]
	for i in controls.size():
		Px.text_c(self, controls[i], Px.W / 2.0, 174 + i * 10, Px.C.steel)
