extends Minigame
## SquareOne: pitch deck. Six slides lie shuffled in a row. Pick one, pick
## another to swap them, until the deck runs TITLE to ASK. Fewer swaps score
## better. A swap that fixes nothing smudges the slides into stray pixels.

const SLIDES := ["TITLE", "PROBLEM", "SOLUTION", "MARKET", "TEAM", "ASK"]

var order := []    # slide id at each position
var sel := 0
var held := -1
var swaps := 0
var best := 0
var bot_t := 0.0


func info() -> Dictionary:
	return {"goal": "PUT THE 6 SLIDES IN ORDER: TITLE, PROBLEM, SOLUTION, MARKET, TEAM, ASK. FEWER SWAPS SCORE MORE.",
		"keys": ["ARROWS: MOVE   J: PICK, THEN J: SWAP", "K: PUT THE SLIDE BACK"], "time": 60.0}


func _ready() -> void:
	super._ready()
	order = range(SLIDES.size())
	if short_round:
		var p := range(SLIDES.size())
		p.shuffle()
		_swap(p[0], p[1])
		_swap(p[2], p[3])
	else:
		while _placed() > 1:
			order.shuffle()
	best = _min_swaps()


func _swap(a: int, b: int) -> void:
	var tmp: int = order[a]
	order[a] = order[b]
	order[b] = tmp


func _placed() -> int:
	var n := 0
	for i in order.size():
		if order[i] == i:
			n += 1
	return n


## Fewest swaps that sort the deck: slides minus permutation cycles.
func _min_swaps() -> int:
	var seen := {}
	var cycles := 0
	for i in order.size():
		if seen.has(i):
			continue
		cycles += 1
		var j := i
		while not seen.has(j):
			seen[j] = true
			j = order[j]
	return order.size() - cycles


func goal_text() -> String:
	return "IN PLACE %d/6   SWAPS %d (BEST %d)   TIME %d" % [_placed(), swaps, best, ceili(time_left)]


func _rect(i: int) -> Rect2:
	return Rect2(14 + i * 60, 64 - (8 if i == held else 0), 56, 44)


func tick(delta: float) -> void:
	if Game.autoplay:
		bot_t -= delta
		if bot_t > 0.0:
			return
		bot_t = 0.3
		var target := order.find(held) if held >= 0 else _first_wrong()
		if sel != target:
			sel += signi(target - sel)
			Audio.play("move", 0.0)
		else:
			_press()
		return
	if Input.is_action_just_pressed("left") and sel > 0:
		sel -= 1
		Audio.play("move", 0.0)
	if Input.is_action_just_pressed("right") and sel < SLIDES.size() - 1:
		sel += 1
		Audio.play("move", 0.0)
	if _clicked:
		_clicked = false
		for i in SLIDES.size():
			if _rect(i).has_point(cursor):
				sel = i
				_press()
	if Input.is_action_just_pressed("attack"):
		_press()
	if Input.is_action_just_pressed("dodge") and held >= 0:
		held = -1
		Audio.play("back", 0.0)


func _first_wrong() -> int:
	for i in order.size():
		if order[i] != i:
			return i
	return 0


func _press() -> void:
	if held < 0:
		held = sel
		Audio.play("select", 0.0)
		return
	if held == sel:
		held = -1
		Audio.play("back", 0.0)
		return
	var a := held
	held = -1
	_swap(a, sel)
	swaps += 1
	if order[a] == a or order[sel] == sel:
		Audio.play("right", 0.0)
		for i in [a, sel]:
			if order[i] == i:
				Fx.burst(_rect(i).get_center(), [Px.C.tan, Px.C.white], 12, null, 0, 50.0)
		Fx.word(["ALIGN!", "PADDING!", "SNAP!"].pick_random(), _rect(sel).get_center() + Vector2(0, -32), Px.C.lime)
	else:
		Fx.burst(_rect(sel).get_center(), [Px.C.brown, Px.C.ink, Px.C.red], 20, null, 0, 80.0)
		penalty(5.0, "FIXED NOTHING!", _rect(sel).get_center() + Vector2(0, -32))
	if _placed() == order.size():
		Fx.word("SHIP IT!", Vector2(Px.W / 2.0, 130), Px.C.gold, 16)
		finish(true, clampf(float(best) / swaps, 0.3, 1.0))


