extends Node2D
## The campus hub: a scrolling map of IIIT-B. Walk into a door to open its
## directory board, into a counter to buy food, into a sign to read it.
## Security guards walk the paths and fine anyone they catch.

var pausable := true
## One character per 16 px tile. x wall, @ main gate, j jogging track,
## p walkway, . paving, g grass, T tree, h hedge, F fountain, f football ground,
## k basketball, v volleyball/tennis, A R H B buildings, V I hostels, $ canteen,
## c Coffee Cove, o koi pond, O waterfall, U the big tree, W room V121,
## ? door sign, n Aikyam volunteer. Doors are in BUILDINGS and FLAVOUR.
## Laid out after the campus Keep Fit board: the jogging track is its 1 km loop.
const MAP := [
	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx@xxxxxxxxxxxxxxxxxxx",
	"xgggggggggjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjggTgggTgggTgggTgggx",
	"xgggggggggjggggggggggggggggggggTggggggggjgffffffffffffffffTx",
	"xgggggggggjggTggggggggggggggggggggggTgggjgffffffffffffffffgx",
	"xgggggggggjgggggggggggggFFggggggggggggggjgffffffffffffffffgx",
	"xgggggggggjgggggggggggggFFggggggggggggggjgffffffffffffffffTx",
	"xgggggggggjgggggggnggggggggggg?gggggggggj5ffffffffffffffffgx",
	"ZgggggggggjgggggggggTgggggggggggggggggggjgffffffffffffffffgx",
	"xgggggggggjgggggggggggggggggggggggggggggjgffffffffffffffffgx",
	"xgggggggggjpppppppppppppppppppppppppppppjgffffffffffffffffTx",
	"xgggggggggjhhhhhhh.hhhhhh.hhhhhh.hhhhhhpjgffffffffffffffffgx",
	"xgggggg?ggjgAAAAAAmAAAAAA6AAAAAAAAAAAAApjggggggggggggggggggx",
	"xgjjjjjjjjjgAAAAAAAAAAAAAAAAAAAAAAAAAAApjjjjjjjjjjjjjjjjjggx",
	"xgj.......ggAAAAAAAAAAAAAAAAAAAAAAAAAAApj....4..........jggx",
	"xgj.VVVVV.ggAAAAAAAAAAAAAAAAAAAAAAAAAAApj.RRRRRR2RRRRRR.jggx",
	"xgj.VVVVV.ggAAAAAAAA1AAAAAAAAAAcAAAAAAApj.RRRRRRRRRRRRR.jggx",
	"xgj.VVVVV.gpppppppppppppppppppppppppppppj.RRRRRRRRRRRRR.jggx",
	"xgj.VVVVW.pppppppppppppppppppppjjjjjjjjgj.RRRRRRRRRRRRR.jggx",
	"xgj.VVVVV.pgTgggggOooooooooUUTgjkkkkkkkgj.cRRRRRRRRRRRR.jggx",
	"xgj.VVVVV.pgggTgggOooooooooUUggjKkkkkkkgj.RRRRRRRRRRRRb.jggx",
	"xgj.VVVVV.pppppppppppppppppppppjkkkkkkkgj.RRRRRRRRRRRRR.jggx",
	"xgjgIIIIIIIIIIIILIIIIIIIIIIIgggjkkkkkkkgj.RRRRRRRRRRRRR.jggx",
	"xgjgIIIIIIIIIIIIIIIIIIIIIIIIgggjvvvvvvvgj.RRRRRRRRRRRRR.jggx",
	"xgjgIIIIIIIIIIIIIIIIIIIIIIIIgggjYvvvvvvgj.RRRRRRRRRRRRR.jggx",
	"xgjjjjjjjjjjjjjjgggggggggggggggjvvvvvvvgj.RRRRRR0RRRRRR.jggx",
	"xggzggggzggggzgj...............jvvvvvvvgj...............jggx",
	"xgggqqqqqqqqqggj...............j.......gjjjjjjjjjjjjjjjjjggx",
	"xgggqqqqqqqqqggj........T......j...?...g........gggggggggggx",
	"xgggqqqqqqqqqggj...............j.......g........gggg?ggggggx",
	"xggzgggggggggzgj...............jjjjjjjjjjjjjjjjjjggggggggggx",
	"xggggggggggggggjHHHHHHHHHHHHH...BBBBBBBBBBBBBBBgjggggggggggx",
	"xggggggggggggggjHHHHHHHHHHHHH...BBBBBBBBBBBBBBBgjggggggggggx",
	"xggggggggggggggjHHHHHHH3HHH7H...BBBBBMBBuBBBBBBgjggggggggggx",
	"xggggggggTgggggjHHHHH.....................BBBBBgjgggTggggggx",
	"xggggggggggggggjHHHHH.....................BBBBBgjggggggggggx",
	"xggggggggggggggjHHHHG.....................QBBBBgjggggggggggx",
	"xggggggggggggggjHHHHH.....................BBBBBgjggggggggggx",
	"xggggggggggggggjHHHHH.....................BBBBBgjggggggggggx",
	"xggggTgggggggggjHHHHHHH8HHH9HBBBBBBB$BBBBBBBBBBgjgggggggTggx",
	"xggggggggggggggjHHHHHHHHHHHHHBBBBBBBBBBBBBBBBBBgjggggggggggx",
	"xggggggggggggggjHHHHHHHHHHHHHBBBBBBBBBBBBBBBBBBgjggggggggggx",
	"xggggggggggggggjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjggggggggggx",
	"xggggggggggggggggggggggggggggggggggggggggggggggggggggggggggx",
	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
]
const BUILDINGS := {
	"1": {"name": "ARYABHATTA CLASSROOMS", "clubs": ["pioneers", "debsoc", "algo", "quantum", "mosfit", "ecell", "alfaaz", "chess"]},
	"2": {"name": "RAMANUJAN CLASSROOMS", "clubs": ["quiz", "zense", "gdsc", "genesys", "leanin", "squareone", "turiya", "sigchi"]},
	"0": {"name": "RAMANUJAN AUDITORIUM", "clubs": ["film", "parvaaz"]},
	"3": {"name": "MPH 8-BIT CORNER", "clubs": ["eightbit"]},
	"4": {"name": "THINKER'S STATUE (NIGHT SKY)", "clubs": ["eclipse"]},
	"5": {"name": "FOOTBALL & CRICKET GROUND", "clubs": ["sports"]},
	"6": {"name": "ARYABHATTA RECEPTION", "clubs": ["admin"]},
	"7": {"name": "MPH SAC ROOM", "clubs": ["sac"]},
	"8": {"name": "MPH IMPULSE & VINCI ROOM", "clubs": ["impulse", "vinci"]},
	"9": {"name": "MPH SYMPHONY ROOM", "clubs": ["symphony", "synergy"]},
	"M": {"name": "BHASKARA MESS", "clubs": ["food", "aikyam", "prayas"]},
	"O": {"name": "KOI POND WATERFALL", "clubs": ["chhaya"]},
	"K": {"name": "BASKETBALL COURT", "clubs": ["basketball"]},
	"Y": {"name": "VOLLEYBALL & TENNIS COURT", "clubs": ["volleyball", "tennis"]},
}
## Doors and machines with one line to read and no club behind them.
const FLAVOUR := {
	"G": ["SHAPE UP (MPH GYM)", "BENCH PRESS QUEUE: 14 SENIORS. COME BACK NEXT SEM."],
	"m": ["JUSTVEND MACHINE", "OPEN ALL DAY. EATS COINS ALL DAY TOO. IT HUMS AT YOU."],
	"b": ["BADMINTON & TT HALL", "SHUTTLES STUCK IN THE ROOF: 37. NOBODY HAS A LADDER."],
	"L": ["LILAVATI HOSTEL", "GIRLS' HOSTEL. NO CLUBS IN HERE. CALORIE BEE, THE GYM INSIDE, HAS NO QUEUE."],
	"Z": ["PANINI BRIDGE", "THE WALKWAY TO PANINI HOSTEL. THE ADMIN PUT A TURNSTILE ON IT."],
	"u": ["TUCK SHOP", "MAGGI, CHIPS, AND A PRINTER THAT WORKS ON TUESDAYS."],
	"Q": ["HEALTH CENTRE", "THE DOCTOR PRESCRIBES CROCIN. FOR EVERYTHING."],
	"U": ["THE BIG TREE", "EVERY BATCH HAS CARVED ITS NAME HERE. THE ADMIN FINED THE TREE."],
}
## Building colours by map character.
const WALLS := {"A": "tan", "R": "steel", "V": "olive", "I": "teal", "H": "slate", "B": "orange", "x": "brown"}
## Building fronts as in the campus brochure's photos: Aryabhatta off-white with
## sand-yellow panels, Ramanujan white with a mustard panel and black window
## slots, Visvesvaraya cream with pale-yellow panels, Lilavati mustard and cream,
## Bhaskara (and the MPH inside it) white with blue-and-white striped awnings.
const FACADE := {
	"A": {"base": Color("dcd8cc"), "panel": Color("e6cf98"), "win": Color("3b4a5a"), "kind": "panel"},
	"R": {"base": Color("ece9e1"), "panel": Color("d9a62e"), "win": Color("1b1b22"), "kind": "slot"},
	"V": {"base": Color("efe3c2"), "panel": Color("f2dc8a"), "win": Color("3b4a5a"), "kind": "panel"},
	"I": {"base": Color("efe3c2"), "panel": Color("d9a62e"), "win": Color("3b4a5a"), "kind": "band"},
	"H": {"base": Color("eeeeea"), "panel": Color("3a5fcf"), "win": Color("2b3445"), "kind": "awning"},
	"B": {"base": Color("eeeeea"), "panel": Color("3a5fcf"), "win": Color("2b3445"), "kind": "awning"},
}
## Name labels: text, centre x and top y in tiles.
const LABELS := [
	["ARYABHATTA", 25.5, 13.1], ["RAMANUJAN", 48.5, 19.3], ["VISVESVARAYA", 6.5, 13.4], ["(HOSTEL)", 6.5, 14.4],
	["LILAVATI HOSTEL", 16.0, 22.1], ["MPH", 22.5, 30.6], ["BHASKARA", 38.5, 30.6], ["COURTYARD", 31.5, 35.3],
	["FOOTBALL & CRICKET", 50.0, 3.0], ["BASKETBALL", 35.5, 18.1], ["VOLLEY/TENNIS", 35.5, 24.6],
	["MAIN GATE", 44.5, 0.25], ["START HERE", 33.0, 2.1], ["CANTEEN", 36.5, 37.1], ["MESS", 37.5, 32.6],
	["COFFEE COVE", 31.5, 16.6], ["COFFEE COVE", 42.0, 17.1], ["SHAPE UP GYM", 23.5, 35.6], ["AUDITORIUM", 48.5, 23.1],
	["KOI POND", 22.5, 16.6], ["V121", 9.0, 16.4], ["SPORTS", 41.5, 5.0],
	["THROWBALL", 8.5, 25.2], ["TUCK SHOP", 40.5, 33.1], ["HEALTH CENTRE", 39.0, 35.3], ["PANINI BRIDGE", 3.5, 6.0],
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
const JUICY_RIDER := {"hair": "ink", "skin": "skin3", "cloth": "orange", "shade": "brown", "accent": "lime", "pants": "navy", "hat": "cap"}
const ORDER_WAIT := 20.0   # seconds of campus time before the rider leaves the gate
## Food stops by map character, plus the phone ("P"), which orders food to wherever you are.
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
	"P": {"title": "PHONE - FOOD DELIVERY", "who": "PHONE", "look": RIDER,
		"lines": ["RIDER IS 2 MINS AWAY. HAS BEEN FOR 20 MINS.", "DELIVERY TO YOUR LIVE LOCATION. DON'T RUN.",
			"EXTRA CHEESE IS NOT OPTIONAL.", "JUICE: FRESH. MOSTLY.", "RATE YOUR LAST ORDER: * * * * *"],
		"menu": [{"name": "TRUFFLES", "price": 150, "desc": "BURGER: FULL ATT., +25% DMG"},
			{"name": "JUICY", "price": 40, "desc": "JUICE: +30% ATT. (RISKY)"}]},
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
var guards: Array[Guard] = []
var cats: Array[Cat] = []
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
	_spawn_cats()
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
	if from == "v121":
		return _stand(_front(_find("W")))
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
		rider.look = JUICY_RIDER if Game.order_item == "JUICY" else RIDER
		rider.cell = _find("@") + Vector2i.DOWN
		rider.position = _stand(rider.cell)
		add_child(rider)
	if busy:
		return
	_walk(delta)
	safe_t = maxf(0.0, safe_t - delta)
	for gd in guards:
		gd.step(delta, player.position)
		if gd.chase_t > 0.0:
			Audio.urge(0.5)
		if gd.stop_t <= 0.0 and safe_t <= 0.0 and gd.position.distance_to(player.position) < 10.0:
			_caught(gd)
			return
	if rider:
		_ride(delta)
	for cat in cats:
		if cat.pet_cd <= 0.0 and cat.position.distance_to(player.position) < 10.0:
			_pet(cat)
	if busy:
		return
	if Input.is_action_just_pressed("special"):
		_open_shop("P")
		return
	if Input.is_action_just_pressed("switch"):
		_open_map()
		return
	if bump_cd > 0.0:
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
	elif ch == "W":
		_room_v121()
	elif ch == "n":
		if healed:
			_say([{"who": "AIKYAM VOLUNTEER", "text": "ALREADY PATCHED YOU UP. GO GET THEM!", "look": _aikyam()}])
		else:
			healed = true
			Game.heal(100)
			Audio.play("proxy", 0.0)
			_say([{"who": "AIKYAM VOLUNTEER", "text": "SOCIAL SERVICE! FREE CHECK-UP. ATTENDANCE BACK TO 100%.", "look": _aikyam()}])


## The 16 numbered posts of the Keep Fit board, in loop order. Touch all of
## them and come back to post 1 for a lap. One lap is 1 km on the real board.
const POSTS := [Vector2i(40, 1), Vector2i(10, 1), Vector2i(10, 12), Vector2i(2, 12), Vector2i(2, 24),
	Vector2i(15, 24), Vector2i(15, 41), Vector2i(48, 41), Vector2i(48, 29), Vector2i(31, 29),
	Vector2i(31, 17), Vector2i(40, 17), Vector2i(40, 26), Vector2i(56, 26), Vector2i(56, 12), Vector2i(40, 12)]
const LAP_TILES := 240.0   # length of the loop in tiles
var posts_hit := {}
var _last_pos := Vector2.INF


## Counts metres walked and laps of the jogging track.
func _walk(_delta: float) -> void:
	var p := player.position
	if _last_pos != Vector2.INF and p.distance_to(_last_pos) < 40.0:
		Game.tallies["walk_m"] = float(Game.tallies.get("walk_m", 0.0)) + p.distance_to(_last_pos) * 1000.0 / (LAP_TILES * Px.TILE)
	_last_pos = p
	var c := room.cell_of(p)
	var i := -1
	for j in POSTS.size():
		var d: Vector2i = POSTS[j] - c
		if absi(d.x) <= 1 and absi(d.y) <= 1:   # a tile either side, so cutting the corner counts
			i = j
			break
	if i < 0:
		return
	if i == 0 and posts_hit.size() == POSTS.size():
		posts_hit.clear()
		Game.tally("laps")
		Game.add_pixels(25)
		Game.add_hype(3)
		Audio.play("semup", 0.0)
		Fx.word("LAP %d! +25 PX" % int(Game.tallies.laps), player.center() + Vector2(0, -18), Px.C.lime)
	posts_hit[i] = true


## Visvesvaraya V121: Badmosi's old room. A nap refills you once per club
## beaten; the photo on the wall replays the flashback.
func _room_v121() -> void:
	busy = true
	player.input_enabled = false
	var bg := BoardBg.new()
	var naps := int(Game.tallies.get("naps", 0))
	var can_nap := naps < Game.card_count() + 1
	var items := [
		{"text": "NAP ON THE BED   " + ("FULL ATTENDANCE, +5 HYPE" if can_nap else "NOT SLEEPY. BEAT A CLUB FIRST"), "disabled": not can_nap,
			"on": func():
				Game.tally("naps")
				Game.heal(100)
				Game.add_hype(5)
				Audio.play("proxy", 0.0)
				Game.save_run()
				_close_overlay()
				_say([{"who": Game.char_name(), "text": "BADMOSI'S BED. STILL SMELLS OF MAGGI AND REBELLION. FULLY RESTED.", "look": Game.pix_look()}])},
		{"text": "LOOK AT THE PHOTO ON THE WALL   (FLASHBACK)", "on": func(): Game.goto("flashback", {"back": "hub"})},
		{"text": "LEAVE", "on": _close_overlay},
	]
	var m := MenuList.new(items, 330)
	m.title = "VISVESVARAYA V121 - BADMOSI'S OLD ROOM"
	m.center = false
	m.position = Vector2(Px.W / 2.0, 66)
	m.back.connect(_close_overlay)
	bg.add_child(m)
	Game.main.ui.add_child(bg)
	overlay = bg
	Audio.play("door", 0.0)


func _spawn_cats() -> void:
	var spots: Array[Vector2i] = []
	for y in MAP.size():
		for x in MAP[y].length():
			if MAP[y][x] in ".g":
				spots.append(Vector2i(x, y))
	spots.shuffle()
	for i in 6:
		var cat := Cat.new()
		cat.room = room
		cat.kind = Cat.roll()
		cat.cell = spots[i]
		cat.position = room.cell_center(cat.cell) + Vector2(0, 4)
		cat.to = cat.position
		add_child(cat)
		cats.append(cat)


func _pet(cat: Cat) -> void:
	cat.pet_cd = 20.0
	cat.rest_t = 2.0
	var key: String = "cat_" + cat.kind[0]
	var new_kind := not Game.tallies.has(key)
	Game.tally(key)
	Game.tally("cats")
	Game.add_hype(1)
	Audio.play("select", 0.0)
	Fx.word("<3", cat.position + Vector2(0, -14), Px.C.pink)
	if cat.rare():
		Game.add_pixels(20)
	if cat.rare() or new_kind:
		var found := Cat.KINDS.filter(func(k): return Game.tallies.has("cat_" + k[0])).size()
		_say([{"who": cat.kind[0], "text": "%sMEOW. CAT DEX: %d/%d KINDS.%s" % ["RARE CAT! " if cat.rare() else "", found, Cat.KINDS.size(), " +20 PX" if cat.rare() else ""]}])
	Game.save_run()


## The whole campus at 4 px a tile, with you, the guards and every door.
func _open_map() -> void:
	busy = true
	player.input_enabled = false
	var m := CampusMap.new()
	m.hub = self
	Game.main.ui.add_child(m)
	overlay = m
	Audio.play("select", 0.0)
	await m.closed
	overlay = null
	_free()


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
	# Main clubs first: the SAC needs those. Side clubs are optional and free an ally.
	var ids: Array = b.clubs.filter(func(i): return not i in Clubs.SIDE) + b.clubs.filter(func(i): return i in Clubs.SIDE)
	for id in ids:
		var d: Dictionary = Clubs.get_club(id)
		var kind := "SIDE " if id in Clubs.SIDE else ("FINAL" if id in ["sac", "admin"] else "MAIN ")
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
		items.append({"text": "%s %s %s%s" % [kind, d.name, stars, mark], "disabled": locked,
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


func _open_shop(k: String) -> void:
	busy = true
	player.input_enabled = false
	var shop: Dictionary = SHOPS[k]
	var bg := BoardBg.new()
	bg.shop = shop
	bg.note = "%s IS ON ITS WAY." % Game.order_item if k == "P" and Game.truffles_t >= 0.0 else shop.lines.pick_random()
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
		"BROWNIE": Game.heal(30)
		"TRUFFLES", "JUICY":
			if Game.truffles_t >= 0.0:
				bg.note = "ONE ORDER AT A TIME. %s IS ON ITS WAY." % Game.order_item
				Audio.play("wrong", 0.0)
				return
			Game.truffles_t = ORDER_WAIT
			Game.order_item = item.name
	Game.add_pixels(-int(item.price))
	Audio.play("buy", 0.0)
	bg.note = bg.shop.lines.pick_random()
	if item.name in ["TRUFFLES", "JUICY"]:
		bg.note = "ORDER PLACED. THE RIDER LEAVES THE GATE IN %d S." % int(ORDER_WAIT)
	Game.save_run()


## The delivery rider walks from the main gate to the player, one tile at a time.
func _ride(delta: float) -> void:
	var to := _stand(rider.cell)
	rider.position = rider.position.move_toward(to, 100.0 * delta)
	rider.anim += delta
	rider.moving = true
	if rider.position.distance_to(player.position) < 12.0:
		rider.queue_free()
		rider = null
		Game.truffles_t = -1.0
		Audio.play("buy", 0.0)
		if Game.order_item == "JUICY":
			Game.heal(30)
			var pages := [{"who": "JUICY RIDER", "text": "JUICE FOR %s! FRESH. MOSTLY. +30%% ATTENDANCE." % Game.char_name(), "look": JUICY_RIDER}]
			if randf() < 0.35:
				Game.add_buff("upset")
				Game.tally("juicy")
				pages.append({"who": Game.char_name(), "text": "PET KHARAB! THAT JUICE WAS NOT FRESH. -25% SPEED TILL THE NEXT CLUB.", "look": Game.pix_look()})
			_say(pages)
		else:
			Game.heal(100)
			Game.add_buff("power")
			Game.tally("truffles")
			_say([{"who": "TRUFFLES RIDER", "text": "ORDER FOR %s! ONE BURGER, EXTRA CHEESE. FULL ATTENDANCE, +25%% DAMAGE TILL THE NEXT CLUB." % Game.char_name(), "look": RIDER}])
		Game.order_item = ""
		Game.save_run()
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
			im.blit_rect(grass if ch in "gT?nFfkv5oOUKYzqZ" else (path if ch == "p" else paving), full, p)
			var wc := _wall_col(x, y)
			if ch in WALLS or ch in BUILDINGS or ch in FLAVOUR or ch in "$cW":
				if ch in FACADE:
					_facade(im, p, ch, x, y)
				elif not ch in "45KYOUZ":
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
				"o":
					im.fill_rect(Rect2i(p, Vector2i(16, 16)), Px.C.blue.darkened(0.2))
					for q in [Vector2i(2, 3), Vector2i(9, 7), Vector2i(5, 12), Vector2i(12, 13)]:
						im.fill_rect(Rect2i(p + q, Vector2i(3, 1)), Px.C.blue.lightened(0.25))
					if room.at(Vector2i(x, y - 1)) != "o":
						im.fill_rect(Rect2i(p, Vector2i(16, 2)), Px.C.grey)
					if room.at(Vector2i(x, y + 1)) != "o":
						im.fill_rect(Rect2i(p + Vector2i(0, 14), Vector2i(16, 2)), Px.C.grey)
				"O":
					im.fill_rect(Rect2i(p + Vector2i(1, 0), Vector2i(14, 16)), Px.C.grey.darkened(0.25))
					for q in [Vector2i(2, 2), Vector2i(8, 5), Vector2i(3, 10), Vector2i(10, 12)]:
						im.fill_rect(Rect2i(p + q, Vector2i(4, 3)), Px.C.grey)
					im.fill_rect(Rect2i(p + Vector2i(12, 0), Vector2i(4, 16)), Px.C.cyan.lerp(Px.C.white, 0.3))
				"W":
					im.blit_rect(Px.tile_tex("door", {"wall": wc}).get_image(), full, p)
				"z":
					_disc(im, p + Vector2i(8, 14), 4.5, Color(Px.C.dark, 0.35))
					im.fill_rect(Rect2i(p + Vector2i(7, 10), Vector2i(2, 5)), Px.C.brown)
					_disc(im, p + Vector2i(8, 7), 7.0, Px.C.jade)
					var bloom: Color = Color("f2c53d") if x % 2 == 0 else Color("d43f9a")
					for q in [Vector2i(4, 4), Vector2i(9, 3), Vector2i(11, 7), Vector2i(6, 9), Vector2i(8, 6), Vector2i(3, 8), Vector2i(12, 10)]:
						im.set_pixelv(p + q, bloom)
				"Z":
					im.fill_rect(Rect2i(p + Vector2i(0, 4), Vector2i(16, 8)), Px.C.grey)
					for i in range(0, 16, 3):
						im.fill_rect(Rect2i(p + Vector2i(i, 4), Vector2i(1, 8)), Px.C.grey.darkened(0.3))
					im.fill_rect(Rect2i(p + Vector2i(0, 3), Vector2i(16, 1)), Px.C.white)
					im.fill_rect(Rect2i(p + Vector2i(0, 12), Vector2i(16, 1)), Px.C.white)
				"4":
					im.fill_rect(Rect2i(p + Vector2i(2, 11), Vector2i(12, 5)), Px.C.grey.darkened(0.3))
					im.fill_rect(Rect2i(p + Vector2i(5, 3), Vector2i(6, 9)), Px.C.grey)
					im.fill_rect(Rect2i(p + Vector2i(6, 0), Vector2i(4, 4)), Px.C.grey.lightened(0.2))
					im.fill_rect(Rect2i(p + Vector2i(9, 3), Vector2i(2, 4)), Px.C.grey.darkened(0.2))
				_:
					if ch in FACADE or ch == "x":
						pass
					elif ch in BUILDINGS or ch in FLAVOUR:
						im.blit_rect(Px.tile_tex("door", {"wall": wc}).get_image(), full, p)
	_ground(im, _box("f"))
	_court(im, _box("k"), Color("2f5fae"), false)
	_court(im, _box("v"), Color("27509a"), true)
	_court(im, _box("q"), Px.C.sand.darkened(0.2), true)
	# Stepping-stone slabs across the lawn to the waterfall.
	for q in [Vector2i(13, 18), Vector2i(15, 18), Vector2i(16, 19), Vector2i(17, 18)]:
		im.fill_rect(Rect2i(q * 16 + Vector2i(3, 4), Vector2i(10, 7)), Px.C.grey.lightened(0.2))
		im.fill_rect(Rect2i(q * 16 + Vector2i(3, 10), Vector2i(10, 1)), Px.C.grey.darkened(0.3))
	var f := _box("F")
	_disc(im, f.get_center(), 15.0, Px.C.steel)
	_disc(im, f.get_center(), 13.0, Px.C.blue)
	_disc(im, f.get_center(), 4.0, Px.C.steel)
	_disc(im, f.get_center(), 2.0, Px.C.mist)
	# The big tree by the koi pond: one canopy over its 2x2 tiles.
	var u := _box("U")
	_disc(im, u.get_center() + Vector2i(0, 12), 9.0, Color(Px.C.dark, 0.35))
	im.fill_rect(Rect2i(u.get_center() + Vector2i(-3, 0), Vector2i(6, 14)), Px.C.brown)
	_disc(im, u.get_center() + Vector2i(0, -4), 15.0, Px.C.jade.darkened(0.2))
	_disc(im, u.get_center() + Vector2i(-3, -6), 11.0, Px.C.jade)
	_disc(im, u.get_center() + Vector2i(4, -2), 8.0, Px.C.green)
	for q in [Vector2i(-6, -10), Vector2i(3, -8), Vector2i(-2, 0), Vector2i(7, -4)]:
		im.set_pixelv(u.get_center() + q, Px.C.lime)
	# Basketball hoop and the volleyball/tennis net post: the doors to those clubs.
	var k := _find("K") * 16
	im.fill_rect(Rect2i(k + Vector2i(6, 4), Vector2i(2, 12)), Px.C.grey)
	im.fill_rect(Rect2i(k + Vector2i(2, 0), Vector2i(10, 6)), Px.C.white)
	im.fill_rect(Rect2i(k + Vector2i(10, 4), Vector2i(5, 2)), Px.C.red)
	var yp := _find("Y") * 16
	im.fill_rect(Rect2i(yp + Vector2i(7, 0), Vector2i(2, 16)), Px.C.grey)
	im.fill_rect(Rect2i(yp + Vector2i(9, 2), Vector2i(7, 1)), Px.C.white)
	im.fill_rect(Rect2i(yp + Vector2i(4, 1), Vector2i(3, 3)), Px.C.gold)
	var g := _find("5") * 16
	im.fill_rect(Rect2i(g + Vector2i(0, 2), Vector2i(3, 13)), Px.C.brown)
	for i in range(3, 15, 3):
		im.fill_rect(Rect2i(g + Vector2i(0, i), Vector2i(3, 1)), Px.C.tan)
	return ImageTexture.create_from_image(im)


## Colour of the building next to (or under) a tile.
func _wall_col(x: int, y: int) -> Color:
	for d in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var ch := room.at(Vector2i(x, y) + d)
		if ch in FACADE:
			return FACADE[ch].base.darkened(0.3)
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


## A building tile in its real colours. The edge facing open ground gets a dark
## outline so the pale buildings still read against the paving.
func _facade(im: Image, p: Vector2i, ch: String, x: int, y: int) -> void:
	var f: Dictionary = FACADE[ch]
	var base: Color = f.base
	match f.kind:
		"panel":
			im.fill_rect(Rect2i(p, Vector2i(16, 16)), f.panel if (x / 2) % 3 == 0 else base)
			for q in [Vector2i(3, 5), Vector2i(10, 5)]:
				im.fill_rect(Rect2i(p + q, Vector2i(4, 5)), f.win)
		"slot":
			im.fill_rect(Rect2i(p, Vector2i(16, 16)), f.panel if x % 7 == 3 else base)
			for q in [Vector2i(3, 2), Vector2i(10, 2)]:
				im.fill_rect(Rect2i(p + q, Vector2i(2, 11)), f.win)
		"band":
			im.fill_rect(Rect2i(p, Vector2i(16, 16)), f.panel if y % 2 == 0 else base)
			for q in [Vector2i(3, 5), Vector2i(10, 5)]:
				im.fill_rect(Rect2i(p + q, Vector2i(4, 4)), f.win)
		"awning":
			im.fill_rect(Rect2i(p, Vector2i(16, 16)), base)
			for q in [Vector2i(3, 4), Vector2i(10, 4)]:
				im.fill_rect(Rect2i(p + q, Vector2i(3, 3)), f.win)
			if not room.is_solid(Vector2i(x, y + 1)):   # striped awning over open ground
				for i in 8:
					im.fill_rect(Rect2i(p + Vector2i(i * 2, 11), Vector2i(2, 4)), f.panel if i % 2 == 0 else Color.WHITE)
	var edge: Color = base.darkened(0.55)
	for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var n: Vector2i = Vector2i(x, y) + d
		if not _is_building(room.at(n)):
			var r: Rect2i = Rect2i(p + Vector2i(0 if d.x <= 0 else 15, 0 if d.y <= 0 else 15), Vector2i(16 if d.x == 0 else 1, 16 if d.y == 0 else 1))
			im.fill_rect(r, edge)


func _is_building(ch: String) -> bool:
	return ch in FACADE or ((ch in BUILDINGS or ch in FLAVOUR or ch in "$cW") and not ch in "45KYOUZ")


## The general-purpose field: bare red earth, worn paler in the middle, with
## goalposts at each end and a cricket pitch in the centre.
func _ground(im: Image, r: Rect2i) -> void:
	var earth := Color("a5573b")
	im.fill_rect(r, earth)
	for i in 220:
		var q := r.position + Vector2i((i * 37) % r.size.x, (i * 53) % r.size.y)
		im.set_pixelv(q, earth.darkened(0.15) if i % 3 else earth.lightened(0.12))
	var c := r.get_center()
	_disc(im, c, 22.0, Color(earth.lightened(0.1), 0.6))
	im.fill_rect(Rect2i(c.x - 22, c.y - 3, 44, 6), Px.C.sand.darkened(0.1))   # cricket pitch
	for sx in [c.x - 20, c.x + 18]:
		im.fill_rect(Rect2i(sx, c.y - 3, 2, 6), Px.C.white)                   # stumps
	for gx in [r.position.x + 2, r.end.x - 4]:
		im.fill_rect(Rect2i(gx, c.y - 12, 2, 24), Px.C.white)                 # goalposts
		im.fill_rect(Rect2i(gx - 4 if gx > c.x else gx, c.y - 12, 6, 1), Px.C.white)
		im.fill_rect(Rect2i(gx - 4 if gx > c.x else gx, c.y + 11, 6, 1), Px.C.white)


## An outdoor court: painted floor, lines, a net or hoops, wire netting around
## it and floodlight poles at the corners.
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
	for x in range(r.position.x, r.end.x, 2):
		im.set_pixel(x, r.position.y, Px.C.grey)
		im.set_pixel(x, r.end.y - 1, Px.C.grey)
	for y in range(r.position.y, r.end.y, 2):
		im.set_pixel(r.position.x, y, Px.C.grey)
		im.set_pixel(r.end.x - 1, y, Px.C.grey)
	for q in [r.position, Vector2i(r.end.x - 3, r.position.y)]:
		im.fill_rect(Rect2i(q, Vector2i(3, 3)), Px.C.gold)                   # floodlights


func _draw() -> void:
	draw_texture(map_tex, Vector2(0, Px.TOP))
	# Fountain spray.
	var fc := Vector2(_box("F").get_center()) + Vector2(0, Px.TOP)
	for i in 6:
		var a := t * 2.0 + i * TAU / 6.0
		draw_rect(Rect2((fc + Vector2(cos(a), sin(a)) * (6.0 + 3.0 * sin(t * 3.0 + i))).round(), Vector2.ONE), Px.C.white)
	# Koi in the pond, waterfall spray.
	var pond := _box("o")
	for i in 5:
		var run := t * (8.0 + i * 3.0) + i * 29.0
		var span := float(pond.size.x - 12)
		var fx := pond.position.x + 6 + pingpong(run, span)
		var fy := pond.position.y + 6 + (i * 5) % (pond.size.y - 12) + sin(t * 2.0 + i) * 2.0
		var left := fposmod(run, span * 2.0) > span   # swimming back
		var at := Vector2(roundf(fx), roundf(fy) + Px.TOP)
		draw_rect(Rect2(at, Vector2(3, 1)), Px.C.orange if i % 2 == 0 else Px.C.white)
		draw_rect(Rect2(at + Vector2(3 if left else -1, 0), Vector2.ONE), Px.C.red)
	var wf := _box("O")
	for i in 6:
		var wy := fposmod(t * 30.0 + i * 5.0, float(wf.size.y))
		draw_rect(Rect2(Vector2(wf.end.x - 3, wf.position.y + wy + Px.TOP), Vector2(1, 2)), Px.C.white)
	# The 16 Keep Fit posts; reached ones turn green until the lap closes.
	for i in POSTS.size():
		var pc: Vector2i = POSTS[i]
		Px.text_c(self, str(i + 1), pc.x * 16 + 8, Px.TOP + pc.y * 16 + 4, Px.C.lime if posts_hit.has(i) else Px.C.red)
	if Game.difficulty == 2:
		for gd in guards:
			for c in gd.cone():
				draw_rect(Rect2(c.x * 16, Px.TOP + c.y * 16, 16, 16), Color(Px.C.gold, 0.16))
	var nc := _find("n")
	draw_texture(Px.char_tex(_aikyam(), "idle" if int(t * 2) % 2 == 0 else "walk1"), Vector2(nc.x * 16, Px.TOP + nc.y * 16))
	for l in LABELS:
		Px.text_c(self, l[0], l[1] * 16.0, Px.TOP + l[2] * 16.0, Px.C.white)
	Px.text_c(self, "ADMIN", 25.5 * 16, Px.TOP + 9.4 * 16, Px.C.red if not Game.cards.has("sac") else Px.C.lime)
	# Progress over each door.
	for k in BUILDINGS:
		var c := _find(k)
		var ids: Array = BUILDINGS[k].clubs
		var done := ids.filter(func(i): return Game.cards.has(i)).size()
		Px.text_c(self, "%d/%d" % [done, ids.size()], c.x * 16 + 8, Px.TOP + c.y * 16 - 9, Px.C.lime if done == ids.size() else Px.C.white)


class HubRoom extends Room:
	func is_solid(c: Vector2i) -> bool:
		var ch := at(c)
		return not (ch in [".", "p", "g", "j", "k", "v", "q"])


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

	## On 8-BIT difficulty guards carry torches: they see a cone 5 tiles ahead,
	## off the path too, and the cone is drawn so the player can sneak round it.
	func cone() -> Array[Vector2i]:
		var out: Array[Vector2i] = []
		if dir == Vector2i.ZERO:
			return out
		var side := Vector2i(dir.y, dir.x)
		for a in range(1, 6):
			for b in range(-(a / 2), a / 2 + 1):
				var c: Vector2i = cell + dir * a + side * b
				if room.is_solid(c) or room.is_solid(cell + dir * a):
					continue
				out.append(c)
		return out

	## True if the player stands on the path in a straight line, 5 tiles or closer,
	## or anywhere in the torch cone on 8-BIT.
	func _sees(pc: Vector2i) -> bool:
		if Game.difficulty == 2 and pc in cone():
			return true
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
			Px.text(self, "MAIN: NEEDED FOR SAC. SIDE: BONUS ALLY. *: DIFFICULTY", Vector2(24, 186), Px.C.steel)


## Campus cats. They wander the lawns and paving; walk into one to pet it.
## Most are common; a few kinds are rare, and petting a new kind adds it to the
## cat dex shown on the report card.
class Cat extends Node2D:
	## name, body, patch, chance weight
	const KINDS := [
		["ORANGE TABBY", "orange", "tan", 30], ["BLACK CAT", "ink", "dark", 25], ["WHITE CAT", "white", "mist", 20],
		["GREY CAT", "steel", "slate", 15], ["CALICO", "white", "orange", 6], ["THE DEAN (TUXEDO)", "ink", "white", 3],
		["PIXEL CAT", "violet", "cyan", 1],
	]
	var room: Room
	var kind: Array
	var cell := Vector2i.ZERO
	var to := Vector2.ZERO
	var rest_t := 0.0
	var pet_cd := 0.0
	var tt := 0.0
	var face := 1

	static func roll() -> Array:
		var total := 0
		for k in KINDS:
			total += k[3]
		var r := randi() % total
		for k in KINDS:
			r -= k[3]
			if r < 0:
				return k
		return KINDS[0]

	func rare() -> bool:
		return kind[3] <= 6

	func _process(delta: float) -> void:
		tt += delta
		pet_cd = maxf(0.0, pet_cd - delta)
		queue_redraw()
		if rest_t > 0.0:
			rest_t -= delta
			return
		position = position.move_toward(to, 18.0 * delta)
		if position == to:
			rest_t = randf_range(0.5, 4.0)
			var opts := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].filter(
				func(d): return room.at(cell + d) in [".", "g", "p"])
			if not opts.is_empty():
				var d: Vector2i = opts.pick_random()
				cell += d
				if d.x != 0:
					face = d.x
				to = room.cell_center(cell) + Vector2(randf_range(-4, 4), 4)

	func _draw() -> void:
		var body: Color = Px.col(kind[1])
		var patch: Color = Px.col(kind[2])
		if kind[0] == "PIXEL CAT":
			body = Color.from_hsv(fmod(tt * 0.5, 1.0), 0.6, 1.0)
		var sit := rest_t > 0.0
		var f := face
		draw_rect(Rect2(-4, -1, 9, 1), Color(Px.C.dark, 0.4))
		draw_rect(Rect2(-4, -5 if not sit else -6, 7, 4 if not sit else 5), body)      # body
		draw_rect(Rect2(2 * f - (2 if f < 0 else 0), -8, 4, 4), body)                  # head
		draw_rect(Rect2(2 * f - (2 if f < 0 else 0), -9, 1, 1), body)                  # ears
		draw_rect(Rect2(2 * f + (1 if f < 0 else 3), -9, 1, 1), body)
		draw_rect(Rect2(3 * f + (0 if f > 0 else -1), -7, 1, 1), Px.C.lime)           # eye
		var tail_up := int(tt * 3.0) % 2
		draw_rect(Rect2(-5 * f - (1 if f > 0 else -3), -7 - tail_up, 1, 3), body)     # tail
		if kind[0] in ["CALICO", "ORANGE TABBY", "GREY CAT"]:
			draw_rect(Rect2(-2, -5, 2, 2), patch)
			draw_rect(Rect2(1, -4, 1, 1), Px.C.dark if kind[0] == "CALICO" else patch)
		elif kind[0] == "THE DEAN (TUXEDO)":
			draw_rect(Rect2(f, -4, 2, 3), patch)
			draw_rect(Rect2(2 * f - (2 if f < 0 else 0), -4, 3, 1), Px.C.red)            # bow tie
		elif kind[0] == "PIXEL CAT" and int(tt * 6.0) % 5 == 0:
			draw_rect(Rect2(-6, -6, 3, 1), Px.C.cyan)                                   # glitch
		if not sit and int(tt * 6.0) % 2 == 0:
			draw_rect(Rect2(-3, -1, 1, 1), body)
			draw_rect(Rect2(2, -1, 1, 1), body)


class CampusMap extends Node2D:
	signal closed
	var hub: Node
	var tt := 0.0
	var im: ImageTexture

	func _ready() -> void:
		z_index = 60
		var img := Image.create_empty(MAP[0].length() * 4, MAP.size() * 4, false, Image.FORMAT_RGBA8)
		for y in MAP.size():
			for x in MAP[y].length():
				img.fill_rect(Rect2i(x * 4, y * 4, 4, 4), _tile_col(MAP[y][x]))
		im = ImageTexture.create_from_image(img)

	func _tile_col(ch: String) -> Color:
		if ch in FACADE:
			return FACADE[ch].base.darkened(0.15)
		if ch in BUILDINGS:
			return Px.C.gold
		match ch:
			"j": return Px.C.orange.lerp(Px.C.sand, 0.35)
			"p", ".": return Px.C.grey.lerp(Px.C.sand, 0.45)
			"o", "F": return Px.C.cyan.darkened(0.25)
			"f": return Color("a5573b")
			"k", "v": return Color("2f5fae")
			"q": return Px.C.sand.darkened(0.2)
			"T", "z", "U", "h": return Px.C.jade
			"x": return Px.C.brown
			"@": return Px.C.white
		if ch in FLAVOUR or ch in "$cWP":
			return Px.C.gold.darkened(0.3)
		return Px.C.green

	func _process(delta: float) -> void:
		tt += delta
		queue_redraw()
		if tt > 0.2 and (Input.is_action_just_pressed("switch") or Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("accept") or Input.is_action_just_pressed("pause")):
			closed.emit()
			queue_free()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, Px.W, Px.H), Color(Px.C.ink, 0.85))
		var o := Vector2(roundf((Px.W - im.get_width()) / 2.0), 30)
		draw_texture(im, o)
		for k in BUILDINGS:
			var c: Vector2i = hub._find(k)
			draw_rect(Rect2(o + Vector2(c) * 4, Vector2(4, 4)), Px.C.gold)
		for l in [["ARYABHATTA", 25, 12], ["RAMANUJAN", 48, 19], ["VISVES.", 6, 16], ["LILAVATI", 16, 22],
				["MPH", 22, 31], ["BHASKARA", 38, 31], ["GROUND", 50, 6], ["GATE", 40, 2]]:
			Px.text_c(self, l[0], o.x + l[1] * 4 + 2, o.y + l[2] * 4 - 3, Px.C.white)
		for gd in hub.guards:
			draw_rect(Rect2(o + gd.position / 4.0 - Vector2(1, Px.TOP / 4.0 + 2), Vector2(3, 3)), Px.C.red)
		if int(tt * 4.0) % 2 == 0:
			draw_rect(Rect2(o + hub.player.position / 4.0 - Vector2(1, Px.TOP / 4.0 + 2), Vector2(3, 3)), Px.C.white)
		Px.text_c(self, "CAMPUS MAP   YOU: WHITE   SECURITY: RED   DOORS: GOLD", Px.W / 2.0, 12, Px.C.gold)
		Px.text_c(self, "I: CLOSE", Px.W / 2.0, Px.H - 10, Px.C.steel)
