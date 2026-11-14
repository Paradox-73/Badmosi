class_name Boss
extends Enemy
## A club head. Picks two of the eight shared attack pieces from the club data,
## telegraphs every attack for at least 0.5 s, then pauses so Pix can hit back.
## The Admin adds phases: Office hours, Upscale and Remix.

const ADMIN_ART := [
	"................................",
	"..kkkkkkkkkkkkkkkkkkkkkkkkkkkk..",
	"..kggggggggggggggggggggggggggk..",
	"..kgmmmmmmmmmmmmmmmmmmmmmmmmgk..",
	"..kgmwwmmmmmmmmmmmmmmmmmmwwmgk..",
	"..kgmwmmmmmmmmmmmmmmmmmmmmwmgk..",
	"..kgmmmmmrrrrmmmmmmrrrrmmmmmgk..",
	"..kgmmmmrrrrrrmmmmrrrrrrmmmmgk..",
	"..kgmmmmmrrrrmmmmmmrrrrmmmmmgk..",
	"..kgmmmmmmmmmmmmmmmmmmmmmmmmgk..",
	"..kgmmmmmmmmmmmmmmmmmmmmmmmmgk..",
	"..kgmmmmmmmkkkkkkkkkkmmmmmmmgk..",
	"..kgmmmmmmmmmmmmmmmmmmmmmmmmgk..",
	"..kgggggggggggggggggggggggggggk.",
	"..kkkkkkkkkkkkkkkkkkkkkkkkkkkk..",
	"....ksssssssssssssssssssssssk...",
	"...ksddddddddddddddddddddddddsk.",
	"..ksdwwwwwwwwwwwwwwwwwwwwwwwwdsk",
	"..ksdwkkkkwwwwkkkkkwwwwkkkwwwdsk",
	"..ksdwwwwwwwwwwwwwwwwwwwwwwwwdsk",
	"..ksdwkkkkkkkwwwwwwkkkkkkwwwwdsk",
	"..ksdwwwwwwwwwwwwwwwwwwwwwwwwdsk",
	"..ksdddddddddddddddddddddddddsk.",
	"..kssssssssssssssssssssssssssk..",
	"..kssaaaasssssssssssssaaaassssk.",
	"..kssaaaasssssssssssssaaaassssk.",
	"..kkkkkkkkkkkkkkkkkkkkkkkkkkkkk.",
	"....kddk................kddk....",
	"....kddk................kddk....",
	"....kddk................kddk....",
	"...kkddkk..............kkddkk...",
	"................................",
]

var attacks: Array = []
var active := false
var busy := false
var rest_t := 1.0
var phase := 1
var reflect_t := 0.0
var freeze_t := 0.0
var freeze_hit := false
var locked := false
var summon_n := 1
var bounce := 1.0
var is_admin := false
signal defeated


func setup_boss(club_id: String) -> void:
	club = club_id
	var d: Dictionary = Clubs.get_club(club_id)
	attacks = d.attacks
	arch = "boss"
	stats = {"hp": 120, "speed": 30, "dmg": 8, "windup": 0.5, "value": 80}
	is_admin = club_id == "admin"
	max_hp = (220.0 if is_admin else 120.0) * Clubs.hp_mult()
	hp = max_hp
	value = 80
	if is_admin:
		var pal := {"k": Px.C.dark, "g": Px.C.grey, "m": Px.C.mist, "w": Px.C.white,
			"r": Px.C.red, "s": Px.C.slate, "d": Px.C.steel, "a": Px.C.gold}
		sprite.texture = Px.tex_from("admin", ADMIN_ART, pal)
		sprite.offset = Vector2(0, -16)
		he = Vector2(12, 4)
	else:
		set_look(d.head_look)
	_spawn_img = sprite.texture.get_image()
	sprite.visible = true
	state = S.IDLE


func _frame(f: String) -> void:
	if is_admin:
		return
	super._frame(f)


func hurtbox() -> Rect2:
	if is_admin:
		var s := sprite.scale.x
		return Rect2(position + Vector2(-14, -30) * s, Vector2(28, 30) * s)
	return Rect2(position + Vector2(-7, -18), Vector2(14, 18))


func speed_mult() -> float:
	return 1.25 if hp < max_hp * 0.5 else 1.0


