extends Node2D
## The campus hub. Walk into a building door to open its directory board,
## into the counter for the canteen, into a sign to read it.

var pausable := true
const MAP := [
	"AAAAAAAAAA...RRRRRRRRRRR",
	"AAAAAAAAAA...RRRRRRRRRRR",
	"AAAA1AAA6A...RRRR2RRRRRR",
	"pppppppppppppppppppppppp",
	"gg?ggggggggpgggg?ggggggg",
	"ggggggggggp4pggggggggggg",
	"gg?gggggggpppgggggn?gggg",
	"pppppppppppppppppppppppp",
	"BBBB3BB$B..p...FFFF5FFFF",
	"BBBBBBBBB..p...FFFFFFFFF",
	"BBBBBBBBB..p...FFFFFFFFF",
	"BBBBBBBBB..@...FFFFFFFFF",
]
const BUILDINGS := {
	"1": {"name": "ARYABHATTA BLOCK", "clubs": ["pioneers", "eightbit", "vinci", "debsoc"]},
	"2": {"name": "RAMANUJAN BLOCK", "clubs": ["quiz", "film", "zense", "parvaaz"]},
	"3": {"name": "MPH & BHASKARA", "clubs": ["impulse", "symphony", "food", "sac"]},
	"4": {"name": "THINKER'S STATUE", "clubs": ["chhaya"]},
	"5": {"name": "PLAYGROUND (NIGHT)", "clubs": ["eclipse"]},
	"6": {"name": "ADMIN OFFICE", "clubs": ["admin"]},
}
const ANNA_LINES := [
	"CHAI? CHAI. ALWAYS CHAI.", "OPEN TILL 2 AM. SOMETIMES 3.", "NO CREDIT. ONLY PIXELS.",
	"YOU LOOK TIRED. FRESHER, NO?", "PUFF IS FRESH. FROM MORNING.", "DOSA TAKES TIME. LIKE GRADES.",
	"ADMIN CAME HERE ONCE. PAID BY FORM.", "SAMBAR REFILL IS FREE.", "EAT. THEN FIGHT.",
	"FILTER COFFEE: BEST HYPE.",
]
const MENU := [
	{"name": "CHAI", "price": 30, "desc": "+20% ATTENDANCE"},
	{"name": "VEG PUFF", "price": 60, "desc": "+40% ATTENDANCE"},
	{"name": "MASALA DOSA", "price": 120, "desc": "FULL ATTENDANCE"},
	{"name": "FILTER COFFEE", "price": 80, "desc": "FULL HYPE"},
	{"name": "PROXY SLIP", "price": 200, "desc": "+1 PROXY (MAX 3)"},
]

var player: Player
var hud: Hud
var t := 0.0
var busy := false
var bump_cd := 0.0
var healed := false
var overlay: Node = null
var from := ""
var room: Room


func setup(args: Dictionary) -> void:
	from = args.get("from", "")


func _ready() -> void:
	Game.practice = false
	room = HubRoom.new()
	room.grid.assign(MAP)
	room.visible = false
	add_child(room)
	player = Player.new()
	player.room = room
	add_child(player)
	player.position = _spawn_pos()
	hud = Hud.new()
	hud.mode = "hub"
	Game.main.ui.add_child(hud)
	Audio.play_music("hub")
	if Game.attendance <= 0.0:
		Game.attendance = 50.0
	_check_unlocks()


func _spawn_pos() -> Vector2:
	if from != "":
		for k in BUILDINGS:
			if from in BUILDINGS[k].clubs:
				var c := _find(k)
				return room.cell_center(c + Vector2i(0, 1 if c.y < 5 else -1)) + Vector2(0, 6)
	return room.cell_center(_find("@") + Vector2i(0, -1)) + Vector2(0, 6)


func _find(ch: String) -> Vector2i:
	for y in MAP.size():
		var x: int = MAP[y].find(ch)
		if x >= 0:
			return Vector2i(x, y)
	return Vector2i(11, 7)


