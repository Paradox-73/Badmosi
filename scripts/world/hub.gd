extends Node2D
## The campus hub: a scrolling map of IIIT-B. Walk into a door to open its
## directory board, into a counter to buy food, into a sign to read it.
## Security guards walk the paths and fine anyone they catch.

var pausable := true
## One character per 16 px tile. x wall, @ main gate, j jogging track,
## p walkway, . paving, g grass, T tree, h hedge, F fountain, f football ground,
## k basketball, v volleyball, A R V I H B buildings, $ canteen, c Coffee Cove,
## t Truffles, y Juicy, ? door sign, n Aikyam volunteer. Doors are in BUILDINGS
## and FLAVOUR.
const MAP := [
	"xxxxxxxxxxxxxxxxxxxxxxxxxxx@xxxxxxxxxxxxxxxxxxxxxxxxxxxx",
	"xggggggggggggggggggggTg........tgggTggggggffffffffffffgx",
	"xggggggggjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjgffffffffffffgx",
	"xggTgggggjgggTggggggggggggggggggggggTgggjgffffffffffffgx",
	"xggggggggjggggggggggggggFFggggggggggggggj.5fffffffffffgx",
	"xggggggggjggggggggggggggFFggggggggggggTgjgffffffffffffgx",
	"xgggggTggjggggg?ggggnggggggggggggg?gggggjgffffffffffffgx",
	"xggggggggjggggggggggggggggggggggggggggggjgffffffffffffgx",
	"xggggggggjppppppppppppppppppppppppppppppjggggggggggggggx",
	"xgggTggggjhhhhhhhh.hhhhhh.hhhhhh.hhhhhhhjjjjjjjjjjjjjjjx",
	"xggggggggjgAAAAAAAmAAAAAA6AAAAAAcAAAAAAgpgg...........jx",
	"xjjjjjjjjjgAAAAAAAAAAAAAAAAAAAAAAAAAAAAgpgg.RRRR2RRRR.jx",
	"xjgggggggpgAAAAAAAAAAAAAAAAAAAAAAAAAAAAgpgg.RRRcRRRRR.jx",
	"xjgVVVVVgpgAAAAAA1AAAAAAAAAAAAAAAAAAAAAgpgg.RR.....RR.jx",
	"xjgVVVVV.p..............................pgg.RR.....RR.jx",
	"xjgVVVVV.ppppppppppppppppppppppjjjjjjjjjjjj.....4..bR.jx",
	"xjgVVVVV.ggg?ggggggggggggggggggjgkkkkkkkggj.RR.....RR.jx",
	"xjgggggggggggggggggggg?gggggTggjgkkkkkkkggj.RR.....RR.jx",
	"xjgIIIIIIIIIIIIIIIIIIIIIIIIIgggjgkkkkkkkggj.RRRRRRRRR.jx",
	"xjgIIIIIIIIIIIIIIIIIIIIIIIIIgTgjgvvvvvvvggj.RRRRRRRRR.jx",
	"xjgIIIIIIILIIIIIIIIIIIIIIIIIgggjgvvvvvvvggj...........jx",
	"xj.............................jgvvvvvvvggjjjjjjjjjjjjjx",
	"xjjjjjjjjjjjjjpppppppppppppppppjgTgggggggggggggggggggggx",
	"xggggggggggggj.................jgggggggggggggggggggggggx",
	"xggggggggggggj.HHHH7HHHGHHH....jyggggggggggggggggggTgggx",
	"xggggTgggggggj.3HHHHHHHHHHH....jgggggTgggggggggggggggggx",
	"xggggggggggggj.HHHHHHHHHHHH....jgggggggggggggggggggggggx",
	"xggggggggggggj.HHHHHHHH8HHH....jjjjjjjjjjjjjjjjjjgg?gggx",
	"xggggggggTgggj.HHHHH............................jggggggx",
	"xggggggggggggj.HHHHH............BBBMBBBBBBBBBB..jggggggx",
	"xggggg?ggggggj.HHHHH............BBBBB$BBBBBBBB..jgggTggx",
	"xggggggggggggj.9HHHH.....................BBBBB..jggggggx",
	"xggggggggggggj.HHHHH.....................BBBBB..jggggggx",
	"xgggTggggggggj.HHHHH.....................BBBBB..jggggggx",
	"xggggggggggggj.HHHHHHHHHHHHHHHBBBBBBBBBBBBBBBB..jggggggx",
	"xgggggggggTggj.HHHHHHHHHHHHHHHBBBBBBBBBBBBBBBB..jgTggggx",
	"xggggggggggggj.HHHHHHHHHHHHHHHBBBBBBBBBBBBBBBB..jggggggx",
	"xggggggggggggj..................................jggggggx",
	"xggggggggggggjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjggggggx",
	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
]
const BUILDINGS := {
	"1": {"name": "ARYABHATTA CLASSROOMS", "clubs": ["pioneers", "debsoc"]},
	"2": {"name": "RAMANUJAN CLASSROOMS", "clubs": ["quiz", "zense"]},
	"3": {"name": "MPH 8-BIT CORNER", "clubs": ["eightbit"]},
	"4": {"name": "THINKER'S STATUE", "clubs": ["chhaya"]},
	"5": {"name": "FOOTBALL GROUND (NIGHT)", "clubs": ["eclipse"]},
	"6": {"name": "ARYABHATTA RECEPTION", "clubs": ["admin"]},
	"7": {"name": "MPH SAC ROOM", "clubs": ["sac"]},
	"8": {"name": "MPH IMPULSE & VINCI ROOM", "clubs": ["impulse", "vinci"]},
	"9": {"name": "MPH SYMPHONY ROOM", "clubs": ["symphony"]},
	"M": {"name": "BHASKARA MESS", "clubs": ["food"]},
	"L": {"name": "LILAVATI", "clubs": ["film", "parvaaz"]},
}
## Doors and machines with one line to read and no club behind them.
const FLAVOUR := {
	"G": ["MPH GYM", "BENCH PRESS QUEUE: 14 SENIORS. COME BACK NEXT SEM."],
	"m": ["VENDING MACHINE", "OUT OF ORDER SINCE ORIENTATION. IT HUMS AT YOU."],
	"b": ["BADMINTON COURT", "SHUTTLES STUCK IN THE ROOF: 37. NOBODY HAS A LADDER."],
}
## Building colours by map character.
const WALLS := {"A": "tan", "R": "steel", "V": "olive", "I": "teal", "H": "slate", "B": "orange", "x": "brown"}
## Name labels: text, centre x and top y in tiles.
const LABELS := [
	["ARYABHATTA", 25.0, 12.1], ["RAMANUJAN", 48.5, 18.3], ["VISVESVARYA", 5.5, 13.3],
	["LILAVATI", 18.0, 18.6], ["MPH", 21.0, 25.3], ["BHASKARA", 38.0, 35.0],
	["FOOTBALL GROUND", 48.0, 1.2], ["BASKETBALL", 36.5, 16.2], ["VOLLEYBALL/TENNIS", 36.5, 20.2],
	["MAIN GATE", 27.5, 0.2], ["START HERE", 22.0, 0.2], ["CANTEEN", 37.5, 31.1],
	["COFFEE COVE", 32.5, 11.0], ["COFFEE COVE", 47.5, 13.1], ["TRUFFLES", 31.5, 0.2],
	["JUICY", 32.5, 23.2], ["GYM", 23.5, 23.3],
]
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
const RIDER := {"hair": "ink", "skin": "skin2", "cloth": "red", "shade": "maroon", "accent": "gold", "pants": "ink", "hat": "cap"}
const TRUFFLES_WAIT := 25.0   # seconds of campus time before the rider sets off
## Food stops by map character.
const SHOPS := {
	"$": {"title": "BHASKARA CANTEEN - OPEN TILL 2 AM", "who": "ANNA", "lines": ANNA_LINES, "menu": MENU,
		"look": {"hair": "ink", "skin": "skin3", "cloth": "white", "shade": "mist", "accent": "orange", "pants": "brown"}},
	"c": {"title": "COFFEE COVE", "who": "BARISTA",
		"look": {"hair": "brown", "skin": "skin1", "cloth": "brown", "shade": "dark", "accent": "white", "pants": "ink"},
		"lines": ["COLD COFFEE MAKES YOU FAST. ALLEGEDLY.", "FOAM ART TODAY: A PIXEL HEART.", "BROWNIE IS WARM. BROWNIE IS LIFE.",
			"SAME BEANS IN BOTH BLOCKS. DON'T TELL.", "RUSH HOUR IS WHEN CLASS ENDS."],
		"menu": [{"name": "COLD COFFEE", "price": 60, "desc": "+25% SPEED, NEXT CLUB"},
			{"name": "CAPPUCCINO", "price": 70, "desc": "-25% ATT. LOSS, NEXT CLUB"},
			{"name": "BROWNIE", "price": 40, "desc": "+30% ATTENDANCE"}]},
	"y": {"title": "JUICY - FRESH JUICE", "who": "JUICY BHAIYA",
		"look": {"hair": "ink", "skin": "skin3", "cloth": "orange", "shade": "brown", "accent": "lime", "pants": "navy"},
		"lines": ["FRESH JUICE! VERY FRESH. MOSTLY.", "WATERMELON TODAY. YESTERDAY ALSO.", "ICE IS FROM... SOMEWHERE. DRINK!",
			"ONE JUICE, ONE STRAW, NO REFUNDS."],
		"menu": [{"name": "JUICE", "price": 40, "desc": "+30% ATTENDANCE"}]},
	"t": {"title": "TRUFFLES - BURGERS TO THE GATE", "who": "TRUFFLES", "look": RIDER,
		"lines": ["DELIVERY TO THE MAIN GATE ONLY.", "RIDER LEAVES IN 25 SECONDS. MAYBE 26.", "EXTRA CHEESE IS NOT OPTIONAL."],
		"menu": [{"name": "ORDER", "price": 150, "desc": "FULL ATT., +25% DMG"}]},
}

