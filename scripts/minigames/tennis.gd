extends Minigame
## Tennis Club: win one game against the club captain, seen from above.
## Move left and right to get to the ball, then press J as it reaches your
## racket line. Clean timing hits harder. Hold LEFT or RIGHT as you swing to
## aim down that line; the rival chases wherever the ball goes.

const L := 112.0         # court edges
const R := 272.0
const TOP := 30.0
const BOT := 206.0
const NET_Y := 118.0
const PY := 188.0        # your racket line
const RY := 48.0         # the rival's racket line
const REACH := 16.0
const Campus := preload("res://scripts/minigames/campus_bg.gd")
const CALLS := ["0", "15", "30", "40"]

var px := 192.0
var rx := 192.0
var ball := Vector2.ZERO
var vel := Vector2.ZERO
var z := 0.0             # ball height, drawn only
var vz := 0.0
var live := false
var wait_t := 0.0
var swing_t := 0.0
var cd := 0.0
var r_react := 0.0
var me := 0
var them := 0
var rally := 0
var aces := 0
var need := 4


func info() -> Dictionary:
	return {"goal": "WIN ONE GAME: 4 POINTS, AND 2 CLEAR AT DEUCE.",
		"keys": ["ARROWS: MOVE   J: SWING AS IT REACHES YOU", "HOLD LEFT/RIGHT WHILE SWINGING TO AIM"], "time": 120.0}


func _ready() -> void:
	if short_round:
		need = 2
	super._ready()


func _call() -> String:
	if me >= 3 and them >= 3:
		return "DEUCE" if me == them else ("ADV YOU" if me > them else "ADV RIVAL")
	return "%s - %s" % [CALLS[mini(me, 3)], CALLS[mini(them, 3)]]


func goal_text() -> String:
	return "YOU %s RIVAL   RALLY %d" % [_call(), rally]


func begin() -> void:
	_serve()


func _serve() -> void:
	live = true
	rally = 0
	ball = Vector2(rx, RY)
	_send(Vector2(randf_range(L + 16, R - 16), BOT), 120.0)
	r_react = 0.0


func _send(to: Vector2, speed: float) -> void:
	vel = (to - ball).normalized() * speed * speedup
	z = 6.0
	vz = 60.0


## Ball x when it next reaches the line y, or its x now if it moves away.
func _x_at(y: float) -> float:
	if absf(vel.y) < 0.01 or signf(y - ball.y) != signf(vel.y):
		return ball.x
	return ball.x + vel.x * (y - ball.y) / vel.y


func _can_hit() -> bool:
	return vel.y > 0.0 and ball.y > PY - 14.0 and ball.y < PY + 4.0 and absf(ball.x - px) <= REACH * Game.window_mult()


func tick(delta: float) -> void:
	var d := delta * speedup
	swing_t -= d
	cd -= d
	var mv := Game.move_vec().x
	var press := Input.is_action_just_pressed("attack")
	if Game.autoplay:
		mv = 0.0
		if live and vel.y > 0.0:
			mv = clampf((_x_at(PY - 4.0) - px) / 6.0, -1.0, 1.0)
		press = _can_hit() and absf(ball.y - (PY - 4.0)) < vel.y * delta * 0.6 + 0.5
		if press:
			mv = 1.0 if rx < 192.0 else -1.0
	px = clampf(px + mv * 120.0 * d, L - 12.0, R + 12.0)
	if not live:
		wait_t -= d
		if wait_t <= 0.0 and not over:
			_serve()
		return
	if press and cd <= 0.0:
		cd = 0.3
		swing_t = 0.18
		if _can_hit():
			var q := 1.0 - clampf(absf(ball.y - (PY - 4.0)) / 10.0, 0.0, 1.0)
			var tx := 192.0 + mv * 64.0 + randf_range(-14.0, 14.0)
			_send(Vector2(clampf(tx, L + 8, R - 8), TOP), 130.0 + 90.0 * q)
			rally += 1
			r_react = randf_range(0.12, 0.3)
			Audio.play("perfect" if q > 0.7 else "hit", 0.08)
			if q > 0.7:
				Fx.word("CLEAN!", Vector2(px, PY - 24), Px.C.lime)
		else:
			Audio.play("swing", 0.1)
	_rival(d)
	ball += vel * d
	vz -= 300.0 * d
	z += vz * d
	if z <= 0.0:
		z = 0.0
		vz = absf(vz) * 0.55 if absf(vz) > 30.0 else 0.0
	if ball.y > BOT + 4.0:
		_point(false)
	elif ball.y < TOP - 4.0:
		_point(true)


func _rival(d: float) -> void:
	if vel.y < 0.0:
		r_react -= d
		if r_react <= 0.0:
			rx = move_toward(rx, _x_at(RY + 4.0), (82.0 + rally * 3.0) * d)
		if ball.y < RY + 10.0 and ball.y > RY - 6.0 and absf(ball.x - rx) <= REACH:
			Audio.play("hit", 0.08)
			# Rival behaviour: hit to the side away from the player.
			var tx := randf_range(R - 44, R - 8) if px < 192.0 else randf_range(L + 8, L + 44)
			_send(Vector2(tx, BOT), minf(115.0 + rally * 6.0, 175.0))
	else:
		rx = move_toward(rx, 192.0, 40.0 * d)


