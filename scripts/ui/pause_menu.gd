extends CanvasLayer
## Pause: Resume, Assists, Options, Back to hub, Quit to title.

var menu: MenuList
var root: Node2D
var page := "main"


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Node2D.new()
	add_child(root)
	root.draw.connect(_draw_bg)
	menu = MenuList.new([], 200)
	menu.position = Vector2(Px.W / 2.0, 58)
	menu.back.connect(_on_back)
	root.add_child(menu)
	visible = false
	menu.active = false


func open() -> void:
	page = "main"
	_build()
	visible = true
	menu.active = true
	get_tree().paused = true
	Audio.play("select", 0.0)


func close() -> void:
	visible = false
	menu.active = false
	get_tree().paused = false


func _on_back() -> void:
	if page != "main":
		page = "main"
		_build()
	else:
		close()


func _build() -> void:
	menu.sel = 0
	var scr = Game.main.screen
	match page:
		"main":
			menu.title = "PAUSED"
			var items := [
				{"text": "RESUME", "on": close},
				{"text": "ASSISTS", "on": func(): page = "assists"; _build()},
				{"text": "OPTIONS", "on": func(): page = "options"; _build()},
			]
			if Game.main.screen_name in ["club", "ending"]:
				items.append({"text": "BACK TO HUB", "on": func(): close(); Game.goto("hub")})
			items.append({"text": "QUIT TO TITLE", "on": func(): close(); Game.goto("title")})
			menu.items = items
		"assists":
			menu.title = "ASSISTS (NO PENALTY)"
			var items2 := [
				{"text": "INVINCIBLE", "value": func(): return OptionsItems.onoff(Game.assist_invincible),
					"change": func(_d): Game.assist_invincible = not Game.assist_invincible},
				{"text": "DOUBLE DAMAGE", "value": func(): return OptionsItems.onoff(Game.assist_double),
					"change": func(_d): Game.assist_double = not Game.assist_double},
			]
			if scr and scr.has_method("skip_club"):
				items2.append({"text": "SKIP THIS CLUB", "on": func(): close(); scr.skip_club()})
			items2.append({"text": "BACK", "on": _on_back})
			menu.items = items2
		"options":
			menu.title = "OPTIONS"
			var items3: Array = OptionsItems.build(false)
			items3.append({"text": "BACK", "on": _on_back})
			menu.items = items3
	root.queue_redraw()


func _draw_bg() -> void:
	root.draw_rect(Rect2(0, 0, Px.W, Px.H), Color(Px.C.ink, 0.8))
	Px.panel(root, Rect2(Px.W / 2.0 - 112, 46, 224, 140), Px.C.night)
