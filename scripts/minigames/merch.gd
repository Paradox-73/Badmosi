extends Minigame
## Merch Club: size rush. Students queue with a size bubble. Pick the hoodie
## size on the rack and send it to the front student before they walk out.
## A wrong size shatters into pixels.

const SIZES := ["S", "M", "L", "XL"]
const WIDTH := [12, 16, 20, 24]
const CLOTH := ["cyan", "lime", "gold", "violet", "orange", "steel", "teal", "red"]
const HAIR := ["ink", "brown", "sand", "maroon"]
const SKIN := ["skin1", "skin2", "skin3"]

var queue := []   # {size, patience, max, look}
var sel := 1
var served := 0
var need := 20
var spawn_t := 0.0
var bot_t := 0.0


func info() -> Dictionary:
	return {"goal": "SEND 20 HOODIES. MATCH THE SIZE IN THE FRONT STUDENT'S BUBBLE.",
		"keys": ["ARROWS: PICK A SIZE   J: SEND"], "time": 75.0}


func _ready() -> void:
	super._ready()
	if short_round:
		need = 2


func begin() -> void:
	_spawn()
	_spawn()


func goal_text() -> String:
	return "SENT %d/%d   MISSES %d   TIME %d" % [served, need, mistakes, ceili(time_left)]


func _spawn() -> void:
	if queue.size() >= 4:
		return
	var pat := (12.0 - minf(served, 8) * 0.5) * Game.time_mult() / speedup
	var look := {"hair": HAIR.pick_random(), "skin": SKIN.pick_random(), "cloth": CLOTH.pick_random(),
		"shade": "slate", "accent": "white", "pants": "navy"}
	queue.append({"size": randi() % 4, "patience": pat, "max": pat, "look": look})


func tick(delta: float) -> void:
	spawn_t -= delta
	if spawn_t <= 0.0:
		spawn_t = (3.4 - minf(served, 8) * 0.15) * Game.time_mult() / speedup
		_spawn()
	for s in queue:
		s.patience -= delta
	for s in queue.duplicate():
		if s.patience <= 0.0:
			queue.erase(s)
			penalty(8.0, "WALKED OUT!", Vector2(52, 60))
	if Game.autoplay:
		bot_t -= delta
		if bot_t <= 0.0 and not queue.is_empty():
			bot_t = 0.4
			var want: int = queue[0].size
			if sel == want:
				_send()
			else:
				sel += signi(want - sel)
				Audio.play("move", 0.0)
	else:
		if Input.is_action_just_pressed("left") and sel > 0:
			sel -= 1
			Audio.play("move", 0.0)
		if Input.is_action_just_pressed("right") and sel < 3:
			sel += 1
			Audio.play("move", 0.0)
		if _clicked:
			_clicked = false
			for i in 4:
				if _slot(i).has_point(cursor):
					sel = i
		if Input.is_action_just_pressed("attack"):
			_send()
	if served >= need:
		finish(true, float(served) / (served + mistakes))


func _send() -> void:
	if queue.is_empty():
		return
	var front: Dictionary = queue[0]
	if sel == front.size:
		served += 1
		queue.pop_front()
		Audio.play("buy", 0.0)
		Game.add_pixels(3)
		Fx.word(["SOLD!", "FITS!", "XL VIBES!"].pick_random(), Vector2(48, 96), Px.C.lime)
		if queue.is_empty():
			_spawn()
	else:
		Fx.burst(_slot(sel).get_center(), [Px.C.pink, Px.C.white, Px.C.maroon], 24, null, 0, 90.0)
		penalty(8.0, "WRONG SIZE!", Vector2(_slot(sel).get_center().x, 124))


func judge() -> Array:
	return [served >= need, float(served) / maxf(1, served + mistakes)]


func _slot(i: int) -> Rect2:
	return Rect2(74 + i * 64, 132, 44, 50)


func _hoodie(cx: int, top: int, w: int, col: Color) -> void:
	var h := w + 2
	var x := cx - w / 2
	draw_rect(Rect2(x - 5, top + 1, w + 10, h - 1), Px.C.dark)
	draw_rect(Rect2(x - 4, top + 2, w + 8, h - 4), col.darkened(0.25))
	draw_rect(Rect2(x - 1, top - 1, w + 2, h + 2), Px.C.dark)
	draw_rect(Rect2(x, top, w, h), col)
	draw_rect(Rect2(cx - 4, top - 3, 8, 4), Px.C.dark)
	draw_rect(Rect2(cx - 3, top - 2, 6, 3), col.darkened(0.35))
	draw_rect(Rect2(cx - w / 4, top + h - 6, w / 2, 3), col.darkened(0.2))
	draw_rect(Rect2(cx - 2, top + 1, 1, 4), Px.C.white)
	draw_rect(Rect2(cx + 1, top + 1, 1, 4), Px.C.white)


## Size labels skip the gamepad rename, which would turn "L" into a button name.
func _size_text(s: String, cx: float, y: float, c: Color) -> void:
	draw_string(Px.font, Vector2(roundi(cx - Px.text_w(s) / 2.0), y + 8), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, c)


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.plum.darkened(0.5), 0.96))
	Px.text_c(self, "MERCH STALL - HOODIE DROP", Px.W / 2.0, 29, Px.C.gold)
	for i in 4:
		var r := Rect2(12 + i * 92, 40, 84, 76)
		Px.panel(self, r, Px.C.night, Px.C.gold if i == 0 else Px.C.slate)
		if i >= queue.size():
			Px.text_c(self, "...", r.get_center().x, 72, Px.C.slate)
			continue
		var s: Dictionary = queue[i]
		if i == 0:
			Px.text(self, "FRONT", r.position + Vector2(5, 5), Px.C.gold)
		var tex := Px.char_tex(s.look, "idle")
		var bob := 1 if i == 0 and int(t * 4) % 2 == 0 else 0
		draw_texture_rect(tex, Rect2(r.position + Vector2(20, 34 - bob), Vector2(32, 32)), false)
		var b := Rect2(r.position.x + 52, r.position.y + 16, 26, 14)
		Px.panel(self, b, Px.C.white, Px.C.dark)
		draw_rect(Rect2(b.position.x + 4, b.end.y, 2, 2), Px.C.white)
		_size_text(SIZES[s.size], b.get_center().x, b.position.y + 3, Px.C.dark)
		var f: float = s.patience / s.max
		Px.bar(self, Rect2(r.position.x + 4, r.end.y - 8, r.size.x - 8, 4), f, Px.C.lime if f > 0.5 else (Px.C.gold if f > 0.25 else Px.C.red))
	# The rack.
	draw_rect(Rect2(60, 126, 264, 2), Px.C.steel)
	for i in 4:
		var r := _slot(i)
		if i == sel:
			Px.panel(self, r, Px.C.plum, Px.C.gold)
		draw_rect(Rect2(r.get_center().x, 127, 1, 7), Px.C.mist)
		_hoodie(int(r.get_center().x), 140, WIDTH[i], Px.C.pink)
		_size_text(SIZES[i], r.get_center().x, 170, Px.C.gold if i == sel else Px.C.mist)
	Px.text_c(self, "ARROWS: PICK   J: SEND", Px.W / 2.0, 194, Px.C.steel)
	draw_timer()
	draw_card()