func _point(mine: bool) -> void:
	live = false
	wait_t = 1.0
	if mine:
		me += 1
		if rally <= 1:
			aces += 1
		Audio.play("good", 0.0)
		Fx.word("WINNER!", Vector2(ball.x, 60), Px.C.lime)
	else:
		them += 1
		penalty(6.0, "MISSED IT!", Vector2(px, PY - 24))
	if me >= need and me - them >= (1 if short_round else 2):
		Audio.play("sting", 0.0)
		finish(true, clampf(0.5 + 0.12 * (me - them) + 0.05 * aces, 0.0, 1.0))
	elif them >= need and them - me >= (1 if short_round else 2):
		finish(false, float(me) / need * 0.5)
	else:
		Fx.word(_call(), Vector2(Px.W / 2.0, NET_Y - 6), Px.C.gold)


func judge() -> Array:
	return [me > them, float(me) / need * 0.5]


func _roof(r: Rect2, c: Color, panel: Color) -> void:
	draw_rect(r, Px.C.slate)
	draw_rect(r.grow(-2), c)
	draw_rect(Rect2(r.position.x + 8, r.position.y + 14, r.size.x - 16, 20), panel)
	for y in range(int(r.position.y) + 44, int(r.end.y) - 8, 14):
		draw_rect(Rect2(r.position.x + 8, y, r.size.x - 16, 2), c.darkened(0.12))


func _draw() -> void:
	# From above: the blue court on the lawn, Aryabhatta's roof (light grey,
	# sand-yellow panel, white tower) to the left, Ramanujan's (white, mustard
	# panel) to the right, trees beside the court.
	draw_rect(PLAY, Px.C.green)
	_roof(Rect2(0, 24, 72, 192), Px.C.white.darkened(0.12), Px.C.sand)
	draw_rect(Rect2(20, 150, 24, 24), Px.C.slate)
	draw_rect(Rect2(22, 152, 20, 20), Px.C.white)
	_roof(Rect2(316, 72, 68, 144), Px.C.white, Px.C.gold.darkened(0.2))
	Campus.tree_top(self, Vector2(84, 64))
	Campus.tree_top(self, Vector2(302, 196))
	var apron := Rect2(L - 16, TOP - 6, R - L + 32, BOT - TOP + 12)
	draw_rect(apron, Px.C.blue.darkened(0.2))
	# Netting round the court, with a floodlight pole at each corner.
	draw_rect(apron, Px.C.dark, false, 1.0)
	for y in range(int(apron.position.y) + 8, int(apron.end.y), 16):
		draw_rect(Rect2(apron.position.x - 1, y, 2, 2), Px.C.slate)
		draw_rect(Rect2(apron.end.x - 1, y, 2, 2), Px.C.slate)
	for c in [Vector2(apron.position.x, TOP + 12), Vector2(apron.end.x, TOP + 12), Vector2(apron.position.x, BOT - 12), Vector2(apron.end.x, BOT - 12)]:
		draw_rect(Rect2(c - Vector2(3, 3), Vector2(6, 6)), Px.C.dark)
		draw_rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), Px.C.mist)
	draw_rect(Rect2(L, TOP, R - L, BOT - TOP), Px.C.blue)
	draw_rect(Rect2(L, TOP, R - L, BOT - TOP), Px.C.white, false, 1.0)
	draw_rect(Rect2(L + 20, TOP, R - L - 40, BOT - TOP), Px.C.white, false, 1.0)
	draw_rect(Rect2(L + 20, NET_Y - 44, R - L - 40, 88), Px.C.white, false, 1.0)
	draw_rect(Rect2(192, NET_Y - 44, 1, 88), Px.C.white)
	# Net.
	draw_rect(Rect2(L - 8, NET_Y - 1, R - L + 16, 3), Px.C.dark)
	for x in range(int(L) - 8, int(R) + 8, 3):
		draw_rect(Rect2(x, NET_Y - 1, 1, 3), Px.C.mist)
	draw_rect(Rect2(L - 8, NET_Y - 2, R - L + 16, 1), Px.C.white)
	# Players: the rival at the top, you at the bottom.
	var riv := Px.char_tex(Clubs.get_club("tennis").head_look, "idle")
	draw_texture(riv, Vector2(roundi(rx) - 8, RY - riv.get_height() + 4))
	var you := Px.char_tex(Game.pix_look(), "walk1" if int(t * 8) % 2 == 0 and absf(Game.move_vec().x) > 0.1 else "idle")
	draw_texture(you, Vector2(roundi(px) - 8, PY - you.get_height() + 12))
	var rk := Vector2(px + (12 if swing_t > 0.0 else 8), PY - (2 if swing_t > 0.0 else 8))
	draw_rect(Rect2(rk, Vector2(4, 4)), Px.C.gold, false, 1.0)
	# Ball, shadow on the court, then the ball lifted by its height.
	if live or wait_t > 0.4:
		var b := ball.round()
		draw_rect(Rect2(b.x - 1, b.y + 1, 3, 1), Px.C.dark)
		draw_rect(Rect2(b - Vector2(1, 1 + roundi(z)), Vector2(3, 3)), Px.C.lime)
	# Your reach on the racket line.
	var w := REACH * Game.window_mult()
	draw_rect(Rect2(px - w, PY + 14, w * 2, 2), Px.C.lime if live and _can_hit() else Px.C.slate)
	Px.panel(self, Rect2(290, 30, 88, 34), Px.C.night, Px.C.lime)
	Px.text(self, "TENNIS CLUB", Vector2(296, 34), Px.C.lime)
	Px.text(self, _call(), Vector2(296, 48), Px.C.white)
	draw_timer()
	draw_card()
