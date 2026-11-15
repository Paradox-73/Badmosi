extends Minigame
## Screening Club: CHANGEOVER. A grainy reel runs on projector A. A grey cue
## dot warns that the reel is ending, then a white dot flashes: press J inside
## that flash to switch projectors. Early presses and missed cues cost Attendance.

const SCREEN := Rect2(72, 40, 240, 136)
const SKIES := ["navy", "maroon", "teal", "plum", "olive", "blue"]

var need := 6
var hits := 0
var misses := 0
var projector := 0       # 0 = A, 1 = B
var reel_i := 0
var next_cue := 0.0      # time of the changeover cue
var warn_len := 1.4      # the motor cue shows this long before the changeover cue
var black_t := 0.0       # screen goes dark after a missed cue
var flash_t := 0.0
var auto_wait := 0.0


func info() -> Dictionary:
	return {"goal": "HIT THE CHANGEOVER ON THE WHITE CUE DOT. %d CLEAN SWITCHES." % (2 if short_round else 6),
		"keys": ["GREY DOT: GET READY", "J: SWITCH PROJECTOR ON THE WHITE DOT"], "time": 60.0}


func _ready() -> void:
	super._ready()
	if short_round:
		need = 2


func begin() -> void:
	next_cue = t + _gap()


func goal_text() -> String:
	return "SWITCHES %d/%d   PROJECTOR %s   MISSED %d" % [hits, need, "AB"[projector], misses]


## Seconds of reel before the next changeover cue.
func _gap() -> float:
	var g := randf_range(2.4, 3.0) if short_round else randf_range(4.0, 6.5)
	return g / speedup


func _window() -> float:
	return 0.35 * Game.window_mult()


func _cue_on() -> bool:
	return t >= next_cue and t <= next_cue + _window()


func tick(delta: float) -> void:
	black_t -= delta
	flash_t -= delta
	var press := Input.is_action_just_pressed("attack")
	if Game.autoplay:
		auto_wait = auto_wait + delta if _cue_on() else 0.0
		press = auto_wait > 0.08
	if press:
		if _cue_on():
			_switch()
		elif t > next_cue - warn_len and t < next_cue:
			penalty(4.0, "TOO EARLY!", Vector2(SCREEN.get_center().x, SCREEN.position.y + 20))
		else:
			penalty(4.0, "NO CUE YET!", Vector2(SCREEN.get_center().x, SCREEN.position.y + 20))
	if t > next_cue + _window():
		misses += 1
		black_t = 0.6
		penalty(8.0, "REEL RAN OUT!", SCREEN.get_center())
		Fx.burst(SCREEN.get_center(), [Px.C.white, Px.C.grey, Px.C.dark], 40)
		next_cue = t + _gap()
		reel_i += 1


func _switch() -> void:
	hits += 1
	projector = 1 - projector
	reel_i += 1
	flash_t = 0.15
	auto_wait = 0.0
	Audio.play("shutter", 0.0)
	Fx.word("CHANGEOVER!", Vector2(SCREEN.get_center().x, SCREEN.end.y - 16), Px.C.gold)
	Fx.burst(_cue_pos() + Vector2(3, 3), [Px.C.white, Px.C.gold], 16)
	next_cue = t + _gap()
	if hits >= need:
		finish(true, float(hits) / (hits + misses + mistakes * 0.5))


func judge() -> Array:
	return [hits >= need, float(hits) / float(need)]


func _cue_pos() -> Vector2:
	return SCREEN.position + Vector2(SCREEN.size.x - 20, 8)


