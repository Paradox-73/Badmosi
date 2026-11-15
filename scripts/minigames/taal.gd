extends Minigame
## Turiya: TAAL. Teentaal, 16 beats in four groups of four. Tabla bols scroll
## to the line; press J on every beat. SAM, the first beat, is big and worth
## three. Judged against the audio clock, like the dance-off.

const BOLS := ["DHA", "DHIN", "DHIN", "DHA", "DHA", "DHIN", "DHIN", "DHA",
	"DHA", "TIN", "TIN", "TA", "TA", "DHIN", "DHIN", "DHA"]
const MARKS := {0: "X", 4: "2", 8: "0", 12: "3"}   # SAM, tali, khali, tali
const HIT_X := 72.0
const PX_PER_BEAT := 34.0
const LANE_Y := 96

var notes := []     # {beat, idx, judged}
var start := 0.0
var beat := -99.0
var score := 0.0
var best := 0.0
var hits := 0
var sams := 0
var hit_t := 0.0
var sam_t := 0.0


func info() -> Dictionary:
	return {"goal": "KEEP TEENTAAL: J ON EVERY BEAT. SAM (X) COUNTS TRIPLE.",
		"keys": ["J: STRIKE THE TABLA AS EACH BOL MEETS THE LINE"], "time": 60.0}


func uses_timer() -> bool:
	return false


func begin() -> void:
	if not Audio.music.playing:
		Audio.play_music("minigame")
	var cycles := 1 if short_round else 5
	start = ceilf(Audio.song_time() / Audio.beat_len()) + (2.0 if short_round else 4.0)
	for k in cycles * 16:
		notes.append({"beat": start + k, "idx": k % 16, "judged": false})
		best += 3.0 if k % 16 == 0 else 1.0


func goal_text() -> String:
	return "BEATS %d/%d   SAM %d/%d" % [hits, notes.size(), sams, notes.size() / 16]


func tick(delta: float) -> void:
	beat = Audio.song_time() / Audio.beat_len()
	hit_t -= delta
	sam_t -= delta
	var bl := Audio.beat_len()
	var perfect_w := 0.05 * Game.window_mult()
	var good_w := 0.1 * Game.window_mult()
	var next = null
	for n in notes:
		if not n.judged:
			next = n
			break
	if next == null:
		if notes.size() > 0:
			var acc := score / best
			finish(acc >= 0.6, acc)
		return
	var press := Input.is_action_just_pressed("attack")
	if Game.autoplay:
		press = beat >= next.beat
	var d: float = (beat - float(next.beat)) * bl
	if press:
		if absf(d) <= good_w:
			_strike(next, absf(d) <= perfect_w)
		elif beat > start - 1.0:
			penalty(2.0, "OFF TAAL", Vector2(HIT_X, LANE_Y - 22))
	elif d > good_w:
		next.judged = true
		penalty(3.0 if next.idx == 0 else 2.0, "MISSED SAM!" if next.idx == 0 else "MISS", Vector2(HIT_X, LANE_Y - 22))


func _strike(n: Dictionary, perfect: bool) -> void:
	n.judged = true
	hits += 1
	hit_t = 0.12
	var w := 3.0 if n.idx == 0 else 1.0
	score += w * (1.0 if perfect else 0.7)
	var bol: String = BOLS[n.idx]
	Audio.note(43 if bol.begins_with("D") else 67, 0.2, "tri")
	if n.idx == 0:
		sams += 1
		sam_t = 0.5
		Audio.play("perfect", 0.0)
		Fx.word("SAM!", Vector2(HIT_X, LANE_Y - 26), Px.C.gold, 16)
		Fx.burst(Vector2(HIT_X, LANE_Y), [Px.C.gold, Px.C.orange, Px.C.white], 28)
	elif perfect:
		Fx.burst(Vector2(HIT_X, LANE_Y), [Px.C.cyan, Px.C.white], 10)


func _draw() -> void:
	draw_rect(PLAY, Px.C.ink)
	# Rug and stage glow.
	draw_rect(Rect2(0, 150, Px.W, 42), Px.C.maroon)
	for i in 24:
		draw_rect(Rect2(i * 16 + 4, 156, 8, 2), Px.C.gold.darkened(0.3))
	# The 16-beat cycle as a row of dots, groups split by gaps.
	var cur := int(floor(beat - start)) % 16 if beat >= start else -1
	for k in 16:
		var x := 96 + k * 12 + (k / 4) * 6
		var c: Color = Px.C.plum
		if k == cur:
			c = Px.C.gold if k == 0 else Px.C.cyan
		var s := 6 if k == 0 else 4
		draw_rect(Rect2(x - s / 2, 40 - s / 2, s, s), c)
		if MARKS.has(k):
			Px.text_c(self, MARKS[k], x, 46, Px.C.gold if k == 0 else Px.C.steel)
	Px.text(self, "SAM", Vector2(8, 34), Px.C.gold if sam_t > 0.0 else Px.C.slate, 16)
	# The lane: bols ride in from the right.
	draw_rect(Rect2(0, LANE_Y - 14, Px.W, 28), Px.C.night)
	draw_rect(Rect2(HIT_X - 1, LANE_Y - 16, 2, 32), Px.C.white if hit_t > 0.0 else Px.C.steel)
	for n in notes:
		if n.judged:
			continue
		var x := roundf(HIT_X + (float(n.beat) - beat) * PX_PER_BEAT)
		if x < -20 or x > Px.W + 20:
			continue
		var bol: String = BOLS[n.idx]
		var sam: bool = n.idx == 0
		var w := 30 if sam else Px.text_w(bol) + 6
		var h := 22 if sam else 14
		var col: Color = Px.C.gold if sam else (Px.C.steel if n.idx >= 8 and n.idx < 12 else Px.C.cyan)
		var r := Rect2(x - floorf(w / 2.0), LANE_Y - h / 2, w, h)
		Px.panel(self, r, Px.C.dark, col)
		Px.text_c(self, "SAM" if sam else bol, x, r.position.y + (7 if sam else 3), col)
	# The tabla pair, bouncing on each strike.
	var bob := 1 if hit_t > 0.0 else 0
	_drum(Vector2(150, 160 + bob), 22, Px.C.brown)
	_drum(Vector2(196, 158 + bob), 28, Px.C.grey)
	var who: Texture2D = Px.char_tex(Game.pix_look(), "idle")
	draw_texture_rect(who, Rect2(Vector2(170, 126), who.get_size() * 2), false)
	Px.text(self, "BEATS %d/%d" % [hits, notes.size()], Vector2(8, 196), Px.C.steel)
	draw_card()


func _drum(p: Vector2, w: int, body: Color) -> void:
	draw_rect(Rect2(p.x - w / 2, p.y, w, 20), body)
	draw_rect(Rect2(p.x - w / 2, p.y, w, 4), Px.C.sand)
	draw_rect(Rect2(p.x - 3, p.y + 1, 6, 2), Px.C.dark)
