extends Minigame
## Synergy: Fest Setup. Six stalls on the fest ground keep breaking: they spark,
## glitch into loose pixels and show a "!". The crowd meter drains while any
## stall is down. Walk the marker over and tap J three times to fix it.

const NAMES := ["STAGE", "FOOD", "MERCH", "GAMES", "SOUND", "LIGHTS"]
const TINTS := ["violet", "orange", "pink", "cyan", "blue", "gold"]
const FIX_TAPS := 3

var broken: Array[bool] = [false, false, false, false, false, false]
var fix: Array[int] = [0, 0, 0, 0, 0, 0]
var sel := 0
var crowd := 1.0
var crowd_sum := 0.0
var break_t := 2.0
var bot_t := 0.0
var spark_t := 0.0


func info() -> Dictionary:
	return {"goal": "KEEP THE CROWD UNTIL THE TIMER ENDS. FIX EVERY BROKEN STALL FAST.",
		"keys": ["ARROWS: MOVE BETWEEN STALLS", "J: FIX (3 TAPS)"], "time": 60.0}


func _ready() -> void:
	super._ready()
	if short_round:
		break_t = 0.5


func goal_text() -> String:
	return "CROWD %d%%   DOWN %d   TIME %d" % [int(crowd * 100), broken.count(true), ceili(time_left)]


func _rect(i: int) -> Rect2:
	return Rect2(28 + (i % 3) * 120, 50 + (i / 3) * 74, 88, 44)


func tick(delta: float) -> void:
	var down := broken.count(true)
	var pace := (1.0 - time_left / time_total) * 0.6 + 0.4
	break_t -= delta * speedup * (1.6 if short_round else 1.0)
	if break_t <= 0.0:
		break_t = randf_range(2.2, 3.6) / pace
		var ok: Array[int] = []
		for i in 6:
			if not broken[i]:
				ok.append(i)
		if not ok.is_empty():
			var i: int = ok.pick_random()
			broken[i] = true
			fix[i] = 0
			Audio.play("zap", 0.0)
			Fx.burst(_rect(i).get_center(), [Px.C.gold, Px.C.white, Px.C.orange], 16)
	if down > 0:
		crowd -= 0.035 * down * delta * speedup / Game.window_mult()
	else:
		crowd = minf(1.0, crowd + 0.03 * delta)
	crowd_sum += crowd * delta
	spark_t -= delta
	if spark_t <= 0.0 and down > 0:
		spark_t = 0.4
		for i in 6:
			if broken[i]:
				Fx.burst(_rect(i).position + Vector2(randf_range(8, 80), 6), [Px.C.gold, Px.C.white], 3, null, 0, 40.0)
	if crowd <= 0.0:
		crowd = 0.0
		Audio.play("detained", 0.0)
		finish(false, 0.2)
		return
	var mv := Vector2i.ZERO
	var press := Input.is_action_just_pressed("attack")
	if Game.autoplay:
		press = false
		bot_t -= delta
		if bot_t <= 0.0:
			bot_t = 0.16
			var tgt := broken.find(true)
			if tgt == sel:
				press = true
			elif tgt >= 0:
				mv = Vector2i(signi(tgt % 3 - sel % 3), signi(tgt / 3 - sel / 3))
	else:
		mv.x = int(Input.is_action_just_pressed("right")) - int(Input.is_action_just_pressed("left"))
		mv.y = int(Input.is_action_just_pressed("down")) - int(Input.is_action_just_pressed("up"))
	if mv != Vector2i.ZERO:
		var c := clampi(sel % 3 + mv.x, 0, 2)
		var r := clampi(sel / 3 + mv.y, 0, 1)
		sel = r * 3 + c
		Audio.play("move", 0.0)
	if press:
		_fix()


func _fix() -> void:
	var r := _rect(sel)
	if not broken[sel]:
		penalty(3.0, "IT WORKS ALREADY!", r.position + Vector2(44, -10))
		return
	fix[sel] += 1
	Audio.play("hit", 0.0)
	if fix[sel] >= FIX_TAPS:
		broken[sel] = false
		Audio.play("right", 0.0)
		Fx.burst(r.get_center(), [Px.col(TINTS[sel]), Px.C.lime, Px.C.white], 20)
		Fx.word("FIXED!", r.position + Vector2(44, -10), Px.C.lime)


