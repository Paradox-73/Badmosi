extends Node2D
## Save slots, for NEW GAME (pick a slot, overwrite asks first) and LOAD GAME.
## Args: mode "new" or "load", difficulty, speedrun.

var mode := "load"
var difficulty := 1
var speedrun := false
var menu: MenuList
var sub: MenuList  # the confirm or slot-actions menu, while open
var t := 0.0


func setup(args: Dictionary) -> void:
	mode = args.get("mode", "load")
	difficulty = int(args.get("difficulty", 1))
	speedrun = bool(args.get("speedrun", false))


func _ready() -> void:
	Audio.play_music("title")
	_build()


func _build() -> void:
	var keep := menu.sel if menu else 0
	if menu:
		menu.queue_free()
	var items := []
	for n in range(1, Game.SLOTS + 1):
		items.append({"text": row_text(n), "on": _pick.bind(n),
			"disabled": mode == "load" and not Game.slot_used(n)})
	menu = MenuList.new(items, 330)
	menu.center = false
	menu.title = "NEW GAME: PICK A SLOT" if mode == "new" else "LOAD GAME"
	menu.position = Vector2(Px.W / 2.0, 80)
	menu.sel = keep
	if items[keep].disabled:
		menu._move(1)
	menu.back.connect(func(): Game.goto("menu"))
	add_child(menu)


## One slot as a line: name, club cards, SEM, pixels and play time.
static func row_text(n: int) -> String:
	var d := Game.slot_data(n)
	if d.is_empty():
		return "%d  EMPTY" % n
	var who: String = Roster.get_char(str(d.get("character", "kanav"))).name
	return "%d  %-8s CARDS %d/%d  SEM %d  %d PX  %s" % [n, who.to_upper(),
		Clubs.ORDER.filter(func(id): return d.get("cards", {}).has(id)).size(), Clubs.ORDER.size(), int(d.get("sem", 1)),
		int(d.get("pixels", 0)), Game.clock(float(d.get("run_time", 0.0)))]


func _pick(n: int) -> void:
	if not Game.slot_used(n):
		_start(n)
	elif mode == "new":
		_ask("SLOT %d HAS A RUN" % n, [
			{"text": "CANCEL", "on": _close},
			{"text": "OVERWRITE", "on": _overwrite.bind(n)},
			{"text": "DELETE", "on": _ask_delete.bind(n)}])
	else:
		_ask("SLOT %d" % n, [
			{"text": "LOAD", "on": _load.bind(n)},
			{"text": "DELETE", "on": _ask_delete.bind(n)}])


func _ask_delete(n: int) -> void:
	_close()
	_ask("DELETE SLOT %d FOR GOOD?" % n, [
		{"text": "NO", "on": _close},
		{"text": "YES, DELETE", "on": _delete.bind(n)}])


func _delete(n: int) -> void:
	Game.delete_slot(n)
	_close()
	_build()


func _overwrite(n: int) -> void:
	Game.delete_slot(n)
	_start(n)


func _load(n: int) -> void:
	if Game.load_run(n):
		Game.goto("hub")


func _start(n: int) -> void:
	Game.slot = n
	Game.difficulty = difficulty
	Game.new_run()
	Game.speedrun = speedrun
	Game.goto("char_select")


func _ask(title: String, items: Array) -> void:
	menu.active = false
	sub = MenuList.new(items, 170)
	sub.title = title
	sub.position = Vector2(Px.W / 2.0, 140)
	sub.back.connect(_close)
	add_child(sub)


func _close() -> void:
	if sub:
		sub.queue_free()
		sub = null
	menu.active = true


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, Px.W, Px.H), Px.C.ink)
	preload("res://scripts/ui/title.gd").draw_skyline(self, t, 200)
	Px.text_c(self, "BADMOSI", Px.W / 2.0, 24, Px.C.gold, 24)
	Px.text_c(self, "J/ENTER: SELECT   K/ESC: BACK   ARROWS/WASD: MOVE", Px.W / 2.0, Px.H - 10, Px.C.slate)
