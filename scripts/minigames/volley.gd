extends Minigame
## Volleyball Club: one on one over the net. Get under the ball and press J
## while it is at head height to bump it over. Hold LEFT for a short drop
## just over the net, RIGHT for a deep shot, nothing for the middle.
## A ball that lands on your side is a point to the rival.

const GROUND := 180.0
const NET_X := 192.0
const NET_TOP := 118.0
const G := 360.0
const APEX := 80.0
const REACH := 14.0
const Campus := preload("res://scripts/minigames/campus_bg.gd")

var need := 5
var me := 0
var them := 0
var px := 90.0
var rx := 300.0
var ball := Vector2.ZERO
var vel := Vector2.ZERO
var live := false
var last_hit := 0        # -1 me, 1 rival
var wait_t := 0.0
var swing_t := 0.0
var cd := 0.0
var r_react := 0.0
var rallies := 0


func info() -> Dictionary:
	return {"goal": "FIRST TO %d POINTS. BUMP THE BALL OVER THE NET; DON'T LET IT DROP." % need,
		"keys": ["ARROWS: MOVE   J: BUMP AT HEAD HEIGHT", "HOLD LEFT: SHORT DROP   HOLD RIGHT: DEEP"], "time": 90.0}


func _ready() -> void:
	if short_round:
		need = 2
	super._ready()


func goal_text() -> String:
	return "YOU %d - %d RIVAL   FIRST TO %d" % [me, them, need]


func begin() -> void:
	_serve()


func _serve() -> void:
	live = true
	last_hit = 1
	ball = Vector2(330, 100)
	_launch(randf_range(40.0, 125.0))   # deeper serves clear the net
	r_react = 0.0


## Sends the ball on a fixed-apex arc that lands at x.
func _launch(x: float) -> void:
	var vy := -sqrt(2.0 * G * maxf(ball.y - APEX, 4.0))
	var t_up := -vy / G
	var t_down := sqrt(2.0 * (GROUND - APEX) / G)
	vel = Vector2((x - ball.x) / (t_up + t_down), vy)


## Where the ball will be (x) when it next falls to height y.
func _x_at(y: float) -> float:
	var d := vel.y * vel.y - 2.0 * G * (ball.y - y)
	if d < 0.0:
		return ball.x
	return ball.x + vel.x * (-vel.y + sqrt(d)) / G


func _in_band(x: float) -> bool:
	return ball.y > GROUND - 54 and ball.y < GROUND - 12 and absf(ball.x - x) <= REACH * Game.window_mult()


func tick(delta: float) -> void:
	var d := delta * speedup
	swing_t -= d
	cd -= d
	# Player movement.
	var mv := Game.move_vec().x
	var press := Input.is_action_just_pressed("attack")
	if Game.autoplay:
		mv = 0.0
		if live and vel.x < 0.0:
			mv = clampf((_x_at(GROUND - 30) - px) / 8.0, -1.0, 1.0)
		press = live and last_hit == 1 and _in_band(px) and ball.y > GROUND - 40
		if press:
			mv = -1.0 if rx > 300.0 else 1.0
	px = clampf(px + mv * 115.0 * d, 16.0, NET_X - 10.0)
	if not live:
		wait_t -= d
		if wait_t <= 0.0 and not over:
			_serve()
		return
	if press and cd <= 0.0:
		cd = 0.3
		swing_t = 0.2
		if last_hit == 1 and _in_band(px):
			Audio.play("hit", 0.08)
			last_hit = -1
			rallies += 1
			var tx := 290.0 + mv * 68.0
			_launch(tx + randf_range(-12.0, 12.0))
			r_react = randf_range(0.25, 0.45)
		else:
			Audio.play("swing", 0.1)
	_rival(d)
	# Ball flight and the net.
	var was_left := ball.x < NET_X
	vel.y += G * d
	ball += vel * d
	if was_left != (ball.x < NET_X) and ball.y > NET_TOP:
		ball.x = NET_X + (-3.0 if was_left else 3.0)
		vel.x = -vel.x * 0.2
		Audio.play("squash", 0.0)
		Fx.word("NET!", Vector2(NET_X, NET_TOP - 12), Px.C.orange)
	if ball.y >= GROUND:
		ball.y = GROUND
		_point(ball.x > NET_X)


