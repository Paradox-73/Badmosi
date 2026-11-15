extends Minigame
## Impulse: call and response. COUNT EIGHT dances a phrase on the left lanes,
## then the same phrase scrolls up Pix's lanes. Judged against the audio clock.

const LANES := ["left", "down", "up", "right"]
const GLYPH := ["", "", "", ""]
const LANE_COL := ["pink", "cyan", "lime", "gold"]
const LEAD := 4.0          # beats before the first phrase
const PHRASES := 6
const PX_PER_BEAT := 28.0
const TARGET_Y := 52.0

var notes := []   # {beat, lane, side (0 call, 1 player), judged, result}
var hits := 0
var perfects := 0
var misses := 0
var total := 0
var beat := -99.0
var last_word := ""
var last_word_t := 0.0
var pose := [-1, -1]
var pose_t := [0.0, 0.0]
var rng := RandomNumberGenerator.new()



func rhythm() -> bool:
	return true

func info() -> Dictionary:
	return {"goal": "REPEAT COUNT EIGHT'S PHRASES ON THE BEAT",
		"keys": ["ARROW KEYS OR WASD, AS EACH ARROW HITS THE TOP ROW"], "time": 60.0}


func uses_timer() -> bool:
	return false


func _ready() -> void:
	super._ready()
	rng.seed = 808
	var phrases := PHRASES if not short_round else 1
	for p in phrases:
		var n := mini(4 + p, 8) if not short_round else 4
		var slots := []
		for s in 14:
			slots.append(s * 0.5)
		slots.shuffle()
		var chosen := slots.slice(0, n)
		chosen.sort()
		var start := LEAD + p * 16.0
		if short_round:
			start = 2.0
		var prev := -1
		for b in chosen:
			var lane := rng.randi() % 4
			if lane == prev:
				lane = (lane + 1) % 4
			prev = lane
			notes.append({"beat": start + b, "lane": lane, "side": 0, "judged": false})
			notes.append({"beat": start + 8.0 + b, "lane": lane, "side": 1, "judged": false})
			total += 1


func begin() -> void:
	Audio.stop_music()
	Audio.play_music("dance")


func goal_text() -> String:
	return "HITS %d/%d   PERFECT %d   MISS %d" % [hits, total, perfects, misses]


func tick(delta: float) -> void:
	beat = Audio.song_time() / Audio.beat_len()
	var bl := Audio.beat_len()
	var perfect_w := 0.045 * Game.window_mult()
	var good_w := 0.09 * Game.window_mult()
	last_word_t -= delta
	for i in 2:
		pose_t[i] -= delta
	# The caller dances its notes automatically.
	for n in notes:
		if n.side == 0 and not n.judged and beat >= n.beat:
			n.judged = true
			pose[0] = n.lane
			pose_t[0] = 0.2
			Audio.play("good", 0.0, -6.0)
	# Input.
	for li in 4:
		if Input.is_action_just_pressed(LANES[li]):
			pose[1] = li
			pose_t[1] = 0.2
			var best = null
			var best_d := 999.0
			for n in notes:
				if n.side == 1 and not n.judged and n.lane == li:
					var d := absf(n.beat - beat) * bl
					if d < best_d:
						best_d = d
						best = n
			if best != null and best_d <= good_w:
				best.judged = true
				hits += 1
				if best_d <= perfect_w:
					perfects += 1
					_say("PERFECT!", Px.C.gold)
					Audio.play("perfect", 0.0)
					Fx.burst(Vector2(_lane_x(1, li) + 8, TARGET_Y + 8), [Px.col(LANE_COL[li]), Px.C.white], 16)
				else:
					_say("GOOD", Px.C.cyan)
					Audio.play("good", 0.0)
	# Misses.
	for n in notes:
		if n.side == 1 and not n.judged and (beat - n.beat) * bl > good_w:
			n.judged = true
			misses += 1
			_say("MISS", Px.C.red)
			penalty(4.0)
	var end_beat: float = notes[-1].beat + 2.0
	if beat > end_beat:
		var acc := float(hits) / maxf(1.0, total)
		finish(acc >= 0.5, acc)


