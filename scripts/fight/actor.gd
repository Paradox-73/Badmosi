class_name Actor
extends Node2D
## Shared body for Pix, club members and club heads: a sprite with hit flash,
## knockback, a shadow, and whole-pixel movement inside a Room.

const SPRITE_SHADER := preload("res://shaders/sprite.gdshader")

var fight: Node = null
var room: Room = null
var sprite: Sprite2D
var mat: ShaderMaterial
var look := {}
var hp := 10.0
var max_hp := 10.0
var vel := Vector2.ZERO
var knock := Vector2.ZERO
var facing := Vector2.RIGHT
var flash_t := 0.0
var he := Vector2(5, 3)
var anim_t := 0.0
var dead := false
var downscale_t := 0.0
var slow_t := 0.0


func _init() -> void:
	sprite = Sprite2D.new()
	sprite.centered = true
	mat = ShaderMaterial.new()
	mat.shader = SPRITE_SHADER
	sprite.material = mat
	add_child(sprite)


func set_look(l: Dictionary) -> void:
	look = l
	_frame("idle")


func _frame(f: String) -> void:
	var t := Px.char_tex(look, f)
	sprite.texture = t
	sprite.offset = Vector2(0, -t.get_height() / 2.0)


func step_anim(delta: float, moving: bool) -> void:
	anim_t += delta
	if moving:
		_frame("walk1" if int(anim_t * 8.0) % 2 == 0 else "walk2")
	else:
		_frame("idle")
	if absf(facing.x) > 0.1:
		sprite.flip_h = facing.x < 0


func tick_effects(delta: float) -> void:
	if flash_t > 0.0:
		flash_t -= delta
	mat.set_shader_parameter("flash", 1.0 if flash_t > 0.0 else 0.0)
	if downscale_t > 0.0:
		downscale_t -= delta
	mat.set_shader_parameter("blocks", 4.0 if downscale_t > 0.0 else 1.0)
	if slow_t > 0.0:
		slow_t -= delta
	if knock.length() > 1.0:
		position = room.move(position, knock * delta, he) if room else position + knock * delta
		knock = knock.move_toward(Vector2.ZERO, 600.0 * delta)
	else:
		knock = Vector2.ZERO


func move_by(motion: Vector2) -> void:
	if room:
		position = room.move(position, motion, he)
	else:
		position += motion


func center() -> Vector2:
	return position + Vector2(0, -7)


func hurtbox() -> Rect2:
	return Rect2(position + Vector2(-6, -14), Vector2(12, 14))


func _draw() -> void:
	# Pixel shadow under the feet.
	draw_rect(Rect2(-5, -1, 10, 2), Color(Px.C.dark, 0.5))