func _check_unlocks() -> void:
	if Game.cards.has("admin"):
		return
	if Clubs.all_beaten() and not Game.cards.has("sac") and from != "sac":
		_say([{"who": "8-BIT REPORTER", "text": "EVERY CLUB IS BEATEN! THE SAC IS WAITING IN THE MPH.", "look": Clubs.get_club("eightbit").look}])
	elif Game.cards.has("sac") and from == "sac":
		_say([{"who": "CLIPBOARD", "text": "THE ADMIN OFFICE IS OPEN. NEXT TO ARYABHATTA BLOCK. GOOD LUCK.", "look": Clubs.get_club("sac").head_look}])
	elif Game.card_count() == 0 and from == "":
		_say([{"who": "PIX", "text": "THIRTEEN CLUBS. BEAT EVERY ONE AT ITS OWN GAME. WALK INTO A DOOR TO START.", "look": Player.PIX_LOOK}])


func _say(pages: Array) -> void:
	busy = true
	player.input_enabled = false
	var d := DialogueBox.new()
	d.pages = pages
	Game.main.ui.add_child(d)
	await d.finished
	_free()


func _free() -> void:
	busy = false
	player.input_enabled = true
	bump_cd = 0.4
	overlay = null


func _process(delta: float) -> void:
	t += delta
	bump_cd = maxf(0.0, bump_cd - delta)
	queue_redraw()
	if busy or bump_cd > 0.0:
		return
	var mv := Game.move_vec()
	if mv.length() < 0.3:
		return
	var probe := player.position + mv.normalized() * 8.0 + Vector2(0, -3)
	var c := room.cell_of(probe)
	var ch := room.at(c)
	if ch in BUILDINGS:
		_open_board(ch)
	elif ch == "$":
		_open_canteen()
	elif ch == "?":
		var idx := (c.x * 7 + c.y * 3) % Clubs.SIGNS.size()
		var s: Array = Clubs.SIGNS[idx]
		_say([{"who": s[0] + " (DOOR SIGN)", "text": s[1]}])
	elif ch == "n":
		if healed:
			_say([{"who": "AIKYAM VOLUNTEER", "text": "ALREADY PATCHED YOU UP. GO GET THEM!", "look": _aikyam()}])
		else:
			healed = true
			Game.heal(100)
			Audio.play("proxy", 0.0)
			_say([{"who": "AIKYAM VOLUNTEER", "text": "SOCIAL SERVICE! FREE CHECK-UP. ATTENDANCE BACK TO 100%.", "look": _aikyam()}])


func _aikyam() -> Dictionary:
	return {"hair": "ink", "skin": "skin3", "cloth": "lime", "shade": "green", "accent": "white", "pants": "navy"}


func _open_board(k: String) -> void:
	busy = true
	player.input_enabled = false
	var b: Dictionary = BUILDINGS[k]
	var items := []
	for id in b.clubs:
		var d: Dictionary = Clubs.get_club(id)
		var locked := false
		var mark := ""
		if id == "sac" and not Clubs.all_beaten():
			locked = true
			mark = " [LOCKED: BEAT ALL CLUBS]"
		if id == "admin" and not Game.cards.has("sac"):
			locked = true
			mark = " [LOCKED: BEAT THE SAC]"
		if Game.cards.has(id):
			mark = " [STRAIGHT]" if Game.cards[id] == "straight" else " [FLIPPED]"
		var stars := "*".repeat(int(d.stars))
		var club_id: String = id
		items.append({"text": "%s %s%s" % [d.name, stars, mark], "disabled": locked,
			"on": func(): Game.goto("club", {"id": club_id})})
	items.append({"text": "LEAVE", "on": _close_overlay})
	var m := MenuList.new(items, 300)
	m.title = b.name + " - DIRECTORY"
	m.center = false
	m.position = Vector2(Px.W / 2.0, 60)
	m.back.connect(_close_overlay)
	var bg := BoardBg.new()
	bg.add_child(m)
	Game.main.ui.add_child(bg)
	overlay = bg
	Audio.play("door", 0.0)