func _say(w: String, c: Color) -> void:
	last_word = w
	last_word_t = 0.4
	Fx.word(w, Vector2(_lane_x(1, 1) + 24, TARGET_Y + 22), c)


func _lane_x(side: int, lane: int) -> float:
	return (40.0 if side == 0 else 228.0) + lane * 30.0


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.ink, 0.92))
	# Dance floor lights pulse on the beat.
	var ph := fmod(maxf(beat, 0.0), 1.0)
	for i in 12:
		var c: Color = Px.col(LANE_COL[i % 4])
		c.a = 0.18 if (i + int(beat)) % 3 == 0 and ph < 0.5 else 0.06
		draw_rect(Rect2(i * 32, 180, 32, 36), c)
	Px.text_c(self, "COUNT EIGHT", _lane_x(0, 1) + 22, 28, Px.C.pink)
	Px.text_c(self, Game.char_name(), _lane_x(1, 1) + 22, 28, Px.C.gold)
	# Which side is up?
	var cur_phrase := int(floor((beat - LEAD) / 16.0))
	var in_resp := fmod(beat - LEAD, 16.0) >= 8.0
	if beat >= LEAD and not short_round:
		Px.text_c(self, "YOUR TURN!" if in_resp else "WATCH...", Px.W / 2.0, 40, Px.C.white if in_resp else Px.C.steel)
	elif short_round:
		Px.text_c(self, "YOUR TURN!" if beat > 10.0 else "WATCH...", Px.W / 2.0, 40, Px.C.white)
	for side in 2:
		for li in 4:
			var x := _lane_x(side, li)
			var lit: bool = pose[side] == li and pose_t[side] > 0.0
			draw_rect(Rect2(x, TARGET_Y, 16, 16), Px.C.plum if not lit else Px.col(LANE_COL[li]))
			Px.text(self, GLYPH[li], Vector2(x + 5, TARGET_Y + 4), Px.C.ink if lit else Px.C.steel)
			if side == 1:
				Px.text(self, ["A", "S", "W", "D"][li], Vector2(x + 5, TARGET_Y - 10), Px.C.slate)
	for n in notes:
		if n.judged and n.side == 1:
			continue
		var y: float = TARGET_Y + (n.beat - beat) * PX_PER_BEAT
		if n.side == 0 and n.judged:
			continue
		if y < 30 or y > 200:
			continue
		var x2: float = _lane_x(n.side, n.lane)
		var col: Color = Px.col(LANE_COL[n.lane])
		if n.side == 0:
			col = col.darkened(0.3)
		var yy := roundf(y)
		draw_rect(Rect2(x2, yy, 16, 16), Px.C.dark)
		draw_rect(Rect2(x2 + 1, yy + 1, 14, 14), col)
		Px.text(self, GLYPH[n.lane], Vector2(x2 + 5, yy + 4), Px.C.ink, 8, false)
	# Dancers.
	var head: Dictionary = Clubs.get_club("impulse").head_look
	var bob := 1 if ph < 0.25 else 0
	_dancer(Px.char_tex(head, "walk1" if pose_t[0] > 0.0 else "idle"), Vector2(64, 150 - bob), pose[0], pose_t[0])
	_dancer(Px.char_tex(Game.pix_look(), "walk2" if pose_t[1] > 0.0 else "idle"), Vector2(252, 150 - bob), pose[1], pose_t[1])
	draw_card()


func _dancer(tex: Texture2D, pos: Vector2, lane: int, pt: float) -> void:
	var off := Vector2.ZERO
	if pt > 0.0:
		off = [Vector2(-4, 0), Vector2(0, 3), Vector2(0, -4), Vector2(4, 0)][lane]
	draw_texture_rect(tex, Rect2(pos + off, tex.get_size() * 2), false)
