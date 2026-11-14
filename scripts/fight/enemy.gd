class_name Enemy
extends Actor
## One scene for all five archetypes: member, thrower, senior, junior, coordinator.
## States: SPAWN, IDLE, CHASE, WINDUP, ATTACK, STAGGER, DEAD.

enum S { SPAWN, IDLE, CHASE, WINDUP, ATTACK, STAGGER, DEAD }

const ARCH := {
	"member": {"hp": 16, "speed": 42, "dmg": 6, "windup": 0.4, "value": 10},
	"thrower": {"hp": 12, "speed": 38, "dmg": 5, "windup": 0.5, "value": 12},
	"senior": {"hp": 34, "speed": 26, "dmg": 10, "windup": 0.7, "value": 25},
	"junior": {"hp": 5, "speed": 66, "dmg": 3, "windup": 0.3, "value": 4},
	"coordinator": {"hp": 20, "speed": 30, "dmg": 5, "windup": 0.5, "value": 15},
}

var arch := "member"
var club := ""
var state := S.SPAWN
var state_t := 0.0
var has_token := false
var think_t := 0.0
var orbit := 1.0
var armor := 0
var shielded := false
var attack_dir := Vector2.RIGHT
var hit_done := false
var value := 10
var _spawn_img: Image
var _spawn_off := []
var stats := {}


func setup(a: String, club_id: String, l: Dictionary) -> void:
	arch = a
	club = club_id
	stats = ARCH[a]
	max_hp = float(stats.hp) * Clubs.hp_mult()
	hp = max_hp
	value = int(stats.value)
	armor = 3 if a == "senior" else 0
	orbit = 1.0 if randf() < 0.5 else -1.0
	var lk := l.duplicate()
	match a:
		"senior":
			lk["cloth"] = lk.get("shade", "slate")
			lk["hat"] = "cap"
		"junior":
			lk["hair"] = lk.get("accent", "gold")
		"coordinator":
			lk["hat"] = "visor"
		"thrower":
			lk["accent"] = "white"
	set_look(lk)
	_spawn_img = sprite.texture.get_image()
	for i in _spawn_img.get_width() * _spawn_img.get_height():
		_spawn_off.append(Vector2(randf_range(-40, 40), randf_range(-40, 20)))
	sprite.visible = false


func _process(delta: float) -> void:
	queue_redraw()
	if Fx.frozen() or dead:
		return
	delta = Fx.dt(delta)
	tick_effects(delta)
	state_t += delta
	var p: Player = fight.player if fight else null
	if p == null:
		return
	var to := p.position - position
	if absf(to.x) > 2.0:
		facing = Vector2(signf(to.x), 0)
	if downscale_t > 0.0:
		_release()
		step_anim(delta, false)
		return
	match state:
		S.SPAWN:
			if state_t >= 0.5:
				sprite.visible = true
				_go(S.IDLE)
		S.IDLE, S.CHASE:
			_think(delta, p, to)
		S.WINDUP:
			step_anim(delta, false)
			if state_t >= float(stats.windup):
				_go(S.ATTACK)
				hit_done = false
				_begin_attack(p)
		S.ATTACK:
			_attack_tick(delta, p)
		S.STAGGER:
			step_anim(delta, false)
			if state_t >= 0.3:
				_go(S.CHASE)


func _go(s: S) -> void:
	state = s
	state_t = 0.0


func _release() -> void:
	if has_token:
		has_token = false
		fight.release_token(self)


func _think(delta: float, p: Player, to: Vector2) -> void:
	var dist := to.length()
	var on_screen := Rect2(0, Px.TOP, Px.W, Px.H - Px.TOP).has_point(position)
	var want := Vector2.ZERO
	var spd := float(stats.speed) * (0.5 if slow_t > 0.0 else 1.0)
	var reach := 18.0
	match arch:
		"thrower":
			reach = 90.0
		"senior":
			reach = 110.0
		"coordinator":
			reach = 16.0
	if not has_token:
		think_t -= delta
		if think_t <= 0.0 and on_screen and dist < reach + 40.0:
			think_t = randf_range(0.2, 0.6)
			has_token = fight.request_token(self)
	if has_token:
		if arch == "thrower" and dist < 56.0:
			want = -to.normalized()
		elif dist > reach:
			want = to.normalized()
		elif on_screen:
			attack_dir = to.normalized()
			_go(S.WINDUP)
			if arch == "senior":
				fight.line_fx(position, position + attack_dir * 110.0, float(stats.windup))
			return
	else:
		# Circle at 3 to 4 tiles, waiting for a token.
		var ring := 56.0 if arch != "thrower" else 72.0
		if arch == "coordinator":
			ring = 80.0
		var tangent := Vector2(-to.y, to.x).normalized() * orbit
		var radial := -to.normalized() * clampf((ring - dist) / 20.0, -1.0, 1.0)
		want = (tangent * 0.6 + radial).limit_length(1.0)
	# Separation from other enemies.
	for e in fight.enemies:
		if e != self and not e.dead:
			var d: Vector2 = position - e.position
			if d.length() < 14.0 and d.length() > 0.01:
				want += d.normalized() * 0.6
	if want.length() > 0.05:
		move_by(want.limit_length(1.0) * spd * delta)
	step_anim(delta, want.length() > 0.05)