func _process(delta: float) -> void:
	queue_redraw()
	if Fx.frozen() or dead:
		return
	delta = Fx.dt(delta)
	tick_effects(delta)
	state_t += delta
	reflect_t = maxf(0.0, reflect_t - delta)
	var p: Player = fight.player
	if freeze_t > 0.0:
		freeze_t -= delta
		if p.moved_this_frame and not freeze_hit:
			freeze_hit = p.take_hit(8.0, Vector2.ZERO)
	if not active or busy:
		step_anim(delta, false)
		return
	if downscale_t > 0.0:
		if locked:
			_final_downscale()
		step_anim(delta, false)
		return
	var to := p.position - position
	if absf(to.x) > 2.0:
		facing = Vector2(signf(to.x), 0)
	rest_t -= delta * speed_mult()
	if rest_t > 0.0:
		var want := to.normalized() if to.length() > 40.0 else Vector2.ZERO
		move_by(want * float(stats.speed) * (0.5 if phase == 2 else 1.0) * delta)
		step_anim(delta, want.length() > 0.0)
		return
	_run_attack()


func _pick() -> String:
	if is_admin:
		if phase == 1:
			return ["fan", "stamps"].pick_random()
		if phase == 2:
			return ["ring", "dash", "stamps"].pick_random()
		return ["tiles", "fan", "ring", "dash", "hazard", "summon", "freeze"].pick_random()
	return attacks.pick_random()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec / speed_mult(), false).timeout


func _run_attack() -> void:
	busy = true
	var kind := _pick()
	var p: Player = fight.player
	match kind:
		"tiles":
			var cells := _pattern(p)
			var tg := Fx.telegraph(cells, 0.8 / speed_mult())
			await tg.done
			if dead: return
			Audio.play("zap")
			fight.zap_cells(cells, 9.0, Px.col(Clubs.get_club(club).hazard))
		"stamps":
			var cells2 := []
			var pc := room.cell_of(p.position)
			for i in 3:
				var o := pc + Vector2i(randi_range(-4, 3), randi_range(-3, 2)) if i > 0 else pc
				for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
					cells2.append(o + d)
			var tg2 := Fx.telegraph(cells2, 0.8 / speed_mult())
			await tg2.done
			if dead: return
			Audio.play("stamp")
			Fx.shake(3, 0.15)
			fight.zap_cells(cells2, 10.0, Px.C.red)
			Fx.word("REJECTED!", p.center() + Vector2(0, -20), Px.C.red)
		"fan":
			_flash_pose()
			await _wait(0.5)
			if dead: return
			var volleys := 2 if hp < max_hp * 0.5 else 1
			for v in volleys:
				var aim := (p.center() - center()).normalized()
				for i in 5:
					var a := aim.rotated(deg_to_rad(-30 + 15 * i))
					fight.throw_item(center(), a, club, 6.0, 100.0)
				Audio.play("throw", 0.0)
				await _wait(0.35)
				if dead: return
		"dash":
			var dir := (p.position - position).normalized()
			fight.line_fx(position, position + dir * 200.0, 0.6 / speed_mult())
			await _wait(0.6)
			if dead: return
			Audio.play("swing3")
			var t := 0.0
			var hit := false
			while t < 0.45 and not dead:
				var dt := get_process_delta_time()
				move_by(dir * 260.0 * dt)
				if not hit and p.hurtbox().intersects(hurtbox()):
					hit = p.take_hit(10.0, dir)
				t += dt
				await get_tree().process_frame
		"ring":
			_flash_pose()
			await _wait(0.5)
			if dead: return
			Audio.play("zap")
			fight.shockwave(center(), Px.col(Clubs.get_club(club).hazard), 8.0, 150.0 * (1.5 if phase == 2 else 1.0))
		"summon":
			_flash_pose()
			await _wait(0.5)
			if dead: return
			var n := summon_n if club == "pioneers" else 2
			for i in n:
				fight.spawn_enemy("junior", room.cell_of(position + Vector2(randf_range(-30, 30), randf_range(-20, 20))))
			summon_n = mini(summon_n * 2, 4)
			Fx.word(Clubs.get_club(club).words.pick_random(), center() + Vector2(0, -22), Px.C.gold)
		"hazard":
			var zones := []
			for i in 3:
				var c := room.cell_of(p.position) + Vector2i(randi_range(-5, 4), randi_range(-3, 3))
				if i == 0:
					c = room.cell_of(p.position)
				for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
					zones.append(c + d)
			var tg3 := Fx.telegraph(zones, 0.7 / speed_mult(), Px.col(Clubs.get_club(club).hazard))
			await tg3.done
			if dead: return
			fight.add_hazard(zones, 4.0, Px.col(Clubs.get_club(club).hazard))
		"freeze":
			Fx.word("FREEZE!", Vector2(Px.W / 2.0, 70), Px.C.cyan, 16)
			Audio.play("whistle", 0.0)
			await _wait(0.6)
			if dead: return
			freeze_hit = false
			freeze_t = 1.5
			await _wait(1.5)
			if dead: return
		"shield":
			_flash_pose()
			await _wait(0.5)
			if dead: return
			reflect_t = 2.0
			Fx.word("REBUTTAL!", center() + Vector2(0, -22), Px.C.white)
	if dead:
		return
	rest_t = randf_range(1.0, 1.5)
	busy = false


