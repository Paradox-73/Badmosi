extends CanvasLayer
## Pause: Resume, Flip the table, Controls, Restart, Assists, Options, Back to hub,
## Quit to title.

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
	Audio.music.stream_paused = true
	Audio.play("select", 0.0)


func close() -> void:
	visible = false
	menu.active = false
	get_tree().paused = false
	Audio.music.stream_paused = false


func _on_back() -> void:
	if page != "main":
		page = "main"
		_build()
	else:
		close()


func _build() -> void:
	menu.sel = 0
	var scr = Game.main.screen
	var in_club: bool = Game.main.screen_name == "club"
	match page:
		"main":
			menu.title = "PAUSED"
			var items := [{"text": "RESUME", "on": close}]
			if in_club and scr.phase == "minigame" and scr.game and scr.game.can_flip():
				items.append({"text": "FLIP THE TABLE", "on": func(): close(); scr._flip_table()})
			items.append({"text": "CONTROLS", "on": func(): page = "controls"; _build()})
			if in_club:
				items.append({"text": "RESTART THIS CLUB", "on": func(): _confirm("RESTART THIS CLUB?", func(): close(); Game.goto("club", {"id": scr.id}))})
			items.append({"text": "ASSISTS", "on": func(): page = "assists"; _build()})
			items.append({"text": "OPTIONS", "on": func(): page = "options"; _build()})
			if Game.main.screen_name in ["club", "ending"]:
				items.append({"text": "BACK TO HUB", "on": func(): _confirm("LEAVE FOR THE HUB?", func(): close(); Game.goto("hub"))})
			items.append({"text": "QUIT TO TITLE", "on": func(): _confirm("QUIT TO THE TITLE?", func(): close(); Game.goto("title"))})
			menu.items = items
		"controls":
			menu.title = "CONTROLS"
			var rows: Array = []
			if in_club and scr.phase == "minigame" and scr.game:
				var inf: Dictionary = scr.game.info()
				for l in DialogueBox.wrap_text(inf.goal, 32):
					rows.append(l)
				rows.append_array(inf.get("keys", []))
				rows.append("HOLD F: FLIP THE TABLE")
			else:
				rows.append_array(["ARROWS/WASD: MOVE", "J: ATTACK, 3X FOR A COMBO", "K: DASH", "L: SPECIAL   I: SWITCH IT"])
				if Game.main.screen_name == "hub":
					rows.append_array(["L: PHONE, ORDER FOOD", "WALK INTO A DOOR TO ENTER"])
			var items4: Array = rows.map(func(r): return {"text": r, "disabled": true})
			items4.append({"text": "BACK", "on": _on_back})
			menu.items = items4
			menu.sel = items4.size() - 1
		"confirm":
			menu.title = _ask
			menu.items = [{"text": "NO", "on": _on_back}, {"text": "YES", "on": _yes}]
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


## Leaving or restarting loses the attempt, and the menu wraps from RESUME to
## QUIT in one press, so those ask first.
var _ask := ""
var _yes: Callable


func _confirm(question: String, action: Callable) -> void:
	_ask = question
	_yes = action
	page = "confirm"
	_build()


func _draw_bg() -> void:
	root.draw_rect(Rect2(0, 0, Px.W, Px.H), Color(Px.C.ink, 0.8))
	Px.panel(root, Rect2(Px.W / 2.0 - 112, 40, 224, 160), Px.C.night)