func _begin_attack(p: Player) -> void:
	match arch:
		"thrower":
			fight.throw_item(center(), (p.center() - center()).normalized(), club, float(stats.dmg))
			Audio.play("throw")
		"senior":
			Audio.play("swing3")
		_:
			Audio.play("swing", 0.1)


func _attack_tick(delta: float, p: Player) -> void:
	match arch:
		"senior":
			# Charge along the telegraphed line.
			move_by(attack_dir * 200.0 * delta)
			if not hit_done and p.hurtbox().intersects(hurtbox().grow(2)):
				hit_done = p.take_hit(float(stats.dmg), attack_dir)
			if state_t >= 0.55:
				_finish_attack()
		"thrower":
			if state_t >= 0.25:
				_finish_attack()
		_:
			if arch == "junior" and state_t < 0.15:
				move_by(attack_dir * 120.0 * delta)
			if not hit_done and state_t > 0.05:
				var box := Rect2(center() + attack_dir * 10.0 - Vector2(8, 7), Vector2(16, 14))
				if box.intersects(p.hurtbox()):
					hit_done = true
					p.take_hit(float(stats.dmg), attack_dir)
			if state_t >= 0.3:
				_finish_attack()


func _finish_attack() -> void:
	_release()
	_go(S.CHASE)
	think_t = randf_range(0.6, 1.2)


func downscale(sec: float) -> void:
	downscale_t = sec
	if state == S.WINDUP or state == S.ATTACK:
		_go(S.STAGGER)


## Takes a hit from Pix. Returns true if it landed.
func take_hit(dmg: float, dir: Vector2, finisher: bool) -> bool:
	if dead or state == S.SPAWN:
		return false
	if shielded:
		Fx.word("SHIELDED", center() + Vector2(0, -14), Px.C.cyan)
		Audio.play("tick", 0.0)
		return false
	if downscale_t > 0.0:
		dmg *= 2.0
	flash_t = 0.07
	Fx.hitstop(0.1 if finisher else 0.06)
	Audio.play("finisher" if finisher else ["hit", "hit2"].pick_random())
	if armor > 0:
		armor -= 1
		Fx.word("ARMOUR", center() + Vector2(0, -14), Px.C.steel)
		return true
	hp -= dmg
	if finisher:
		knock = dir * 260.0
		Fx.shake(2, 0.12)
		var d: Dictionary = Clubs.get_club(club)
		Fx.word(d.words.pick_random(), center() + Vector2(0, -18), Px.C.gold)
	else:
		knock = dir * 90.0
	if hp <= 0.0:
		die()
	elif arch != "senior" or finisher:
		_release()
		_go(S.STAGGER)
	return true


func die() -> void:
	if dead:
		return
	dead = true
	_release()
	state = S.DEAD
	Audio.play("burst")
	var t := sprite.texture
	Fx.shatter_tex(t, global_position + Vector2(-t.get_width() / 2.0, -t.get_height()), fight.player, value)
	fight.on_enemy_dead(self)
	queue_free()


func _draw() -> void:
	if state == S.SPAWN:
		var k := clampf(state_t / 0.5, 0.0, 1.0)
		var w := _spawn_img.get_width()
		var h := _spawn_img.get_height()
		var i := 0
		for y in h:
			for x in w:
				var c := _spawn_img.get_pixel(x, y)
				if c.a > 0.5:
					var target := Vector2(x - w / 2.0, y - h)
					draw_rect(Rect2((target + _spawn_off[i] * (1.0 - k)).round(), Vector2.ONE), c)
				i += 1
		return
	super._draw()
	if state == S.WINDUP:
		if arch == "member" or arch == "coordinator":
			mat.set_shader_parameter("flash", 1.0 if int(state_t * 12.0) % 2 == 0 else 0.0)
		elif arch == "thrower":
			var col: Color = Px.col(Clubs.get_club(club).item_color)
			draw_rect(Rect2(-3, -24, 6, 6), Px.C.dark)
			draw_rect(Rect2(-2, -23, 4, 4), col)
		elif arch == "junior":
			sprite.position.y = -2 if int(state_t * 20.0) % 2 == 0 else 0
	else:
		sprite.position.y = 0
	if shielded:
		var t := int(anim_t * 6.0) % 2
		draw_rect(Rect2(-8, -18 - t, 16, 19 + t), Color(Px.C.cyan, 0.35))
		draw_rect(Rect2(-8, -18 - t, 16, 19 + t), Px.C.cyan, false, 1.0)
	if hp < max_hp and arch != "junior":
		Px.bar(self, Rect2(-7, 2, 14, 3), hp / max_hp, Px.C.red)
	if armor > 0:
		for i2 in armor:
			draw_rect(Rect2(-5 + i2 * 4, -22, 3, 3), Px.C.steel)