func _rival(d: float) -> void:
	if vel.x > 0.0 and last_hit == -1:
		r_react -= d
		if r_react <= 0.0:
			var want := _x_at(GROUND - 32)
			rx = move_toward(rx, clampf(want, NET_X + 10.0, 370.0), (56.0 + them * 4.0) * d)
		if _in_band(rx) and ball.y > GROUND - 40:
			Audio.play("hit", 0.08)
			last_hit = 1
			# Rival behaviour: aim away from where the player stands.
			_launch(randf_range(110.0, 175.0) if px < 100.0 else randf_range(24.0, 80.0))
	elif not live or last_hit == 1:
		rx = move_toward(rx, 300.0, 50.0 * d)


func _point(mine: bool) -> void:
	live = false
	wait_t = 1.0
	if mine:
		me += 1
		Audio.play("good", 0.0)
		Fx.word("POINT!", Vector2(ball.x, GROUND - 30), Px.C.lime)
		Fx.burst(Vector2(ball.x, GROUND), [Px.C.sand, Px.C.white], 14)
	else:
		them += 1
		penalty(6.0, "DROPPED IT!", Vector2(ball.x, GROUND - 30))
	if me >= need:
		Audio.play("sting", 0.0)
		finish(true, clampf(0.55 + 0.45 * float(me - them) / need, 0.0, 1.0))
	elif them >= need:
		finish(false, float(me) / need * 0.5)


func judge() -> Array:
	return [me > them, float(me) / need * 0.5]


func _draw() -> void:
	# The blue outdoor court between Aryabhatta and Ramanujan: netting
	# round it, floodlight poles, a tree beside it.
	Campus.sky_and_blocks(self, 128)
	Campus.tree(self, 176, 128, 1.1)
	Campus.tree(self, 356, 128, 0.9)
	Campus.labels(self, 128)
	draw_rect(Rect2(0, 128, Px.W, 88), Px.C.green)
	Campus.fence(self, Rect2(0, 98, Px.W, 36))
	Campus.floodlight(self, 24, 134, 92)
	Campus.floodlight(self, 330, 134, 92)
	draw_rect(Rect2(8, 134, Px.W - 16, 70), Px.C.blue)
	draw_rect(Rect2(8, 134, Px.W - 16, 70), Px.C.white, false, 1.0)
	draw_rect(Rect2(10, GROUND, Px.W - 20, 1), Px.C.white)
	# Net.
	draw_rect(Rect2(NET_X - 1, NET_TOP, 2, GROUND - NET_TOP), Px.C.mist)
	for y in range(int(NET_TOP), int(NET_TOP) + 22, 4):
		draw_rect(Rect2(NET_X - 3, y, 6, 1), Px.C.white)
	draw_rect(Rect2(NET_X - 4, NET_TOP - 1, 8, 2), Px.C.white)
	# Players.
	var you := Px.char_tex(Game.pix_look(), "walk1" if int(t * 8) % 2 == 0 and absf(Game.move_vec().x) > 0.1 else "idle")
	draw_texture(you, Vector2(roundi(px) - 8, GROUND - you.get_height() + (2 if swing_t > 0.0 else 0)))
	var riv := Px.char_tex(Clubs.get_club("volleyball").head_look, "idle")
	draw_texture(riv, Vector2(roundi(rx) - 8, GROUND - riv.get_height()))
	# Ball and its shadow.
	if live or wait_t > 0.4:
		var b := ball.round()
		draw_rect(Rect2(b.x - 3, GROUND + 1, 6, 1), Px.C.navy)
		draw_rect(Rect2(b - Vector2(4, 4), Vector2(8, 8)), Px.C.dark)
		draw_rect(Rect2(b - Vector2(3, 3), Vector2(6, 6)), Px.C.white)
		draw_rect(Rect2(b - Vector2(3, 0), Vector2(6, 1)), Px.C.gold)
		draw_rect(Rect2(b - Vector2(1, 3), Vector2(1, 6)), Px.C.blue)
	# Your reach band, lit when the ball is in it.
	var w := REACH * Game.window_mult()
	draw_rect(Rect2(px - w, GROUND + 4, w * 2, 2), Px.C.lime if live and last_hit == 1 and _in_band(px) else Px.C.navy)
	Px.panel(self, Rect2(142, 28, 100, 22), Px.C.night, Px.C.cyan)
	Px.text_c(self, "%d - %d" % [me, them], NET_X, 31, Px.C.white, 16)
	draw_timer()
	draw_card()