var player: Player
var hud: Hud
var t := 0.0
var busy := false
var bump_cd := 0.0
var healed := false
var overlay: Node = null
var from := ""
var room: Room
var map_tex: ImageTexture
var rider: Walker = null
var kharab := false      # the last juice was bad; say so when the stall closes
var guards: Array[Guard] = []
var safe_t := 2.0        # no catches until this runs out


func setup(args: Dictionary) -> void:
	from = args.get("from", "")


func _ready() -> void:
	Game.practice = false
	y_sort_enabled = true
	room = HubRoom.new()
	room.grid.assign(MAP)
	room.visible = false
	add_child(room)
	map_tex = _bake()
	player = Player.new()
	player.room = room
	add_child(player)
	player.position = _spawn_pos()
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = MAP[0].length() * Px.TILE
	cam.limit_bottom = Px.TOP + MAP.size() * Px.TILE
	player.add_child(cam)
	_spawn_guards()
	hud = Hud.new()
	hud.mode = "hub"
	Game.main.ui.add_child(hud)
	Audio.play_music("hub")
	if Game.attendance <= 0.0:
		Game.attendance = 50.0
	_check_unlocks()


func _exit_tree() -> void:
	# The camera leaves its offset on the viewport; the next screen expects none.
	get_viewport().canvas_transform = Transform2D()


