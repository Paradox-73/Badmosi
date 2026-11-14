class_name Player
extends Actor
## Pix in a fight: move, 3-hit combo, dodge with i-frames, specials.

const SPEED := 80.0            # 5 tiles per second
const PIX_LOOK := {"hair": "brown", "skin": "skin2", "cloth": "gold", "shade": "orange",
	"accent": "pink", "pants": "navy", "shoes": "white"}

enum S { MOVE, ATTACK, DODGE, HURT, SPIN, LOCKED }

var state := S.MOVE
var state_t := 0.0
var combo := 0
var combo_window := 0.0
var buffer := ""
var buffer_t := 0.0
var iframe_t := 0.0
var dodge_cd := 0.0
var dodge_dir := Vector2.ZERO
var swing_hit := {}
var shield_t := 0.0
var input_enabled := true
var moved_this_frame := false
var bot := "--autofight" in OS.get_cmdline_user_args()
var _bot_t := 0.0


func _ready() -> void:
	set_look(PIX_LOOK)


func _process(delta: float) -> void:
	queue_redraw()
	if Fx.frozen():
		return
	delta = Fx.dt(delta)
	tick_effects(delta)
	state_t += delta
	iframe_t = maxf(0.0, iframe_t - delta)
	dodge_cd = maxf(0.0, dodge_cd - delta)
	combo_window = maxf(0.0, combo_window - delta)
	shield_t = maxf(0.0, shield_t - delta)
	buffer_t = maxf(0.0, buffer_t - delta)
	if buffer_t <= 0.0:
		buffer = ""
	if input_enabled and not bot:
		_read_input()
	moved_this_frame = false
	var mv := Game.move_vec() if input_enabled else Vector2.ZERO
	if bot and input_enabled:
		mv = _bot(delta)
	match state:
		S.MOVE:
			if mv.length() > 0.1:
				facing = _snap8(mv)
				var spd := SPEED * (0.5 if slow_t > 0.0 else 1.0)
				move_by(mv.normalized() * spd * delta)
				moved_this_frame = true
			step_anim(delta, mv.length() > 0.1)
			if buffer == "attack":
				_start_attack()
			elif buffer == "dodge" and dodge_cd <= 0.0:
				_start_dodge(mv)
			elif buffer == "special":
				_try_special()
		S.ATTACK:
			var dur := 0.35 if combo == 3 else 0.25
			if state_t > 0.05 and state_t < 0.16:
				_apply_swing()
			if buffer == "dodge" and dodge_cd <= 0.0 and state_t > 0.1:
				_start_dodge(mv)
			elif state_t >= dur:
				state = S.MOVE
				combo_window = 0.3
				if buffer == "attack" and combo < 3:
					_start_attack()
		S.DODGE:
			move_by(dodge_dir * 240.0 * delta)
			moved_this_frame = true
			if state_t >= 0.2:
				state = S.MOVE
		S.HURT:
			if state_t >= 0.25:
				state = S.MOVE
		S.SPIN:
			if mv.length() > 0.1:
				move_by(mv.normalized() * SPEED * delta)
			sprite.flip_h = int(state_t * 16.0) % 2 == 0
			if int(state_t * 10.0) != int((state_t - delta) * 10.0):
				swing_hit.clear()
			_spin_hits()
			if state_t >= 1.0:
				state = S.MOVE
		S.LOCKED:
			step_anim(delta, false)
	if room and room.is_hazard(position) and iframe_t <= 0.0 and state != S.DODGE:
		take_hit(4.0, Vector2.ZERO, "hazard")


## Test bot for frame captures: walks to the nearest enemy and attacks.
func _bot(delta: float) -> Vector2:
	_bot_t -= delta
	if fight == null or fight.enemies.is_empty():
		return Vector2.ZERO
	var best = null
	var bd := 9999.0
	for e in fight.enemies:
		if is_instance_valid(e) and not e.dead:
			var d: float = e.position.distance_to(position)
			if d < bd:
				bd = d
				best = e
	if best == null:
		return Vector2.ZERO
	var to: Vector2 = best.position - position
	if bd < 20.0:
		facing = _snap8(to)
		if _bot_t <= 0.0:
			_bot_t = 0.12
			buffer = "attack" if Game.hype < 5 or randf() < 0.8 else "special"
			buffer_t = 0.15
		return Vector2.ZERO
	return to.normalized()


func _read_input() -> void:
	for a in ["attack", "dodge", "special"]:
		if Input.is_action_just_pressed(a):
			buffer = a
			buffer_t = 0.15
	if Input.is_action_just_pressed("switch"):
		Game.cycle_special()
		Audio.play("move", 0.0)


static func _snap8(v: Vector2) -> Vector2:
	return Vector2.from_angle(snappedf(v.angle(), PI / 4.0))


func _start_attack() -> void:
	buffer = ""
	combo = combo + 1 if combo_window > 0.0 and combo < 3 else 1
	state = S.ATTACK
	state_t = 0.0
	swing_hit.clear()
	_frame("idle")
	Audio.play(["swing", "swing2", "swing3"][combo - 1])
	move_by(facing * 3.0)


