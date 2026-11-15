extends Minigame
## Lean-In: mentor match. 12 face-down cards: 6 mentors and the 6 fields they
## teach. Flip two at a time and pair each mentor with their field. Pairs
## burst into pixels. Missing a card you had already seen costs Attendance.

const FIELDS := ["CODE", "CHIPS", "DATA", "DESIGN", "SPACE", "BIO"]
const CLOTH := ["lime", "gold", "cyan", "tan", "white", "green"]
const HAIR := ["ink", "brown", "sand", "maroon", "ink", "brown"]
# Icons on an 8 x 8 grid: [x, y, w, h, colour].
const ICONS := [
	[[0, 1, 8, 6, "steel"], [1, 2, 6, 4, "ink"], [2, 3, 3, 1, "lime"], [2, 5, 2, 1, "lime"], [3, 7, 2, 1, "steel"]],
	[[2, 2, 4, 4, "ink"], [3, 3, 2, 2, "gold"], [1, 2, 1, 1, "gold"], [1, 4, 1, 1, "gold"], [6, 2, 1, 1, "gold"],
		[6, 4, 1, 1, "gold"], [2, 1, 1, 1, "gold"], [4, 1, 1, 1, "gold"], [3, 6, 1, 1, "gold"], [5, 6, 1, 1, "gold"]],
	[[1, 5, 2, 2, "cyan"], [3, 3, 2, 4, "blue"], [5, 1, 2, 6, "violet"], [0, 7, 8, 1, "white"]],
	[[1, 1, 6, 6, "tan"], [2, 2, 1, 1, "red"], [4, 2, 1, 1, "blue"], [2, 4, 1, 1, "lime"], [5, 4, 1, 1, "navy"]],
	[[3, 0, 2, 6, "white"], [3, 2, 2, 1, "cyan"], [2, 4, 1, 2, "red"], [5, 4, 1, 2, "red"], [3, 6, 2, 2, "orange"]],
	[[3, 1, 2, 1, "lime"], [2, 2, 4, 2, "lime"], [1, 3, 2, 2, "green"], [3, 4, 3, 1, "green"], [3, 5, 2, 1, "green"], [4, 6, 1, 2, "brown"]],
]

var cards := []   # {pair, kind (0 mentor, 1 field), up, done, seen}
var sel := 0
var first := -1
var wait_t := 0.0
var pairs := 0
var bot_t := 0.0


func info() -> Dictionary:
	return {"goal": "PAIR ALL 6 MENTORS WITH THEIR FIELDS. FLIP TWO CARDS AT A TIME.",
		"keys": ["ARROWS: MOVE   J: FLIP A CARD"], "time": 75.0}


func _ready() -> void:
	super._ready()
	var n := 2 if short_round else 6
	for p in n:
		for k in 2:
			cards.append({"pair": p, "kind": k, "up": false, "done": false, "seen": false})
	cards.shuffle()


func goal_text() -> String:
	return "PAIRS %d/%d   TIME %d" % [pairs, cards.size() / 2, ceili(time_left)]


func _rect(i: int) -> Rect2:
	return Rect2(76 + (i % 4) * 60, 34 + (i / 4) * 52, 52, 46)


func tick(delta: float) -> void:
	if wait_t > 0.0:
		wait_t -= delta
		if wait_t <= 0.0:
			for c in cards:
				if not c.done:
					c.up = false
		return
	if Game.autoplay:
		bot_t -= delta
		if bot_t <= 0.0:
			bot_t = 0.35
			var target := _bot_target()
			if sel == target:
				_flip(sel)
			else:
				sel = target
				Audio.play("move", 0.0)
		return
	var n := cards.size()
	if Input.is_action_just_pressed("left"):
		sel = (sel + n - 1) % n
	if Input.is_action_just_pressed("right"):
		sel = (sel + 1) % n
	if Input.is_action_just_pressed("up"):
		sel = (sel + n - 4) % n
	if Input.is_action_just_pressed("down"):
		sel = (sel + 4) % n
	if _clicked:
		_clicked = false
		for i in n:
			if _rect(i).has_point(cursor):
				sel = i
				_flip(i)
	if Input.is_action_just_pressed("attack"):
		_flip(sel)


