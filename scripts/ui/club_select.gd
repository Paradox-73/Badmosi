extends Node2D
## Opens any club, the SAC or the Admin from the first launch, for practice and judging.

var menu: MenuList
var start_fight := false


func _ready() -> void:
	Audio.play_music("title")
	_build(false)


## Builds the list: the thirteen clubs plus the SAC and Admin, or the side
## clubs. Both lists do not fit on one screen.
func _build(side: bool) -> void:
	if menu:
		menu.queue_free()
	var items := []
	for id in (Clubs.SIDE if side else Clubs.ORDER + ["sac", "admin"]):
		var d: Dictionary = Clubs.get_club(id)
		var cid: String = id
		items.append({"text": "%-15s %-20s %s" % [d.name, d.game_name, "*".repeat(int(d.stars))], "on": func(): _open(cid)})
	items.append({"text": "MODE", "value": func(): return "FIGHT FIRST" if start_fight else "MINIGAME FIRST",
		"change": func(_d): start_fight = not start_fight})
	items.append({"text": "MAIN CLUBS" if side else "SIDE CLUBS AND COMMITTEES", "on": func(): _build.call_deferred(not side)})
	items.append({"text": "BACK", "on": func(): Game.goto("menu")})
	menu = MenuList.new(items, 330)
	menu.row_h = 10
	menu.center = false
	menu.position = Vector2(Px.W / 2.0, 26)
	menu.back.connect(func(): Game.goto("menu"))
	add_child(menu)


func _open(id: String) -> void:
	if not Game.practice:
		Game.new_run()
	Game.practice = true
	Game.attendance = 100.0
	Game.goto("club", {"id": id, "fight": start_fight})


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, Px.W, Px.H), Px.C.ink)
	Px.text_c(self, "CLUB SELECT - PRACTICE", Px.W / 2.0, 8, Px.C.gold)
	Px.text_c(self, "LEFT/RIGHT ON MODE: START IN THE FIGHT", Px.W / 2.0, Px.H - 12, Px.C.steel)