func _flash_pose() -> void:
	flash_t = 0.12
	Audio.play("tick", 0.0)


func _pattern(p: Player) -> Array:
	var out := []
	var pc := room.cell_of(p.position)
	match randi() % 3:
		0: # Rows across the room.
			for y in [pc.y - 1, pc.y, pc.y + 1]:
				for x in range(1, Px.COLS - 1):
					if (x + y) % 2 == 0:
						out.append(Vector2i(x, y))
		1: # A cross on Pix.
			for i in range(-4, 5):
				out.append(pc + Vector2i(i, 0))
				if i != 0:
					out.append(pc + Vector2i(0, i))
		2: # Checker squares near Pix.
			for y in range(pc.y - 2, pc.y + 3):
				for x in range(pc.x - 3, pc.x + 4):
					if (x + y) % 2 == 0:
						out.append(Vector2i(x, y))
	var clean := []
	for c in out:
		if not room.is_solid(c):
			clean.append(c)
	return clean


func take_hit(dmg: float, dir: Vector2, finisher: bool) -> bool:
	if dead or not active:
		return false
	if reflect_t > 0.0:
		Fx.word("REFLECTED!", center() + Vector2(0, -20), Px.C.white)
		fight.player.take_hit(4.0, -dir)
		return false
	if locked:
		Fx.word("DOWNSCALE IT!", center() + Vector2(0, -36), Px.C.cyan)
		Audio.play("tick", 0.0)
		return false
	if downscale_t > 0.0:
		dmg *= 2.0
	flash_t = 0.07
	Fx.hitstop(0.1 if finisher else 0.06)
	Audio.play("finisher" if finisher else ["hit", "hit2"].pick_random())
	hp -= dmg
	knock = dir * (80.0 if finisher else 20.0)
	if finisher:
		Fx.word(Clubs.get_club(club).words.pick_random(), center() + Vector2(0, -22), Px.C.gold)
		Fx.shake(2, 0.1)
	if is_admin:
		_admin_phase()
	if hp <= 0.0 and not locked:
		die()
	return true


func _admin_phase() -> void:
	var f := hp / max_hp
	if phase == 1 and f <= 0.66:
		phase = 2
		Fx.word("UPSCALE!", Vector2(Px.W / 2.0, 60), Px.C.red, 16)
		Audio.play("special", 0.0)
		sprite.scale = Vector2(2, 2)
		he = Vector2(24, 6)
		fight.banner("THE ADMIN UPSCALES ITSELF. BIGGER PIXELS!")
	elif phase == 2 and f <= 0.33:
		phase = 3
		sprite.scale = Vector2(1, 1)
		he = Vector2(12, 4)
		Fx.word("REMIX!", Vector2(Px.W / 2.0, 60), Px.C.red, 16)
		fight.banner("PHASE 3: EVERY CLUB'S MOVES, FASTER.")
	if f <= 0.01:
		hp = max_hp * 0.01
		if not locked:
			locked = true
			busy = true
			fight.banner("THE ADMIN IS LOCKED. USE DOWNSCALE (L) TO FINISH IT!")
			Game.hype = 10
			Game.special_idx = 0
			Game.stats_changed.emit()


func downscale(sec: float) -> void:
	downscale_t = sec
	if locked:
		_final_downscale()


func _final_downscale() -> void:
	if dead:
		return
	locked = false
	hp = 0.0
	die()


func die() -> void:
	if dead:
		return
	dead = true
	state = S.DEAD
	busy = true
	fight.on_boss_dead(self)


func _draw() -> void:
	draw_rect(Rect2(-8 * sprite.scale.x, -1, 16 * sprite.scale.x, 2), Color(Px.C.dark, 0.5))
	if reflect_t > 0.0:
		var r := Rect2(-10, -22, 20, 23)
		draw_rect(r, Color(Px.C.white, 0.3))
		draw_rect(r, Px.C.white, false, 1.0)
	if freeze_t > 0.0:
		Px.text_c(self, "DON'T MOVE", 0, -40, Px.C.cyan)
