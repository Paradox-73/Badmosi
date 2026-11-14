extends Node
## Game feel: hitstop, whole-pixel screen shake, comic words, pixel bursts,
## floor telegraphs, flashes and the mosaic room transition.

var stop_t := 0.0
var slowmo := 1.0
var _shake_t := 0.0
var _shake_px := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if stop_t > 0.0:
		stop_t -= delta
	var m = Game.main
	if m == null:
		return
	if _shake_t > 0.0 and Game.opts.shake:
		_shake_t -= delta
		m.world.position = Vector2(_rng.randi_range(-_shake_px, _shake_px), _rng.randi_range(-_shake_px, _shake_px))
	else:
		m.world.position = Vector2.ZERO


## True while a hitstop freeze is running. Fighters skip their update then.
func frozen() -> bool:
	return stop_t > 0.0


## Scaled delta for gameplay, honouring slow motion.
func dt(delta: float) -> float:
	return delta * slowmo


func hitstop(sec: float) -> void:
	stop_t = maxf(stop_t, sec)


func shake(px := 2, sec := 0.15) -> void:
	_shake_px = clampi(px, 1, 3)
	_shake_t = maxf(_shake_t, sec)


func layer() -> Node2D:
	return Game.main.fx_layer if Game.main else null


## A comic word that pops and floats up, in the pixel font.
func word(text: String, pos: Vector2, color: Color = Px.C.gold, size := 8) -> void:
	var l := layer()
	if l == null:
		return
	var w := FloatWord.new()
	w.text = text
	w.color = color
	w.size = size
	w.position = Vector2(roundi(pos.x - Px.text_w(text, size) / 2.0), roundi(pos.y))
	l.add_child(w)


## Throws n pixels of the given colours from pos. If collect is set, they fly
## to that node and are worth value pixels in total.
func burst(pos: Vector2, colors: Array, n := 24, collect: Node2D = null, value := 0, speed := 90.0) -> void:
	var l := layer()
	if l == null:
		return
	var p := PixelBurst.new()
	p.setup(pos, colors, n, collect, value, speed)
	l.add_child(p)


## Explodes a texture into its own pixels.
func shatter_tex(tex: Texture2D, top_left: Vector2, collect: Node2D = null, value := 0) -> void:
	var l := layer()
	if l == null or tex == null:
		return
	var p := PixelBurst.new()
	p.setup_from_image(tex.get_image(), top_left, collect, value)
	l.add_child(p)


## Blinks warning blocks on floor tiles for sec seconds. Await the returned node's done signal.
func telegraph(cells: Array, sec: float, color: Color = Px.C.red) -> Telegraph:
	var l := layer()
	var t := Telegraph.new()
	t.cells = cells
	t.life = sec
	t.color = color
	if l:
		l.add_child(t)
	Audio.play("tele", 0.0)
	return t


func flash(color: Color = Color.WHITE, sec := 0.1) -> void:
	if Game.main == null:
		return
	if Game.opts.reduce_flash:
		color.a *= 0.3
		sec *= 2.0
	Game.main.flash(color, sec)


func transition(mid: Callable) -> void:
	if Game.main:
		Game.main.mosaic_transition(mid)
	else:
		mid.call()


# ---------------------------------------------------------------- helpers

class FloatWord extends Node2D:
	var text := ""
	var color := Color.WHITE
	var size := 8
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		if t > 0.12:
			position.y -= delta * 24.0
		if t > 0.8:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		if t > 0.6 and int(t * 30) % 2 == 0:
			return
		var s := size * 2 if t < 0.08 else size
		var off := Vector2.ZERO
		if s != size:
			off = Vector2(-Px.text_w(text, size) / 2.0, -4)
		Px.text(self, text, off.round(), color, s)


class PixelBurst extends Node2D:
	var parts := []   # each: [pos, vel, color, life]
	var target: Node2D = null
	var value := 0
	var t := 0.0
	var paid := false

	func setup(pos: Vector2, colors: Array, n: int, collect: Node2D, val: int, speed: float) -> void:
		target = collect
		value = val
		for i in n:
			var a := randf() * TAU
			var v := Vector2(cos(a), sin(a)) * randf_range(speed * 0.3, speed)
			parts.append([pos, v, colors[i % colors.size()], randf_range(0.4, 0.9)])

	func setup_from_image(im: Image, tl: Vector2, collect: Node2D, val: int) -> void:
		target = collect
		value = val
		var c := tl + Vector2(im.get_width(), im.get_height()) / 2.0
		for y in im.get_height():
			for x in im.get_width():
				var col := im.get_pixel(x, y)
				if col.a > 0.5:
					var p := tl + Vector2(x, y)
					var v := (p - c).normalized() * randf_range(30, 110) + Vector2(0, -30)
					parts.append([p, v, col, randf_range(0.5, 1.1)])

	func _process(delta: float) -> void:
		t += delta
		var alive := 0
		for p in parts:
			if p[3] <= 0.0:
				continue
			alive += 1
			if target and is_instance_valid(target) and t > 0.35:
				var to: Vector2 = target.global_position + Vector2(0, -6) - p[0]
				if to.length() < 6.0:
					p[3] = 0.0
					continue
				p[1] = p[1].lerp(to.normalized() * 260.0, clampf(delta * 8.0, 0.0, 1.0))
			else:
				p[1] *= pow(0.05, delta)
				p[3] -= delta
			p[0] += p[1] * delta
		if target and value > 0 and not paid and t > 0.6:
			paid = true
			Game.add_pixels(value)
			Audio.coin()
		if alive == 0 or t > 3.0:
			if target and value > 0 and not paid:
				Game.add_pixels(value)
			queue_free()
		queue_redraw()

	func _draw() -> void:
		for p in parts:
			if p[3] > 0.0:
				draw_rect(Rect2(p[0].round(), Vector2.ONE), p[2])


class Telegraph extends Node2D:
	signal done
	var cells := []
	var life := 0.5
	var color := Color.RED
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		if t >= life:
			done.emit()
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var on := int(t * 10.0) % 2 == 0
		for c in cells:
			var r := Rect2(Vector2(c.x * 16, Px.TOP + c.y * 16), Vector2(16, 16))
			if on:
				draw_rect(r.grow(-2), Color(color, 0.55))
				draw_rect(r.grow(-2), Px.C.tele, false, 1.0)
			else:
				draw_rect(r.grow(-5), Color(color, 0.35))