func _close_overlay() -> void:
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
	_free()


func _open_canteen() -> void:
	busy = true
	player.input_enabled = false
	var bg := BoardBg.new()
	bg.note = ANNA_LINES.pick_random()
	bg.canteen = true
	var items := []
	for it in MENU:
		var item: Dictionary = it
		items.append({"text": "%-14s %4d PX  %s" % [item.name, item.price, item.desc], "on": func(): _buy(item, bg)})
	items.append({"text": "LEAVE", "on": _close_overlay})
	var m := MenuList.new(items, 330)
	m.title = "BHASKARA CANTEEN - OPEN TILL 2 AM"
	m.center = false
	m.position = Vector2(Px.W / 2.0, 66)
	m.back.connect(_close_overlay)
	bg.add_child(m)
	Game.main.ui.add_child(bg)
	overlay = bg


func _buy(item: Dictionary, bg: BoardBg) -> void:
	if Game.pixels < int(item.price):
		bg.note = "NOT ENOUGH PIXELS, FRESHER."
		Audio.play("wrong", 0.0)
		return
	match item.name:
		"CHAI": Game.heal(20)
		"VEG PUFF": Game.heal(40)
		"MASALA DOSA": Game.heal(100)
		"FILTER COFFEE": Game.add_hype(10)
		"PROXY SLIP":
			if Game.proxies >= 3 or Game.difficulty == 2:
				bg.note = "PROXY SLIPS ARE SOLD OUT." if Game.difficulty == 2 else "YOU HAVE 3 ALREADY. GREEDY."
				Audio.play("wrong", 0.0)
				return
			Game.proxies += 1
	Game.add_pixels(-int(item.price))
	Audio.play("buy", 0.0)
	bg.note = ANNA_LINES.pick_random()
	Game.save_run()


