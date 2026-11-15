extends Minigame
## Sports Committee: last-overs chase on the cricket ground. The bowler runs
## in and the ball bounces towards the bat. Press J as it reaches the bat.
## Hold UP to loft it (six, or caught if mistimed), DOWN to keep it on the
## ground (safe, fewer runs), nothing for a drive.

const BAT_X := 104.0     # sweet spot of the bat
const STUMPS_X := 84.0
const GROUND := 170.0
const BOWL_X := 318.0
const WIN := 14.0        # half-width of the timing window in pixels
const Campus := preload("res://scripts/minigames/campus_bg.gd")

var balls := 12
var need := 26
var max_wkts := 3
var bowled := 0
var runs := 0
var wkts := 0
var phase := "runup"     # runup, ball, shot, wait
var phase_t := 0.0
var bx := 0.0
var bounce_x := 200.0
var ball_v := 170.0
var on_stumps := false
var swung := false
var swing_t := 0.0
var shot_v := Vector2.ZERO
var shot_p := Vector2.ZERO
var shot_air := false
var last := ""           # what happened to the last ball, for the scoreboard
var log_balls: Array[String] = []
var bot_aim := 0.0


func info() -> Dictionary:
	return {"goal": "CHASE %d RUNS OFF 2 OVERS. LOSE 3 WICKETS AND IT'S OVER." % need,
		"keys": ["J: SWING AS THE BALL REACHES THE BAT", "HOLD UP: LOFT IT (SIX, OR CAUGHT)", "HOLD DOWN: ALONG THE GROUND (SAFE)"],
		"time": 120.0}


func _ready() -> void:
	if short_round:
		balls = 3
		need = 8
		max_wkts = 2
	super._ready()


func uses_timer() -> bool:
	return false


func goal_text() -> String:
	return "%d/%d   NEED %d OFF %d   %s" % [runs, wkts, maxi(need - runs, 0), balls - bowled, last]


func begin() -> void:
	_next_ball()


func _next_ball() -> void:
	phase = "runup"
	phase_t = 0.0
	swung = false
	bx = BOWL_X
	bounce_x = randf_range(150.0, 220.0)
	ball_v = randf_range(150.0, 215.0) * speedup
	on_stumps = randf() < 0.6
	bot_aim = randf_range(-3.0, 3.0)


## Ball height on its way to the bat: straight down to the bounce, then a low rise.
func _ball_y(x: float) -> float:
	if x > bounce_x:
		return lerpf(132.0, GROUND - 2.0, (BOWL_X - x) / (BOWL_X - bounce_x))
	var k := (bounce_x - x) / (bounce_x - STUMPS_X + 20.0)
	return GROUND - 2.0 - 22.0 * sin(clampf(k, 0.0, 1.0) * PI * 0.5)


func tick(delta: float) -> void:
	phase_t += delta
	swing_t -= delta
	var w := WIN * Game.window_mult()
	match phase:
		"runup":
			if phase_t > 0.9 / speedup:
				phase = "ball"
				Audio.play("throw", 0.05)
		"ball":
			bx -= ball_v * delta
			var press := Input.is_action_just_pressed("attack")
			var dir := Game.move_vec().y
			if Game.autoplay:
				press = absf(bx - (BAT_X + bot_aim)) < ball_v * delta * 0.6 + 0.5
				dir = -1.0 if need - runs > (balls - bowled) * 3 else 0.0
			if press and not swung:
				swung = true
				swing_t = 0.25
				Audio.play("swing", 0.1)
				if absf(bx - BAT_X) <= w:
					_shot(1.0 - absf(bx - BAT_X) / w, dir)
					return
				Fx.word("TOO EARLY!" if bx > BAT_X else "TOO LATE!", Vector2(BAT_X, 112), Px.C.orange)
			if bx < STUMPS_X:
				if on_stumps:
					Audio.play("crash", 0.0)
					Fx.burst(Vector2(STUMPS_X, GROUND - 10), [Px.C.tan, Px.C.white], 20)
					_out("BOWLED!")
				else:
					_ball_done(0, "DOT")
		"shot":
			shot_v.y += (140.0 if shot_air else 0.0) * delta
			shot_p += shot_v * delta
			if phase_t > 1.1:
				phase = "wait"
				phase_t = 0.0
		"wait":
			if phase_t > 0.5:
				if over:
					return
				if runs >= need:
					Audio.play("sting", 0.0)
					finish(true, clampf(0.6 + 0.4 * float(balls - bowled) / balls + 0.1 * (max_wkts - wkts), 0.0, 1.0))
				elif wkts >= max_wkts or bowled >= balls:
					finish(false, clampf(float(runs) / need * 0.6, 0.0, 0.6))
				else:
					_next_ball()


func _shot(q: float, dir: float) -> void:
	var r := 0
	var air := false
	if dir < -0.3:
		air = true
		r = 6 if q > 0.8 else (4 if q > 0.5 else -1)
	elif dir > 0.3:
		r = 4 if q > 0.75 else (2 if q > 0.35 else 1)
	else:
		air = q > 0.6
		r = 4 if q > 0.8 else (2 if q > 0.45 else (1 if q > 0.15 else 0))
	shot_air = air
	shot_p = Vector2(bx, _ball_y(bx))
	shot_v = Vector2(randf_range(170.0, 260.0), -150.0 if air else 0.0)
	if r == 6:
		shot_v = Vector2(220.0, -210.0)
	Audio.play("perfect" if q > 0.8 else "hit", 0.05)
	if r < 0:
		_out("CAUGHT!", false)
		return
	if q > 0.8:
		Fx.burst(shot_p, [Px.C.white, Px.C.gold], 16)
	_ball_done(r, ["DOT", "1 RUN", "2 RUNS", "3", "FOUR!", "5", "SIX!"][r], false)