func _draw() -> void:
	draw_rect(PLAY, Px.C.dark)
	# Hall seats.
	for i in 16:
		draw_rect(Rect2(8 + i * 24, 186, 18, 10), Px.C.maroon)
		draw_rect(Rect2(10 + i * 24, 182, 14, 4), Px.C.maroon.darkened(0.3))
	# Film sprockets scroll down both sides of the screen.
	var sc := int(t * 90.0) % 12
	for x in [SCREEN.position.x - 12, SCREEN.end.x + 4]:
		draw_rect(Rect2(x, SCREEN.position.y, 8, SCREEN.size.y), Px.C.ink)
		for k in range(-1, 12):
			var y: int = int(SCREEN.position.y) + k * 12 + sc
			if y >= SCREEN.position.y and y + 4 <= SCREEN.end.y:
				draw_rect(Rect2(x + 2, y, 4, 4), Px.C.night)
	Px.panel(self, SCREEN.grow(2), Px.C.dark, Px.C.grey)
	if black_t > 0.0:
		draw_rect(SCREEN, Px.C.dark)
		Px.text_c(self, "- NO SIGNAL -", SCREEN.get_center().x, SCREEN.get_center().y - 4, Px.C.slate)
	else:
		_draw_scene()
	# Cue marks: grey motor cue, then the white changeover cue.
	if running and black_t <= 0.0:
		var cp := _cue_pos()
		if t > next_cue - warn_len and t < next_cue - warn_len + 0.4:
			_dot(cp, Px.C.grey)
		if _cue_on():
			_dot(cp, Px.C.white)
	if flash_t > 0.0:
		draw_rect(SCREEN, Color(Px.C.white, 0.7))
	# Projector lamps.
	for p in 2:
		var on := p == projector
		var lx := 140 + p * 80
		Px.panel(self, Rect2(lx, 26, 24, 11), Px.C.gold if on else Px.C.ink, Px.C.steel)
		Px.text(self, "AB"[p], Vector2(lx + 9, 28), Px.C.dark if on else Px.C.slate, 8, false)
	var bar_f := clampf((next_cue - t) / 6.5, 0.0, 1.0) if running else 1.0
	Px.text(self, "REEL", Vector2(8, 100), Px.C.steel)
	Px.bar(self, Rect2(8, 110, 48, 4), bar_f, Px.C.gold)
	Px.text(self, "%d/%d" % [hits, need], Vector2(8, 120), Px.C.white)
	draw_timer()
	draw_card()


## A simple scene per reel, shaking a pixel, with grain and scratches.
func _draw_scene() -> void:
	var jit := Vector2(0, 1 if int(t * 24) % 7 == 0 else 0)
	var r := Rect2(SCREEN.position + jit, SCREEN.size - jit)
	var sky: Color = Px.col(SKIES[reel_i % SKIES.size()])
	draw_rect(r, sky)
	var sx := int(r.position.x) + 40 + (reel_i * 53) % 150
	draw_rect(Rect2(sx, r.position.y + 24, 16, 16), Px.C.sand)
	for i in 6:
		var hx := int(r.position.x) + i * 40 - int(t * 6.0) % 40
		var hh := 20 + ((i + reel_i) * 13) % 26
		var hr := Rect2(maxf(hx, r.position.x), r.end.y - hh, 40, hh)
		hr = hr.intersection(r)
		draw_rect(hr, sky.darkened(0.55))
	var who: Texture2D = Px.char_tex(Clubs.get_club("screening").head_look, "walk1" if int(t * 4) % 2 == 0 else "walk2")
	var wx := int(r.position.x) + 30 + int(t * 20.0 + reel_i * 70) % 170
	draw_texture_rect(who, Rect2(Vector2(wx, r.end.y - 52), who.get_size() * 2), false)
	# Grain: a fresh speckle every frame of film (24 per second).
	var rng := RandomNumberGenerator.new()
	rng.seed = int(t * 24.0)
	for i in 70:
		var gp := Vector2(rng.randi_range(0, int(r.size.x) - 1), rng.randi_range(0, int(r.size.y) - 1))
		draw_rect(Rect2(r.position + gp, Vector2.ONE), Color(Px.C.white if i % 2 == 0 else Px.C.dark, 0.6))
	if rng.randf() < 0.5:
		draw_rect(Rect2(r.position.x + rng.randi_range(4, int(r.size.x) - 4), r.position.y, 1, r.size.y), Color(Px.C.white, 0.35))


## A round 7 x 7 pixel cue dot.
func _dot(p: Vector2, c: Color) -> void:
	draw_rect(Rect2(p + Vector2(2, 0), Vector2(3, 7)), c)
	draw_rect(Rect2(p + Vector2(0, 2), Vector2(7, 3)), c)
	draw_rect(Rect2(p + Vector2(1, 1), Vector2(5, 5)), c)