func _spawn_pos() -> Vector2:
	for k in BUILDINGS:
		if from in BUILDINGS[k].clubs:
			return _stand(_front(_find(k)))
	return _gate_pos()


func _gate_pos() -> Vector2:
	return _stand(_find("@") + Vector2i.DOWN)


## Feet position on a tile, with the collision box inside it.
func _stand(c: Vector2i) -> Vector2:
	return room.cell_center(c) + Vector2(0, 4)


## The walkable tile in front of a door.
func _front(c: Vector2i) -> Vector2i:
	for d in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
		if not room.is_solid(c + d):
			return c + d
	return c


func _find(ch: String) -> Vector2i:
	for y in MAP.size():
		var x: int = MAP[y].find(ch)
		if x >= 0:
			return Vector2i(x, y)
	return Vector2i(27, 1)


func _check_unlocks() -> void:
	if Game.cards.has("admin"):
		return
	if Clubs.all_beaten() and not Game.cards.has("sac") and from != "sac":
		_say([{"who": "8-BIT REPORTER", "text": "EVERY CLUB IS BEATEN! THE SAC IS WAITING IN THE SAC ROOM, MPH.", "look": Clubs.get_club("eightbit").look}])
	elif Game.cards.has("sac") and from == "sac":
		_say([{"who": "CLIPBOARD", "text": "THE ADMIN OFFICE IS OPEN. ARYABHATTA RECEPTION, BY THE FOUNTAIN LAWN. GOOD LUCK.", "look": Clubs.get_club("sac").head_look}])
	elif Game.card_count() == 0 and from == "":
		_say([{"who": Game.char_name(), "text": "THIRTEEN CLUBS. BEAT EVERY ONE AT ITS OWN GAME. WALK INTO A DOOR TO START.", "look": Game.pix_look()},
			{"who": "SECURITY", "text": "NO LOITERING ON THE PATHS, FRESHER. WE FINE.", "look": Guard.LOOK}])


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
	safe_t = 2.0