func _start_dodge(mv: Vector2) -> void:
	buffer = ""
	state = S.DODGE
	state_t = 0.0
	dodge_dir = mv.normalized() if mv.length() > 0.1 else facing
	iframe_t = maxf(iframe_t, 0.25)
	dodge_cd = 0.4
	combo = 0
	Audio.play("dodge")


func swing_box() -> Rect2:
	var c := center() + facing * 12.0
	return Rect2(c - Vector2(10, 8), Vector2(20, 16))


func _apply_swing() -> void:
	if fight == null:
		return
	var box := swing_box()
	var dmg := (12.0 if combo == 3 else 6.0) * Game.player_dmg_mult()
	for e in fight.enemies:
		if e.dead or swing_hit.has(e):
			continue
		if box.intersects(e.hurtbox()):
			swing_hit[e] = true
			var landed: bool = e.take_hit(dmg, facing, combo == 3)
			if landed:
				Game.add_hype(1)
	if room and room.hit_prop(center() + facing * 12.0):
		Fx.burst(center() + facing * 14.0, [Px.C.gold], 6, self, 5)


func _spin_hits() -> void:
	if fight == null:
		return
	var box := Rect2(center() - Vector2(20, 18), Vector2(40, 32))
	for e in fight.enemies:
		if not e.dead and not swing_hit.has(e) and box.intersects(e.hurtbox()):
			swing_hit[e] = true
			e.take_hit(5.0 * Game.player_dmg_mult(), (e.position - position).normalized(), false)


func _try_special() -> void:
	buffer = ""
	var sp: Dictionary = Game.current_special()
	if Game.hype < int(sp.cost):
		Fx.word("NEED HYPE", center() + Vector2(0, -16), Px.C.steel)
		Audio.play("back", 0.0)
		return
	Game.add_hype(-int(sp.cost))
	Audio.play("special", 0.0)
	Fx.word(sp.name + "!", center() + Vector2(0, -18), Px.C.cyan)
	match sp.id:
		"downscale":
			Fx.flash(Color(Px.C.cyan, 0.4), 0.15)
			for e in fight.enemies:
				if not e.dead and e.position.distance_to(position) <= 48.0:
					e.downscale(2.0)
		"spin":
			state = S.SPIN
			state_t = 0.0
			swing_hit.clear()
			iframe_t = maxf(iframe_t, 1.0)
		"bass":
			Fx.shake(3, 0.3)
			fight.ring_fx(center(), Px.C.violet)
			for e in fight.enemies:
				if not e.dead:
					var d: Vector2 = e.position - position
					if d.length() < 120.0:
						e.knock = d.normalized() * 300.0
						e.take_hit(4.0, d.normalized(), false)
		"redpen":
			Fx.flash(Color(Px.C.red, 0.3), 0.2)
			fight.clear_hazards()
		"pi":
			shield_t = 3.14
			iframe_t = maxf(iframe_t, 3.14)


## Takes a hit. Returns true if it landed.
func take_hit(pct: float, dir: Vector2, _kind := "") -> bool:
	if iframe_t > 0.0 or state == S.DODGE or dead:
		return false
	Game.hurt(pct)
	Audio.play("hurt")
	flash_t = 0.07
	iframe_t = 0.8
	knock = dir * 160.0
	state = S.HURT
	state_t = 0.0
	combo = 0
	Fx.shake(2, 0.12)
	Fx.hitstop(0.05)
	return true


func _draw() -> void:
	super._draw()
	if iframe_t > 0.0 and state != S.DODGE and int(iframe_t * 20.0) % 2 == 0:
		sprite.visible = false
	else:
		sprite.visible = true
	if shield_t > 0.0:
		var r := 14
		for i in 16:
			var a := i * TAU / 16.0 + shield_t * 3.0
			draw_rect(Rect2(Vector2(cos(a), sin(a) * 0.8) * r + Vector2(0, -8), Vector2.ONE * 2).abs(), Px.C.cyan)
	if state == S.ATTACK and state_t < 0.18:
		# Swing arc made of pixel blocks.
		var c := Vector2(0, -7)
		var base := facing.angle()
		var span := 2.2
		var n := 7
		var col := Px.C.white if combo < 3 else Px.C.gold
		for i in n:
			var k := float(i) / (n - 1)
			var a := base - span / 2.0 + span * k
			var rad := 13.0 + (2.0 if combo == 3 else 0.0)
			var p := (c + Vector2(cos(a), sin(a)) * rad).round()
			draw_rect(Rect2(p, Vector2(2, 2)), col)
		# The wooden club.
		var tip := (c + facing * 14.0).round()
		draw_line(c.round(), tip, Px.C.brown, 2.0)
	if state == S.SPIN:
		for i in 12:
			var a2 := i * TAU / 12.0 + state_t * 20.0
			draw_rect(Rect2((Vector2(cos(a2), sin(a2)) * 16 + Vector2(0, -7)).round(), Vector2(2, 2)), Px.C.gold)
