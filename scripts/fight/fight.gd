class_name Fight
extends Node2D
## Runs a club fight in a room: the wave, the attack tokens, projectiles,
## floor hazards, shockwaves, the club head's entrance and defeat.

signal won
signal lost

var club := ""
var room: Room
var player: Player
var actors: Node2D
var top: FightTop
var enemies: Array = []
var boss: Boss = null
var tokens := []
var projectiles := []
var hazards := []
var rings := []
var lines := []
var zaps := []
var phase := "wave"
var no_boss := false   # the opening's tutorial fight
var over := false
var _haz_tick := 0.0


func setup(club_id: String, r: Room, p: Player) -> void:
	club = club_id
	room = r
	player = p
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	top = FightTop.new()
	top.fight = self
	top.z_index = 10
	add_child(top)
	if p.get_parent():
		p.reparent(actors)
	else:
		actors.add_child(p)
	p.fight = self
	p.room = r
	if not Game.detained.is_connected(_on_detained):
		Game.detained.connect(_on_detained)


func _exit_tree() -> void:
	if Game.detained.is_connected(_on_detained):
		Game.detained.disconnect(_on_detained)


func start() -> void:
	var d: Dictionary = Clubs.get_club(club)
	var spawn_list := []
	for ch in ["m", "t"]:
		for c in room.spawns.get(ch, []):
			spawn_list.append([{"m": "member", "t": "thrower"}[ch], c])
	var jc: Array = room.spawns.get("j", [])
	if not jc.is_empty():
		for i in 3:
			spawn_list.append(["junior", jc[i % jc.size()] + Vector2i(0, i - 1)])
	if Game.difficulty == 2:
		for ch2 in ["M", "T"]:
			for c2 in room.spawns.get(ch2, []):
				spawn_list.append([{"M": "member", "T": "thrower"}[ch2], c2])
	var delay := 0.0
	for s in spawn_list:
		_spawn_later(s[0], s[1], delay)
		delay += 0.15
	banner("%s RUSHES IN!" % d.name)