func _process(delta: float) -> void:
	t += delta
	bump_cd = maxf(0.0, bump_cd - delta)
	queue_redraw()
	if Game.truffles_t > 0.0:
		Game.truffles_t = maxf(0.0, Game.truffles_t - delta)
	if Game.truffles_t == 0.0 and rider == null:
		rider = Walker.new()
		rider.look = RIDER
		rider.cell = _find("@") + Vector2i.DOWN
		rider.position = _stand(rider.cell)
		add_child(rider)
	if busy:
		return
	safe_t = maxf(0.0, safe_t - delta)
	for gd in guards:
		gd.step(delta, player.position)
		if gd.stop_t <= 0.0 and safe_t <= 0.0 and gd.position.distance_to(player.position) < 10.0:
			_caught(gd)
			return
	if rider:
		_ride(delta)
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
	elif ch in SHOPS:
		_open_shop(ch)
	elif ch in FLAVOUR:
		_say([{"who": FLAVOUR[ch][0], "text": FLAVOUR[ch][1]}])
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


## 2 guards on HD, 3 on SD, 4 on 8-BIT, on path tiles far from the player.
func _spawn_guards() -> void:
	var pc := room.cell_of(player.position)
	var spots: Array[Vector2i] = []
	for y in MAP.size():
		for x in MAP[y].length():
			if MAP[y][x] in "jp" and absi(x - pc.x) + absi(y - pc.y) >= 15:
				spots.append(Vector2i(x, y))
	spots.shuffle()
	for i in [2, 3, 4][Game.difficulty]:
		var gd := Guard.new()
		gd.room = room
		gd.look = Guard.LOOK
		gd.cell = spots[i]
		gd.position = _stand(gd.cell)
		add_child(gd)
		guards.append(gd)


func _caught(gd: Guard) -> void:
	gd.stop_t = 3.0
	gd.chase_t = 0.0
	var paid := Game.fine(30)
	Game.tally("caught")
	Audio.play("whistle", 0.0)
	await _say([{"who": "SECURITY", "text": "ID CARD? ... LOITERING FINE: %d PX." % paid, "look": Guard.LOOK}])
	player.position = _gate_pos()
	Game.save_run()


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
	overlay = null
	_free()
	if kharab:
		kharab = false
		_say([{"who": Game.char_name(), "text": "PET KHARAB! THAT JUICE WAS NOT FRESH. -25% SPEED TILL THE NEXT CLUB.", "look": Game.pix_look()}])


func _open_canteen() -> void:
	_open_shop("$")


func _open_shop(k: String) -> void:
	busy = true
	player.input_enabled = false
	var shop: Dictionary = SHOPS[k]
	var bg := BoardBg.new()
	bg.shop = shop
	bg.note = "YOUR ORDER IS ON ITS WAY." if k == "t" and Game.truffles_t >= 0.0 else shop.lines.pick_random()
	var items := []
	for it in shop.menu:
		var item: Dictionary = it
		items.append({"text": "%-14s %4d PX  %s" % [item.name, item.price, item.desc], "on": func(): _buy(item, bg)})
	items.append({"text": "LEAVE", "on": _close_overlay})
	var m := MenuList.new(items, 330)
	m.title = shop.title
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
		"COLD COFFEE": Game.add_buff("speed")
		"CAPPUCCINO": Game.add_buff("guard")
		"BROWNIE", "JUICE": Game.heal(30)
		"ORDER":
			if Game.truffles_t >= 0.0:
				bg.note = "ONE ORDER AT A TIME. IT IS ON ITS WAY."
				Audio.play("wrong", 0.0)
				return
			Game.truffles_t = TRUFFLES_WAIT
	Game.add_pixels(-int(item.price))
	Audio.play("buy", 0.0)
	bg.note = bg.shop.lines.pick_random()
	if item.name == "ORDER":
		bg.note = "ORDER PLACED. THE RIDER LEAVES IN 25 S."
	elif item.name == "JUICE" and randf() < 0.35:
		kharab = true
		Game.add_buff("upset")
		Game.tally("juicy")
	Game.save_run()