func _out(word: String, stop := true) -> void:
	wkts += 1
	penalty(8.0, word, Vector2(BAT_X + 40, 104))
	_ball_done(-1, word, stop)


func _ball_done(r: int, word: String, stop := true) -> void:
	bowled += 1
	runs += maxi(r, 0)
	last = word
	log_balls.append("W" if r < 0 else str(r))
	if r >= 4:
		Fx.word(word, Vector2(Px.W / 2.0, 92), Px.C.gold if r == 6 else Px.C.lime, 16)
	elif r > 0:
		Fx.word(word, Vector2(BAT_X + 40, 104), Px.C.white)
	phase = "wait" if stop else "shot"
	phase_t = 0.0


func judge() -> Array:
	return [runs >= need, float(runs) / need * 0.6]


func _person(look: Dictionary, feet: Vector2, frame := "idle") -> void:
	var tex := Px.char_tex(look, frame)
	draw_texture(tex, (feet - Vector2(8, tex.get_height())).round())


func _draw() -> void:
	# The college ground: bare red earth under tall trees, the jogging
	# track along its edges, the academic blocks behind.
	Campus.sky_and_blocks(self, 96)
	var earth := Px.C.orange.lerp(Px.C.brown, 0.45)
	draw_rect(Rect2(0, 96, Px.W, 120), earth)
	for y in range(110, 204, 12):
		draw_rect(Rect2(0, y, Px.W, 6), earth.darkened(0.06))
	draw_rect(Rect2(0, 96, Px.W, 6), Px.C.tan)
	draw_rect(Rect2(0, 204, Px.W, 9), Px.C.tan)
	for tr in [[40.0, 30.0], [76.0, 30.0], [182.0, 18.0], [300.0, 30.0], [346.0, 30.0]]:
		Campus.tree(self, tr[0], 99.0, 1.0, tr[1])
	Campus.labels(self, 96)
	draw_rect(Rect2(64, GROUND - 6, 280, 12), Px.C.sand.darkened(0.15))
	draw_rect(Rect2(64, GROUND - 6, 280, 1), Px.C.sand)
	# Stumps at both ends.
	for sx in [STUMPS_X, BOWL_X + 12.0]:
		for i in 3:
			draw_rect(Rect2(sx - 2 + i * 2, GROUND - 16, 1, 16), Px.C.white)
		draw_rect(Rect2(sx - 3, GROUND - 17, 7, 1), Px.C.tan)
	# Fielders dotted around the boundary.
	for f in [Vector2(150, 118), Vector2(250, 112), Vector2(330, 124), Vector2(200, 192), Vector2(40, 188)]:
		draw_rect(Rect2(f, Vector2(3, 5)), Px.C.white)
		draw_rect(Rect2(f + Vector2(0, -2), Vector2(3, 2)), Px.C.skin2)
	# Bowler: runs in, then follows through.
	var bowl_x := BOWL_X + 40.0 - minf(phase_t / 0.9 * speedup, 1.0) * 30.0 if phase == "runup" else BOWL_X + 8.0
	_person(Clubs.get_club("sports").look, Vector2(bowl_x, GROUND), "walk1" if int(t * 8) % 2 == 0 and phase == "runup" else "idle")
	# Batter and bat.
	var me := Vector2(BAT_X - 14, GROUND)
	_person(Game.pix_look(), me)
	var bat_end := me + (Vector2(18, -4) if swing_t > 0.0 else Vector2(6, -20))
	draw_line(me + Vector2(4, -12), bat_end, Px.C.sand, 2.0)
	# Ball.
	if phase == "ball":
		var bp := Vector2(bx, _ball_y(bx)).round()
		draw_rect(Rect2(bp.x - 1, GROUND + 1, 3, 1), Px.C.dark)
		draw_rect(Rect2(bp - Vector2(1, 1), Vector2(3, 3)), Px.C.red)
		if bx > bounce_x:
			draw_rect(Rect2(bounce_x - 1, GROUND - 1, 3, 1), Color(Px.C.white, 0.3))
	elif phase == "shot":
		draw_rect(Rect2(shot_p.round() - Vector2(1, 1), Vector2(3, 3)), Px.C.red)
	# Timing strip under the pitch: where the bat meets the ball.
	var w := WIN * Game.window_mult()
	draw_rect(Rect2(BAT_X - w, GROUND + 8, w * 2, 2), Px.C.lime.darkened(0.3))
	draw_rect(Rect2(BAT_X - 1, GROUND + 7, 3, 4), Px.C.gold)
	# Scoreboard.
	Px.panel(self, Rect2(90, 28, 128, 28), Px.C.night, Px.C.gold)
	Px.text(self, "%d/%d" % [runs, wkts], Vector2(96, 32), Px.C.gold, 16)
	Px.text(self, "TARGET %d" % need, Vector2(152, 32), Px.C.white)
	Px.text(self, "BALLS %d" % (balls - bowled), Vector2(152, 42), Px.C.steel)
	for i in log_balls.size():
		var b: String = log_balls[i]
		Px.text(self, b, Vector2(250 + i * 10, 30), Px.C.red if b == "W" else (Px.C.lime if b == "4" or b == "6" else Px.C.white))
	draw_card()