func _spawn_later(arch: String, cell: Vector2i, delay: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	if not over:
		spawn_enemy(arch, cell)


func spawn_enemy(arch: String, cell: Vector2i) -> Enemy:
	if room.is_solid(cell):
		cell = room.boss_cell
	var e := Enemy.new()
	e.fight = self
	e.room = room
	e.position = room.cell_center(cell) + Vector2(0, 6)
	e.setup(arch, club, Clubs.get_club(club).look)
	actors.add_child(e)
	enemies.append(e)
	return e


func request_token(e: Enemy) -> bool:
	tokens = tokens.filter(func(x): return is_instance_valid(x) and not x.dead)
	if tokens.size() < Game.max_attackers():
		tokens.append(e)
		return true
	return false


func release_token(e: Enemy) -> void:
	tokens.erase(e)


func on_enemy_dead(e: Enemy) -> void:
	enemies.erase(e)
	tokens.erase(e)
	if phase == "wave" and _living_minions() == 0:
		if no_boss:
			phase = "done"
			over = true
			player.input_enabled = false
			await get_tree().create_timer(1.0, false).timeout
			won.emit()
			return
		phase = "boss_intro"
		_boss_entrance()


func _living_minions() -> int:
	var n := 0
	for e in enemies:
		if not e.dead and not (e is Boss):
			n += 1
	return n


func _boss_entrance() -> void:
	await get_tree().create_timer(0.6, false).timeout
	if over:
		return
	boss = Boss.new()
	boss.fight = self
	boss.room = room
	boss.position = room.cell_center(room.boss_cell) + Vector2(0, 6)
	boss.setup_boss(club)
	actors.add_child(boss)
	enemies.append(boss)
	Fx.burst(boss.center(), [Px.C.white, Px.C.gold], 30)
	var card := NameCard.new()
	card.club = club
	Game.main.ui.add_child(card)
	Audio.play("sting", 0.0)
	await card.finished
	if over:
		return
	phase = "boss"
	Audio.play_music("admin" if club == "admin" else "boss")
	boss.active = true
	# A senior and a coordinator back the club head up.
	for c in room.spawns.get("b", []):
		spawn_enemy("senior", c)
	for c2 in room.spawns.get("c", []):
		spawn_enemy("coordinator", c2)


func on_boss_dead(b: Boss) -> void:
	if over:
		return
	over = true
	enemies.erase(b)
	for e in enemies.duplicate():
		if is_instance_valid(e) and not e.dead:
			e.die()
	projectiles.clear()
	hazards.clear()
	rings.clear()
	player.input_enabled = false
	Fx.slowmo = 0.25
	Audio.play("burst", 0.0)
	Audio.stop_music()
	await get_tree().create_timer(0.8, false).timeout
	Fx.slowmo = 1.0
	Fx.flash(Color(1, 1, 1, 0.8), 0.3)
	Audio.play("shatter", 0.0)
	var t := b.sprite.texture
	var s := b.sprite.scale.x
	Fx.shatter_tex(t, b.global_position + Vector2(-t.get_width() * s / 2.0, -t.get_height() * s), player, b.value)
	Fx.burst(b.center(), [Px.C.gold, Px.C.white, Px.C.cyan, Px.C.pink], 80, null, 0, 150.0)
	b.queue_free()
	await get_tree().create_timer(1.4, false).timeout
	won.emit()


func _on_detained() -> void:
	if over:
		return
	over = true
	player.input_enabled = false
	lost.emit()


# ------------------------------------------------------------ attack pieces

func throw_item(from: Vector2, dir: Vector2, club_id: String, dmg: float, speed := 110.0) -> void:
	var d: Dictionary = Clubs.get_club(club_id)
	projectiles.append({"pos": from, "vel": dir * speed, "dmg": dmg, "color": Px.col(d.item_color), "t": 0.0})


func zap_cells(cells: Array, dmg: float, color: Color) -> void:
	zaps.append({"cells": cells, "t": 0.25, "color": color})
	if cells.has(room.cell_of(player.position)):
		player.take_hit(dmg, Vector2.ZERO)
	Fx.shake(1, 0.1)


func add_hazard(cells: Array, sec: float, color: Color) -> void:
	hazards.append({"cells": cells, "t": sec, "color": color})


func shockwave(c: Vector2, color: Color, dmg: float, max_r := 150.0) -> void:
	rings.append({"c": c, "r": 4.0, "max": max_r, "color": color, "dmg": dmg, "hit": false, "hurts": true})


func ring_fx(c: Vector2, color: Color) -> void:
	rings.append({"c": c, "r": 4.0, "max": 120.0, "color": color, "dmg": 0.0, "hit": true, "hurts": false})


func line_fx(a: Vector2, b: Vector2, sec: float) -> void:
	lines.append({"a": a, "b": b, "t": sec})
	Audio.play("tele", 0.0)


func clear_hazards() -> void:
	for p in projectiles:
		Fx.burst(p.pos, [p.color], 4)
	projectiles.clear()
	hazards.clear()
	rings = rings.filter(func(r): return not r.hurts)


func banner(text: String) -> void:
	if top:
		top.banner_text = text
		top.banner_t = 2.5


func _process(delta: float) -> void:
	queue_redraw()
	top.queue_redraw()
	if Fx.frozen() or get_tree().paused:
		return
	delta = Fx.dt(delta)
	# Coordinators shield members near them.
	var coords := enemies.filter(func(e): return is_instance_valid(e) and not e.dead and e.arch == "coordinator")
	for e in enemies:
		if not is_instance_valid(e) or e.dead or e is Boss:
			continue
		e.shielded = false
		if e.arch != "coordinator":
			for c in coords:
				if c.position.distance_to(e.position) < 48.0:
					e.shielded = true
	# Projectiles.
	for p in projectiles:
		p.pos += p.vel * delta
		p.t += delta
		if room.is_solid(room.cell_of(p.pos)) or p.t > 5.0:
			p.dead = true
			Fx.burst(p.pos, [p.color], 3, null, 0, 30.0)
		elif player.hurtbox().has_point(p.pos):
			if player.take_hit(p.dmg, p.vel.normalized()):
				p.dead = true
	projectiles = projectiles.filter(func(p): return not p.has("dead"))
	# Floor hazards.
	_haz_tick -= delta
	for h in hazards:
		h.t -= delta
		if h.cells.has(room.cell_of(player.position)):
			player.slow_t = 0.2
			if _haz_tick <= 0.0:
				player.take_hit(3.0, Vector2.ZERO)
	if _haz_tick <= 0.0:
		_haz_tick = 0.5
	hazards = hazards.filter(func(h): return h.t > 0.0)
	# Shockwaves.
	for r in rings:
		r.r += 130.0 * delta
		if r.hurts and not r.hit:
			var d := player.center().distance_to(r.c)
			if absf(d - r.r) < 6.0:
				r.hit = player.take_hit(r.dmg, (player.center() - r.c).normalized())
	rings = rings.filter(func(r): return r.r < r.max)
	for l in lines:
		l.t -= delta
	lines = lines.filter(func(l): return l.t > 0.0)
	for z in zaps:
		z.t -= delta
	zaps = zaps.filter(func(z): return z.t > 0.0)


func _draw() -> void:
	for h in hazards:
		var on := int(h.t * 4.0) % 2 == 0
		for c in h.cells:
			var r := Rect2(Vector2(c.x * 16, Px.TOP + c.y * 16), Vector2(16, 16))
			draw_rect(r.grow(-1), Color(h.color, 0.45 if on else 0.35))
			for i in 4:
				draw_rect(Rect2(r.position + Vector2(3 + i * 3, 4 + (i * 5) % 8), Vector2(2, 2)), Color(h.color.lightened(0.3), 0.8))
	for l in lines:
		var a: Vector2 = l.a
		var b: Vector2 = l.b
		var n := int(a.distance_to(b) / 4.0)
		var on2 := int(l.t * 12.0) % 2 == 0
		for i in n:
			var p: Vector2 = a.lerp(b, float(i) / n).round()
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Px.C.red if on2 else Px.C.tele)