## The Truffles rider walks from the gate to the player, one tile at a time.
func _ride(delta: float) -> void:
	var to := _stand(rider.cell)
	rider.position = rider.position.move_toward(to, 100.0 * delta)
	rider.anim += delta
	rider.moving = true
	if rider.position.distance_to(player.position) < 12.0:
		rider.queue_free()
		rider = null
		Game.truffles_t = -1.0
		Game.heal(100)
		Game.add_buff("power")
		Game.tally("truffles")
		Game.save_run()
		Audio.play("buy", 0.0)
		_say([{"who": "TRUFFLES RIDER", "text": "ORDER FOR %s! ONE BURGER, EXTRA CHEESE. FULL ATTENDANCE, +25%% DAMAGE TILL THE NEXT CLUB." % Game.char_name(), "look": RIDER}])
	elif rider.position == to:
		rider.cell = _step_toward(rider.cell, room.cell_of(player.position))


## The next tile on a shortest walk from a to b, or a if b can't be reached.
func _step_toward(a: Vector2i, b: Vector2i) -> Vector2i:
	var prev := {a: a}
	var q: Array[Vector2i] = [a]
	var i := 0
	while i < q.size() and not prev.has(b):
		var c := q[i]
		i += 1
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if not prev.has(n) and not room.is_solid(n):
				prev[n] = c
				q.append(n)
	if not prev.has(b):
		return a
	var step := b
	while prev[step] != a:
		step = prev[step]
	return step


# ---------------------------------------------------------------- drawing

