extends Minigame
## Basketball Club: free throws. A power meter sweeps up and down; press J to
## lock it inside the green band. Then an arc meter sweeps; press J again to
## lock the arc. Both in the band is a swish, one close is a rim roll.

const HAND := Vector2(92, 132)
const HOOP := Vector2(306, 96)
const Campus := preload("res://scripts/minigames/campus_bg.gd")
const BAND := 0.09       # half-height of the green band, as a fraction of the meter

var shots := 10
var need := 6
var taken := 0
var made := 0
var swishes := 0
var step := 0            # 0 power, 1 arc, 2 ball in the air
var m := 0.0             # meter value 0..1
var m_dir := 1.0
var power := 0.0
var arc := 0.0
var p_aim := 0.5
var a_aim := 0.5
var fly_t := 0.0
var fly_err := Vector2.ZERO
var result := ""
var marks: Array[bool] = []
var bot_off := 0.0


func info() -> Dictionary:
	return {"goal": "SINK %d OF %d FREE THROWS. LOCK POWER, THEN ARC, INSIDE THE GREEN." % [need, shots],
		"keys": ["J: LOCK POWER", "J AGAIN: LOCK ARC"], "time": 75.0}


func _ready() -> void:
	if short_round:
		shots = 3
		need = 2
	super._ready()


func goal_text() -> String:
	return "MADE %d/%d   NEED %d   SWISH %d" % [made, taken, need, swishes]


func begin() -> void:
	_new_shot()


func _new_shot() -> void:
	step = 0
	m = 0.0
	m_dir = 1.0
	p_aim = randf_range(0.3, 0.8)
	a_aim = randf_range(0.3, 0.8)
	bot_off = randf_range(-0.04, 0.04)


func _band() -> float:
	return BAND * Game.window_mult()


func _speed() -> float:
	return (1.1 + taken * 0.06) * speedup


func tick(delta: float) -> void:
	if step < 2:
		m += m_dir * _speed() * delta
		if m > 1.0:
			m = 1.0
			m_dir = -1.0
		elif m < 0.0:
			m = 0.0
			m_dir = 1.0
		var aim := p_aim if step == 0 else a_aim
		var press := Input.is_action_just_pressed("attack")
		if Game.autoplay:
			press = absf(m - (aim + bot_off)) < _speed() * delta * 0.6
		if press:
			Audio.play("tick", 0.0)
			if step == 0:
				power = m - p_aim
				step = 1
				m = 0.0
				m_dir = 1.0
			else:
				arc = m - a_aim
				_release()
		return
	fly_t += delta * speedup
	if fly_t >= 1.0:
		_land()


func _release() -> void:
	step = 2
	fly_t = 0.0
	Audio.play("throw", 0.05)
	var b := _band()
	# Each meter's miss, in bands: under 1 is in, under 2 is close.
	var e := maxf(absf(power), absf(arc)) / b
	if e <= 1.0:
		result = "SWISH"
	elif e <= 2.0 and (absf(power) <= b or absf(arc) <= b):
		result = "RIM_IN" if randf() < 0.5 else "RIM_OUT"
	else:
		result = "MISS"
	fly_err = Vector2(clampf(power / b, -3, 3) * 9.0, -clampf(arc / b, -3, 3) * 6.0)
	if result == "SWISH":
		fly_err = Vector2.ZERO
	elif result.begins_with("RIM"):
		fly_err = Vector2(6.0 * signf(power if absf(power) > b else 1.0), 0)


func _land() -> void:
	taken += 1
	var ok := result == "SWISH" or result == "RIM_IN"
	marks.append(ok)
	if ok:
		made += 1
		if result == "SWISH":
			swishes += 1
			Audio.play("perfect", 0.0)
			Fx.word("SWISH!", HOOP + Vector2(0, -18), Px.C.lime)
			Fx.burst(HOOP + Vector2(0, 6), [Px.C.white, Px.C.orange], 18)
		else:
			Audio.play("right", 0.0)
			Fx.word("ROLLS IN!", HOOP + Vector2(0, -18), Px.C.gold)
	else:
		penalty(6.0, "RIMMED OUT!" if result == "RIM_OUT" else "AIRBALL!", HOOP + Vector2(-20, -18))
	if made >= need:
		Audio.play("sting", 0.0)
		finish(true, clampf(float(made) / maxf(taken, 1) * 0.7 + swishes * 0.05, 0.0, 1.0))
	elif made + (shots - taken) < need:
		finish(false, float(made) / need * 0.5)
	else:
		_new_shot()


func judge() -> Array:
	return [made >= need, float(made) / need * 0.5]