func _draw() -> void:
	var pal := {"wall": Px.C.slate, "floor": Px.C.green}
	for y in MAP.size():
		for x in MAP[y].length():
			var ch: String = MAP[y][x]
			var p := Vector2(x * 16, Px.TOP + y * 16)
			match ch:
				"g", "n", "?":
					draw_texture(Px.tile_tex("grass", {}), p)
				"p", ".", "@":
					draw_texture(Px.tile_tex("path", {}), p)
				"A", "R", "B":
					var wc: Color = {"A": Px.C.tan, "R": Px.C.steel, "B": Px.C.orange}[ch].darkened(0.25)
					draw_texture(Px.tile_tex("wall", {"wall": wc}), p)
					if (x + y) % 2 == 0 and y % 3 != 2:
						draw_rect(Rect2(p + Vector2(4, 4), Vector2(8, 6)), Px.C.gold if (x * 3 + y + int(t)) % 5 == 0 else Px.C.navy)
				"F":
					draw_rect(Rect2(p, Vector2(16, 16)), Px.C.navy.darkened(0.4))
					if (x * 5 + y * 3) % 4 == 0:
						draw_rect(Rect2(p + Vector2((x * 7) % 12, (y * 5) % 12), Vector2.ONE), Px.C.white)
					if y == 8:
						draw_rect(Rect2(p + Vector2(0, 2), Vector2(16, 2)), Px.C.steel)
				"$":
					draw_texture(Px.tile_tex("wall", {"wall": Px.C.orange.darkened(0.25)}), p)
					draw_texture(Px.tile_tex("desk", {"floor": Px.C.orange.darkened(0.3)}), p)
				"4":
					draw_texture(Px.tile_tex("grass", {}), p)
				_:
					if ch in BUILDINGS:
						draw_texture(Px.tile_tex("door", {"wall2": Px.C.dark}), p)
	# Labels.
	Px.text(self, "ARYABHATTA", Vector2(4, Px.TOP + 4), Px.C.white)
	Px.text(self, "RAMANUJAN", Vector2(13 * 16 + 4, Px.TOP + 4), Px.C.white)
	Px.text(self, "MPH-BHASKARA", Vector2(4, Px.TOP + 9 * 16 + 4), Px.C.white)
	Px.text(self, "PLAYGROUND", Vector2(15 * 16 + 14, Px.TOP + 9 * 16 + 6), Px.C.mist)
	Px.text(self, "ADMIN", Vector2(8 * 16 - 6, Px.TOP + 16 + 6), Px.C.red if not Game.cards.has("sac") else Px.C.lime)
	Px.text(self, "CANTEEN", Vector2(6 * 16, Px.TOP + 8 * 16 - 9), Px.C.gold)
	# Thinker's Statue.
	var sp := Vector2(11 * 16, Px.TOP + 5 * 16)
	draw_rect(Rect2(sp + Vector2(2, 10), Vector2(12, 6)), Px.C.grey.darkened(0.3))
	draw_rect(Rect2(sp + Vector2(5, 1), Vector2(6, 10)), Px.C.grey)
	draw_rect(Rect2(sp + Vector2(6, -3), Vector2(4, 4)), Px.C.grey.lightened(0.2))
	draw_rect(Rect2(sp + Vector2(9, 1), Vector2(2, 4)), Px.C.grey.darkened(0.2))
	# Signs.
	for y in MAP.size():
		for x in MAP[y].length():
			var p2 := Vector2(x * 16, Px.TOP + y * 16)
			if MAP[y][x] == "?":
				draw_rect(Rect2(p2 + Vector2(7, 8), Vector2(2, 8)), Px.C.brown)
				draw_rect(Rect2(p2 + Vector2(2, 2), Vector2(12, 7)), Px.C.tan)
				draw_rect(Rect2(p2 + Vector2(4, 4), Vector2(8, 1)), Px.C.brown)
				draw_rect(Rect2(p2 + Vector2(4, 6), Vector2(6, 1)), Px.C.brown)
			elif MAP[y][x] == "n":
				var tx := Px.char_tex(_aikyam(), "idle" if int(t * 2) % 2 == 0 else "walk1")
				draw_texture(tx, p2)
	# Progress over each door.
	for k in BUILDINGS:
		var c := _find(k)
		var ids: Array = BUILDINGS[k].clubs
		var done := ids.filter(func(i): return Game.cards.has(i)).size()
		var s := "%d/%d" % [done, ids.size()]
		var y := Px.TOP + c.y * 16 + (18 if c.y < 5 else -10)
		Px.text_c(self, s, c.x * 16 + 8, y, Px.C.lime if done == ids.size() else Px.C.white)
	# Gate.
	Px.text_c(self, "MAIN GATE", 11 * 16 + 8, Px.H - 10, Px.C.mist)


class HubRoom extends Room:
	func is_solid(c: Vector2i) -> bool:
		var ch := at(c)
		return not (ch in [".", "p", "g", "@"])


class BoardBg extends Node2D:
	var note := ""
	var canteen := false
	var tt := 0.0

	func _ready() -> void:
		z_index = 60

	func _process(delta: float) -> void:
		tt += delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, Px.W, Px.H), Color(Px.C.ink, 0.75))
		Px.panel(self, Rect2(12, 50, Px.W - 24, 150), Px.C.night, Px.C.gold)
		if canteen:
			var anna := {"hair": "ink", "skin": "skin3", "cloth": "white", "shade": "mist", "accent": "orange", "pants": "brown"}
			var tex := Px.char_tex(anna, "idle")
			draw_texture_rect(tex, Rect2(Vector2(20, 26), tex.get_size() * 2), false)
			Px.panel(self, Rect2(58, 28, Px.W - 76, 18), Px.C.ink, Px.C.mist)
			Px.text(self, "ANNA: " + note, Vector2(64, 33), Px.C.white)
			Px.text(self, "YOUR PIXELS: %d    ATTENDANCE: %d%%    HYPE: %d" % [Game.pixels, roundi(Game.attendance), Game.hype], Vector2(24, 186), Px.C.gold)
		else:
			Px.text(self, "* = DIFFICULTY. WALK BACK OUT WITH K.", Vector2(24, 186), Px.C.steel)