func judge() -> Array:
	return [crowd > 0.0, clampf(crowd_sum / maxf(1.0, t), 0.0, 1.0)]


func _stall(i: int) -> void:
	var r := _rect(i)
	var c: Color = Px.col(TINTS[i])
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Px.C.dark)
	draw_rect(Rect2(r.position.x, r.position.y + 12, r.size.x, r.size.y - 12), Px.C.tan.darkened(0.2))
	# Striped awning.
	for x in range(0, int(r.size.x), 8):
		draw_rect(Rect2(r.position.x + x, r.position.y, 4, 12), c)
		draw_rect(Rect2(r.position.x + x + 4, r.position.y, 4, 12), Px.C.white)
	draw_rect(Rect2(r.position.x + 6, r.position.y + 22, r.size.x - 12, 10), Px.C.brown)
	Px.text_c(self, NAMES[i], r.get_center().x, r.position.y + 23, Px.C.white)
	if broken[i]:
		# Glitch: chunks of the stall drop out as loose pixels.
		for k in 10:
			var gx := int(r.position.x) + ((k * 37 + int(t * 9) * 13) % int(r.size.x - 6))
			var gy := int(r.position.y) + ((k * 23 + int(t * 7) * 11) % int(r.size.y - 6))
			draw_rect(Rect2(gx, gy, 6, 6), Px.C.ink if k % 2 == 0 else Px.C.red)
		if int(t * 4) % 2 == 0:
			Px.text_c(self, "!", r.get_center().x, r.position.y - 11, Px.C.red, 16)
		Px.bar(self, Rect2(r.position.x + 14, r.end.y - 8, r.size.x - 28, 4), float(fix[i]) / FIX_TAPS, Px.C.lime)


func _draw() -> void:
	draw_rect(PLAY, Px.C.green.darkened(0.15))
	for y in range(28, 200, 8):
		for x in range((y / 8 % 3) * 5, Px.W, 15):
			draw_rect(Rect2(x, y, 1, 2), Px.C.lime.darkened(0.2))
	draw_rect(Rect2(0, 104, Px.W, 12), Px.C.sand)
	draw_rect(Rect2(0, 178, Px.W, 30), Px.C.sand)
	for i in 6:
		_stall(i)
	var m := _rect(sel).grow(3)
	var ci: Color = Px.C.white if int(t * 5) % 2 == 0 else Px.C.gold
	for corner in [m.position, Vector2(m.end.x - 6, m.position.y), Vector2(m.position.x, m.end.y - 2), m.end - Vector2(6, 2)]:
		draw_rect(Rect2(corner, Vector2(6, 2)), ci)
	for corner in [m.position, Vector2(m.end.x - 2, m.position.y), Vector2(m.position.x, m.end.y - 6), m.end - Vector2(2, 6)]:
		draw_rect(Rect2(corner, Vector2(2, 6)), ci)
	# The crowd: one pixel person per 2.5% of the meter.
	var people := int(crowd * 40)
	for k in people:
		var x := 12 + (k * 53) % 360
		var y := 182 + (k * 7) % 16 + (int(t * 4 + k) % 2)
		draw_rect(Rect2(x, y, 2, 2), Px.col(["skin1", "skin2", "skin3"][k % 3]))
		draw_rect(Rect2(x, y + 2, 2, 3), Px.col(TINTS[k % 6]))
	Px.text(self, "CROWD", Vector2(8, 28), Px.C.white)
	Px.bar(self, Rect2(44, 29, 120, 7), crowd, Px.C.lime if crowd > 0.35 else Px.C.red)
	Px.text(self, "SYNERGY FEST", Vector2(Px.W - 8 - Px.text_w("SYNERGY FEST"), 28), Px.C.gold)
	draw_timer()
	draw_card()