func _ball_pos() -> Vector2:
	var tgt := HOOP + Vector2(0, 4) + fly_err
	var u := clampf(fly_t, 0.0, 1.0)
	var p := HAND.lerp(tgt, u)
	p.y -= sin(u * PI) * (90.0 + arc * 120.0)
	if result == "RIM_OUT" and u > 0.9:
		p += Vector2(12, -6) * (u - 0.9) * 10.0
	return p


func _meter(x: float, label: String, aim: float, val: float, live: bool) -> void:
	var r := Rect2(x, 60, 10, 120)
	draw_rect(r, Px.C.dark)
	var b := _band() * r.size.y
	var cy := r.end.y - aim * r.size.y
	draw_rect(Rect2(x + 1, cy - b * 2.0, 8, b * 4.0), Px.C.gold.darkened(0.4))
	draw_rect(Rect2(x + 1, cy - b, 8, b * 2.0), Px.C.lime)
	var my := r.end.y - val * r.size.y
	draw_rect(Rect2(x - 3, my - 1, 16, 2), Px.C.white if live else Px.C.steel)
	draw_rect(r, Px.C.mist, false, 1.0)
	Px.text_c(self, label, x + 5, 184, Px.C.white if live else Px.C.steel)


func _draw() -> void:
	# The blue outdoor court between Aryabhatta and Ramanujan: netting
	# round it, floodlight poles, a tree beside it.
	Campus.sky_and_blocks(self, 140)
	draw_rect(Rect2(0, 140, Px.W, 16), Px.C.green)
	Campus.tree(self, 350, 156, 1.2)
	Campus.tree(self, 132, 150, 0.8)
	Campus.labels(self, 140, 72.0)   # clear of the meters
	Campus.fence(self, Rect2(0, 110, Px.W, 46))
	Campus.floodlight(self, 68, 156, 96)
	Campus.floodlight(self, 374, 156, 96)
	draw_rect(Rect2(0, 156, Px.W, 60), Px.C.blue)
	draw_rect(Rect2(0, 156, Px.W, 1), Px.C.mist)
	for x in range(8, Px.W, 40):
		draw_rect(Rect2(x, 170 + (x * 5) % 30, 2, 1), Px.C.blue.lightened(0.15))
	draw_rect(Rect2(76, 156, 3, 60), Px.C.white)    # free-throw line
	# Backboard, rim and net.
	draw_rect(Rect2(325, 65, 6, 42), Px.C.dark)
	draw_rect(Rect2(326, 66, 4, 40), Px.C.white)
	draw_rect(Rect2(HOOP.x + 14, HOOP.y, 12, 2), Px.C.dark)   # rim bracket
	draw_rect(Rect2(328, 106, 4, 50), Px.C.dark)
	draw_rect(Rect2(HOOP.x - 12, HOOP.y, 26, 2), Px.C.orange)
	for i in 5:
		draw_line(HOOP + Vector2(-11 + i * 5, 2), HOOP + Vector2(-8 + i * 4, 14), Px.C.white, 1.0)
	# Shooter.
	var tex := Px.char_tex(Game.pix_look(), "idle")
	draw_texture(tex, Vector2(HAND.x - 14, 156 - tex.get_height()))
	var coach := Px.char_tex(Clubs.get_club("basketball").head_look, "idle")
	draw_texture(coach, Vector2(250, 156 - coach.get_height()))
	# Ball.
	var bp := HAND if step < 2 else _ball_pos()
	draw_rect(Rect2(bp.round() - Vector2(3, 3), Vector2(6, 6)), Px.C.orange)
	draw_rect(Rect2(bp.round() - Vector2(3, 0), Vector2(6, 1)), Px.C.dark)
	draw_rect(Rect2(bp.round() - Vector2(0, 3), Vector2(1, 6)), Px.C.dark)
	if step == 2 and fly_t > 0.85:   # the rim draws over the ball as it drops in
		draw_rect(Rect2(HOOP.x - 12, HOOP.y, 26, 2), Px.C.orange)
	_meter(16, "POWER", p_aim, m if step == 0 else power + p_aim, step == 0)
	_meter(50, "ARC", a_aim, m if step == 1 else (arc + a_aim if step == 2 else 0.0), step == 1)
	for i in shots:
		var c: Color = Px.C.slate
		if i < marks.size():
			c = Px.C.lime if marks[i] else Px.C.red
		draw_rect(Rect2(140 + i * 10, 30, 7, 7), c)
	Px.text(self, "BASKETBALL CLUB", Vector2(140, 40), Px.C.orange)
	draw_timer()
	draw_card()