class FightTop extends Node2D:
	var fight: Fight
	var banner_text := ""
	var banner_t := 0.0

	func _process(delta: float) -> void:
		banner_t = maxf(0.0, banner_t - delta)

	func _draw() -> void:
		for z in fight.zaps:
			for c in z.cells:
				var r := Rect2(Vector2(c.x * 16, Px.TOP + c.y * 16), Vector2(16, 16))
				draw_rect(r, Color(Px.C.white, 0.8) if int(z.t * 30.0) % 2 == 0 else Color(z.color, 0.8))
		for p in fight.projectiles:
			var pos: Vector2 = p.pos.round()
			draw_rect(Rect2(pos - Vector2(3, 3), Vector2(6, 6)), Px.C.dark)
			draw_rect(Rect2(pos - Vector2(2, 2), Vector2(4, 4)), p.color)
			draw_rect(Rect2(pos - Vector2(2, 2), Vector2(1, 1)), Px.C.white)
		for r in fight.rings:
			var n := int(r.r * 0.8) + 8
			for i in n:
				var a := i * TAU / n
				var p2: Vector2 = (r.c + Vector2(cos(a), sin(a) * 0.75) * r.r).round()
				draw_rect(Rect2(p2, Vector2(2, 2)), r.color if i % 2 == 0 else Px.C.white)
		if banner_t > 0.0 and banner_text != "":
			var w := Px.text_w(banner_text) + 12
			var rr := Rect2(Px.W / 2.0 - w / 2.0, Px.TOP + 4, w, 14)
			Px.panel(self, rr, Px.C.ink, Px.C.gold)
			Px.text_c(self, banner_text, Px.W / 2.0, Px.TOP + 7, Px.C.white)