func judge() -> Array:
	return [false, float(_placed()) / order.size() * 0.6]


func _art(id: int, p: Vector2) -> void:
	match id:
		0:
			draw_rect(Rect2(p + Vector2(8, 18), Vector2(40, 6)), Px.C.gold)
			draw_rect(Rect2(p + Vector2(14, 28), Vector2(28, 3)), Px.C.steel)
			draw_rect(Rect2(p + Vector2(18, 34), Vector2(20, 2)), Px.C.mist)
		1:
			for i in 9:
				draw_rect(Rect2(p + Vector2(19 + i * 2, 17 + i * 2), Vector2(3, 3)), Px.C.red)
				draw_rect(Rect2(p + Vector2(35 - i * 2, 17 + i * 2), Vector2(3, 3)), Px.C.red)
		2:
			draw_rect(Rect2(p + Vector2(22, 16), Vector2(12, 12)), Px.C.gold)
			draw_rect(Rect2(p + Vector2(24, 18), Vector2(3, 3)), Px.C.white)
			draw_rect(Rect2(p + Vector2(25, 28), Vector2(6, 4)), Px.C.steel)
			draw_rect(Rect2(p + Vector2(27, 32), Vector2(2, 2)), Px.C.slate)
			draw_rect(Rect2(p + Vector2(17, 21), Vector2(3, 1)), Px.C.gold)
			draw_rect(Rect2(p + Vector2(36, 21), Vector2(3, 1)), Px.C.gold)
		3:
			draw_rect(Rect2(p + Vector2(12, 30), Vector2(8, 10)), Px.C.cyan)
			draw_rect(Rect2(p + Vector2(24, 24), Vector2(8, 16)), Px.C.blue)
			draw_rect(Rect2(p + Vector2(36, 16), Vector2(8, 24)), Px.C.lime)
		4:
			for k in 3:
				var x := 10 + k * 13
				draw_rect(Rect2(p + Vector2(x + 1, 20 - (k % 2) * 2), Vector2(8, 8)), Px.col(["skin1", "skin2", "skin3"][k]))
				draw_rect(Rect2(p + Vector2(x, 29 - (k % 2) * 2), Vector2(10, 10)), Px.col(["pink", "teal", "orange"][k]))
		5:
			Px.text_c(self, "$", p.x + 28, p.y + 18, Px.C.green, 16, false)


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.brown.darkened(0.7), 0.96))
	Px.text_c(self, "SQUAREONE CRIT - FIX THE PITCH DECK", Px.W / 2.0, 32, Px.C.gold)
	for i in order.size():
		var r := _rect(i)
		var id: int = order[i]
		var ok := id == i
		draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Px.C.dark)
		Px.panel(self, r, Px.C.white, Px.C.gold if i == held or i == sel else (Px.C.lime if ok else Px.C.steel))
		Px.text_c(self, SLIDES[id], r.get_center().x, r.position.y + 5, Px.C.dark, 8, false)
		_art(id, r.position)
		Px.text_c(self, str(i + 1), r.get_center().x, 114, Px.C.lime if ok else Px.C.mist)
		if i == sel:
			draw_rect(Rect2(r.get_center().x - 3, 125, 7, 2), Px.C.gold)
			draw_rect(Rect2(r.get_center().x - 1, 123, 3, 2), Px.C.gold)
	Px.text_c(self, "TITLE > PROBLEM > SOLUTION > MARKET > TEAM > ASK", Px.W / 2.0, 140, Px.C.tan)
	Px.text_c(self, "SWAPS %d   FEWEST POSSIBLE %d" % [swaps, best], Px.W / 2.0, 160, Px.C.white)
	Px.text_c(self, "ARROWS: MOVE   J: PICK / SWAP   K: PUT BACK", Px.W / 2.0, 194, Px.C.steel)
	draw_timer()
	draw_card()