## Paints the ground, buildings and props once. Only moving things are drawn per frame.
func _bake() -> ImageTexture:
	var im := Image.create_empty(MAP[0].length() * 16, MAP.size() * 16, false, Image.FORMAT_RGBA8)
	var grass := Px.tile_tex("grass", {}).get_image()
	var path := Px.tile_tex("path", {}).get_image()
	var paving := Px.tile_tex("floor", {"floor": Px.C.grey.lerp(Px.C.sand, 0.45)}).get_image()
	var track: Color = Px.C.orange.lerp(Px.C.sand, 0.35)
	var full := Rect2i(0, 0, 16, 16)
	for y in MAP.size():
		for x in MAP[y].length():
			var ch: String = MAP[y][x]
			var p := Vector2i(x * 16, y * 16)
			im.blit_rect(grass if ch in "gT?nFfkv5" else (path if ch == "p" else paving), full, p)
			var wc := _wall_col(x, y)
			if ch in WALLS or ch in BUILDINGS or ch in FLAVOUR or ch in "$c":
				if ch != "4" and ch != "5":
					im.blit_rect(Px.tile_tex("wall", {"wall": wc}).get_image(), full, p)
			match ch:
				"j":
					im.fill_rect(Rect2i(p, Vector2i(16, 16)), track)
					for q in [Vector2i(3, 2), Vector2i(11, 6), Vector2i(6, 12), Vector2i(13, 13)]:
						im.set_pixelv(p + q, track.darkened(0.15))
				"h":
					im.fill_rect(Rect2i(p + Vector2i(0, 2), Vector2i(16, 13)), Px.C.jade)
					for q in [Vector2i(2, 4), Vector2i(9, 3), Vector2i(5, 8), Vector2i(12, 9), Vector2i(7, 12)]:
						im.set_pixelv(p + q, Px.C.green)
					im.fill_rect(Rect2i(p + Vector2i(0, 14), Vector2i(16, 1)), Px.C.dark)
				"@":
					im.fill_rect(Rect2i(p, Vector2i(16, 16)), Px.C.dark)
					for i in range(1, 16, 3):
						im.fill_rect(Rect2i(p + Vector2i(i, 0), Vector2i(1, 16)), Px.C.steel)
					im.fill_rect(Rect2i(p + Vector2i(0, 7), Vector2i(16, 1)), Px.C.steel)
				"T":
					_disc(im, p + Vector2i(8, 14), 4.5, Color(Px.C.dark, 0.35))
					im.fill_rect(Rect2i(p + Vector2i(7, 10), Vector2i(2, 5)), Px.C.brown)
					_disc(im, p + Vector2i(8, 7), 7.0, Px.C.jade)
					_disc(im, p + Vector2i(7, 6), 5.0, Px.C.green)
					for q in [Vector2i(5, 4), Vector2i(9, 5), Vector2i(6, 8)]:
						im.set_pixelv(p + q, Px.C.lime)
				"?":
					im.fill_rect(Rect2i(p + Vector2i(7, 8), Vector2i(2, 8)), Px.C.brown)
					im.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(12, 7)), Px.C.tan)
					im.fill_rect(Rect2i(p + Vector2i(4, 4), Vector2i(8, 1)), Px.C.brown)
					im.fill_rect(Rect2i(p + Vector2i(4, 6), Vector2i(6, 1)), Px.C.brown)
				"$", "c":
					im.blit_rect(Px.tile_tex("desk", {"floor": wc.darkened(0.3)}).get_image(), full, p)
					if ch == "c":
						im.fill_rect(Rect2i(p + Vector2i(6, 1), Vector2i(4, 4)), Px.C.white)
						im.fill_rect(Rect2i(p + Vector2i(7, 2), Vector2i(2, 1)), Px.C.brown)
				"m":
					im.fill_rect(Rect2i(p + Vector2i(3, 1), Vector2i(10, 15)), Px.C.red)
					im.fill_rect(Rect2i(p + Vector2i(5, 3), Vector2i(4, 8)), Px.C.cyan)
					im.fill_rect(Rect2i(p + Vector2i(10, 4), Vector2i(1, 3)), Px.C.gold)
				"t", "y":
					var aw: Color = Px.C.red if ch == "t" else Px.C.lime
					for i in 4:
						im.fill_rect(Rect2i(p + Vector2i(i * 4, 1), Vector2i(4, 5)), aw if i % 2 == 0 else Px.C.white)
					im.fill_rect(Rect2i(p + Vector2i(1, 6), Vector2i(14, 10)), Px.C.brown)
					im.fill_rect(Rect2i(p + Vector2i(1, 6), Vector2i(14, 2)), Px.C.tan)
					im.fill_rect(Rect2i(p + Vector2i(5, 10), Vector2i(6, 3)), Px.C.gold if ch == "t" else Px.C.orange)
				"4":
					im.fill_rect(Rect2i(p + Vector2i(2, 11), Vector2i(12, 5)), Px.C.grey.darkened(0.3))
					im.fill_rect(Rect2i(p + Vector2i(5, 3), Vector2i(6, 9)), Px.C.grey)
					im.fill_rect(Rect2i(p + Vector2i(6, 0), Vector2i(4, 4)), Px.C.grey.lightened(0.2))
					im.fill_rect(Rect2i(p + Vector2i(9, 3), Vector2i(2, 4)), Px.C.grey.darkened(0.2))
				_:
					if ch in WALLS and (x + y) % 2 == 0 and y % 3 != 2 and ch != "x":
						im.fill_rect(Rect2i(p + Vector2i(4, 4), Vector2i(8, 6)), Px.C.gold if (x * 3 + y) % 5 == 0 else Px.C.navy)
					elif ch in BUILDINGS or ch in FLAVOUR:
						im.blit_rect(Px.tile_tex("door", {"wall": wc}).get_image(), full, p)
	_ground(im, _box("f5"))
	_court(im, _box("k"), Px.C.orange.darkened(0.35), false)
	_court(im, _box("v"), Px.C.teal, true)
	var f := _box("F")
	_disc(im, f.get_center(), 15.0, Px.C.steel)
	_disc(im, f.get_center(), 13.0, Px.C.blue)
	_disc(im, f.get_center(), 4.0, Px.C.steel)
	_disc(im, f.get_center(), 2.0, Px.C.mist)
	var g := _find("5") * 16
	im.fill_rect(Rect2i(g + Vector2i(0, 2), Vector2i(3, 13)), Px.C.brown)
	for i in range(3, 15, 3):
		im.fill_rect(Rect2i(g + Vector2i(0, i), Vector2i(3, 1)), Px.C.tan)
	return ImageTexture.create_from_image(im)


## Colour of the building next to (or under) a tile.
func _wall_col(x: int, y: int) -> Color:
	for d in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var ch := room.at(Vector2i(x, y) + d)
		if ch in WALLS:
			return Px.col(WALLS[ch]).darkened(0.25)
	return Px.C.slate