func _partner(i: int) -> int:
	for j in cards.size():
		if j != i and cards[j].pair == cards[i].pair:
			return j
	return -1


## The bot remembers every card it has seen, like a perfect player would.
func _bot_target() -> int:
	if first >= 0 and cards[_partner(first)].seen:
		return _partner(first)
	if first < 0:
		for i in cards.size():
			if not cards[i].done and cards[i].seen and cards[_partner(i)].seen:
				return i
	for i in cards.size():
		if not cards[i].done and not cards[i].seen and i != first:
			return i
	return sel


func _flip(i: int) -> void:
	var c: Dictionary = cards[i]
	if c.up or c.done:
		return
	c.up = true
	Audio.play("select", 0.0)
	if first < 0:
		first = i
		c.seen = true
		return
	var a: Dictionary = cards[first]
	if a.pair == c.pair:
		a.done = true
		c.done = true
		pairs += 1
		Audio.play("right", 0.0)
		for r in [_rect(first), _rect(i)]:
			Fx.burst(r.get_center(), [Px.C.orange, Px.C.white, Px.C.gold], 22, null, 0, 80.0)
		Fx.word(["PAIR UP!", "LEAN IN!", "MATCHED!"].pick_random(), _rect(i).get_center() + Vector2(0, -26), Px.C.lime)
		if pairs >= cards.size() / 2:
			finish(true, clampf(1.0 - mistakes * 0.12, 0.3, 1.0))
	else:
		if cards[_partner(first)].seen:
			penalty(5.0, "YOU SAW ITS MATCH!", _rect(i).get_center() + Vector2(0, -26))
		wait_t = 0.8
	c.seen = true
	first = -1


func judge() -> Array:
	return [false, float(pairs) / (cards.size() / 2)]


func _icon(f: int, p: Vector2, s: int) -> void:
	for r in ICONS[f]:
		draw_rect(Rect2(p + Vector2(r[0], r[1]) * s, Vector2(r[2], r[3]) * s), Px.col(r[4]))


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.maroon.darkened(0.6), 0.96))
	for i in cards.size():
		var c: Dictionary = cards[i]
		var r := _rect(i)
		var edge: Color = Px.C.gold if i == sel else Px.C.dark
		if c.done:
			for x in range(int(r.position.x), int(r.end.x), 4):
				draw_rect(Rect2(x, r.position.y, 2, 1), Px.C.maroon)
				draw_rect(Rect2(x, r.end.y - 1, 2, 1), Px.C.maroon)
			if i == sel:
				draw_rect(Rect2(r.get_center() - Vector2(1, 1), Vector2(2, 2)), Px.C.gold)
			continue
		if not c.up:
			Px.panel(self, r, Px.C.orange, edge)
			for y in range(int(r.position.y) + 4, int(r.end.y) - 4, 4):
				for x in range(int(r.position.x) + 4 + (y / 4) % 2 * 2, int(r.end.x) - 4, 4):
					draw_rect(Rect2(x, y, 2, 2), Px.C.red)
			Px.text_c(self, "?", r.get_center().x, r.get_center().y - 4, Px.C.white)
			continue
		Px.panel(self, r, Px.C.navy, Px.C.gold if i == sel else Px.C.mist)
		var f: int = c.pair
		if c.kind == 0:
			var look := {"hair": HAIR[f], "skin": ["skin1", "skin2", "skin3"][f % 3], "cloth": CLOTH[f], "shade": "slate", "accent": "white", "pants": "ink"}
			draw_texture_rect(Px.char_tex(look, "idle"), Rect2(r.position + Vector2(10, 2), Vector2(32, 32)), false)
			_icon(f, r.position + Vector2(38, 4), 1)
		else:
			_icon(f, r.position + Vector2(14, 6), 3)
		Px.text_c(self, FIELDS[f], r.get_center().x, r.end.y - 11, Px.C.gold if c.kind == 0 else Px.C.white)
	Px.text_c(self, "A MENTOR CARD PAIRS WITH THE FIELD OF THE SAME NAME", Px.W / 2.0, 194, Px.C.steel)
	draw_timer()
	draw_card()
