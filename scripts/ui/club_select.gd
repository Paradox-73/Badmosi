extends Node2D
## Opens any club, the SAC or the Admin from the first launch, for practice and judging.

var menu: MenuList
var start_fight := false


func _ready() -> void:
	Audio.play_music("title")
	_build(0)


## Page 0: the thirteen clubs plus the SAC and Admin. Pages 1 and 2: the side
## clubs, split so every row fits on screen.
func _pages() -> Array:
	var half := ceili(Clubs.SIDE.size() / 2.0)
	return [Clubs.ORDER + ["sac", "admin"], Clubs.SIDE.slice(0, half), Clubs.SIDE.slice(half)]


func _build(page: int) -> void:
	if menu:
		menu.queue_free()
	var items := []
	var pages := _pages()
	for id in pages[page]:
		var d: Dictionary = Clubs.get_club(id)
		var cid: String = id
		items.append({"text": "%-15s %-20s %s" % [d.name, d.game_name, "*".repeat(int(d.stars))], "on": func(): _open(cid)})
	items.append({"text": "MODE", "value": func(): return "FIGHT FIRST" if start_fight else "MINIGAME FIRST",
		"change": func(_d): start_fight = not start_fight})
	var next := (page + 1) % pages.size()
	items.append({"text": "NEXT PAGE (%d/%d): %s" % [page + 1, pages.size(), "MAIN CLUBS" if next == 0 else "SIDE CLUBS"], "on": func(): _build.call_deferred(next)})
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