## Pixel rectangle covering every tile of the given characters.
func _box(chars: String) -> Rect2i:
	var r := Rect2i()
	for y in MAP.size():
		for x in MAP[y].length():
			if MAP[y][x] in chars:
				var c := Rect2i(x * 16, y * 16, 16, 16)
				r = c if r.size == Vector2i.ZERO else r.merge(c)
	return r


func _disc(im: Image, c: Vector2i, r: float, col: Color) -> void:
	var n := ceili(r)
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var q := c + Vector2i(x, y)
			if x * x + y * y <= r * r and q.x >= 0 and q.y >= 0 and q.x < im.get_width() and q.y < im.get_height():
				if col.a < 1.0:
					im.set_pixelv(q, im.get_pixelv(q).blend(col))
				else:
					im.set_pixelv(q, col)


func _outline(im: Image, r: Rect2i, col: Color) -> void:
	im.fill_rect(Rect2i(r.position, Vector2i(r.size.x, 1)), col)
	im.fill_rect(Rect2i(r.position + Vector2i(0, r.size.y - 1), Vector2i(r.size.x, 1)), col)
	im.fill_rect(Rect2i(r.position, Vector2i(1, r.size.y)), col)
	im.fill_rect(Rect2i(r.position + Vector2i(r.size.x - 1, 0), Vector2i(1, r.size.y)), col)


func _ground(im: Image, r: Rect2i) -> void:
	for x in range(r.position.x, r.end.x, 8):
		im.fill_rect(Rect2i(x, r.position.y, 8, r.size.y), Px.C.green if (x >> 3) % 2 == 0 else Px.C.green.darkened(0.12))
	_outline(im, r, Px.C.grey)
	var inner := r.grow(-5)
	_outline(im, inner, Px.C.white)
	var c := inner.get_center()
	im.fill_rect(Rect2i(c.x, inner.position.y, 1, inner.size.y), Px.C.white)
	_disc(im, c, 12.0, Px.C.white)
	_disc(im, c, 11.0, Px.C.green.darkened(0.06))
	im.fill_rect(Rect2i(c.x - 24, c.y - 4, 48, 8), Px.C.sand)
	for side in [inner.position.x - 3, inner.end.x]:
		im.fill_rect(Rect2i(side, c.y - 8, 3, 16), Px.C.white)


func _court(im: Image, r: Rect2i, floor: Color, net: bool) -> void:
	im.fill_rect(r.grow(-1), floor)
	_outline(im, r.grow(-3), Px.C.white)
	var c := r.get_center()
	if net:
		im.fill_rect(Rect2i(c.x - 1, r.position.y + 1, 2, r.size.y - 2), Px.C.dark)
		im.fill_rect(Rect2i(c.x - 1, r.position.y + 1, 2, 1), Px.C.white)
	else:
		im.fill_rect(Rect2i(c.x, r.position.y + 3, 1, r.size.y - 6), Px.C.white)
		_disc(im, c, 6.0, Px.C.white)
		_disc(im, c, 5.0, floor)
		for hx in [r.position.x + 5, r.end.x - 7]:
			im.fill_rect(Rect2i(hx, c.y - 2, 2, 4), Px.C.red)


func _draw() -> void:
	draw_texture(map_tex, Vector2(0, Px.TOP))
	# Fountain spray.
	var fc := Vector2(_box("F").get_center()) + Vector2(0, Px.TOP)
	for i in 6:
		var a := t * 2.0 + i * TAU / 6.0
		draw_rect(Rect2((fc + Vector2(cos(a), sin(a)) * (6.0 + 3.0 * sin(t * 3.0 + i))).round(), Vector2.ONE), Px.C.white)
	var nc := _find("n")
	draw_texture(Px.char_tex(_aikyam(), "idle" if int(t * 2) % 2 == 0 else "walk1"), Vector2(nc.x * 16, Px.TOP + nc.y * 16))
	for l in LABELS:
		Px.text_c(self, l[0], l[1] * 16.0, Px.TOP + l[2] * 16.0, Px.C.white)
	Px.text_c(self, "ADMIN", 25.5 * 16, Px.TOP + 11.0 * 16, Px.C.red if not Game.cards.has("sac") else Px.C.lime)
	# Progress over each door.
	for k in BUILDINGS:
		var c := _find(k)
		var ids: Array = BUILDINGS[k].clubs
		var done := ids.filter(func(i): return Game.cards.has(i)).size()
		Px.text_c(self, "%d/%d" % [done, ids.size()], c.x * 16 + 8, Px.TOP + c.y * 16 - 9, Px.C.lime if done == ids.size() else Px.C.white)


class HubRoom extends Room:
	func is_solid(c: Vector2i) -> bool:
		var ch := at(c)
		return not (ch in [".", "p", "g", "j", "k", "v"])


## A person on the map who walks tile to tile: the Truffles rider and the guards.
class Walker extends Node2D:
	var look := {}
	var cell := Vector2i.ZERO
	var moving := false
	var anim := 0.0
	var mark := ""

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var tex := Px.char_tex(look, ("walk1" if int(anim * 8.0) % 2 == 0 else "walk2") if moving else "idle")
		draw_rect(Rect2(-5, -1, 10, 2), Color(Px.C.dark, 0.5))
		draw_texture(tex, Vector2(-8, -tex.get_height()))
		if mark != "":
			Px.text_c(self, mark, 0, -tex.get_height() - 9, Px.C.red)


## Campus security. Walks the paths like a Pac-Man ghost: a random turn at each
## junction, never back the way it came unless the path ends there. Chases a
## player it sees on the path within 5 tiles.
class Guard extends Walker:
	const LOOK := {"hair": "ink", "skin": "skin2", "cloth": "navy", "shade": "ink", "accent": "steel", "pants": "ink", "hat": "cap"}
	const DIRS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var room: Room
	var dir := Vector2i.ZERO
	var goal := Vector2i.ZERO   # where the player was last seen
	var chase_t := 0.0
	var stop_t := 0.0

	func step(delta: float, p: Vector2) -> void:
		moving = stop_t <= 0.0
		if stop_t > 0.0:
			stop_t -= delta
			mark = ""
			return
		anim += delta
		var pc := room.cell_of(p)
		if _sees(pc):
			chase_t = 2.0
			goal = pc
			if Vector2(goal - cell).dot(Vector2(dir)) < 0.0:
				cell += dir   # turn around on the spot
				dir = -dir
		chase_t = maxf(0.0, chase_t - delta)
		mark = "!" if chase_t > 0.0 else ""
		var to := room.cell_center(cell + dir) + Vector2(0, 4)
		position = position.move_toward(to, Player.SPEED * (0.85 if chase_t > 0.0 else 0.5) * delta)
		if position == to:
			cell += dir
			dir = _turn()

	func _path(c: Vector2i) -> bool:
		return room.at(c) in ["j", "p"]

	## True if the player stands on the path in a straight line, 5 tiles or closer.
	func _sees(pc: Vector2i) -> bool:
		var d := pc - cell
		if (d.x != 0 and d.y != 0) or absi(d.x + d.y) > 5:
			return false
		var s := Vector2i(signi(d.x), signi(d.y))
		for i in absi(d.x + d.y) + 1:
			if not _path(cell + s * i):
				return false
		return true

	func _turn() -> Vector2i:
		var opts := DIRS.filter(func(d): return d != -dir and _path(cell + d))
		if opts.is_empty():
			return -dir
		if chase_t > 0.0:
			opts.sort_custom(func(a, b): return (cell + a - goal).length_squared() < (cell + b - goal).length_squared())
			return opts[0]
		return opts.pick_random()


class BoardBg extends Node2D:
	var note := ""
	var shop := {}
	var tt := 0.0

	func _ready() -> void:
		z_index = 60

	func _process(delta: float) -> void:
		tt += delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, Px.W, Px.H), Color(Px.C.ink, 0.75))
		Px.panel(self, Rect2(12, 50, Px.W - 24, 150), Px.C.night, Px.C.gold)
		if not shop.is_empty():
			var tex := Px.char_tex(shop.look, "idle")
			draw_texture_rect(tex, Rect2(Vector2(20, 58 - tex.get_height() * 2), tex.get_size() * 2), false)
			Px.panel(self, Rect2(58, 28, Px.W - 76, 18), Px.C.ink, Px.C.mist)
			Px.text(self, shop.who + ": " + note, Vector2(64, 33), Px.C.white)
			Px.text(self, "YOUR PIXELS: %d    ATTENDANCE: %d%%    HYPE: %d" % [Game.pixels, roundi(Game.attendance), Game.hype], Vector2(24, 186), Px.C.gold)
		else:
			Px.text(self, "* = DIFFICULTY. WALK BACK OUT WITH K.", Vector2(24, 186), Px.C.steel)
