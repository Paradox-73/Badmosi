extends Node
## Root of the game. Owns the screen stack, the effect layers, the mosaic
## transition, the flash overlay and the pause menu. The game draws into a
## 384 x 216 SubViewport, shown at the largest whole-number scale that fits
## the window, through the CRT filter when it is on.

const SCREENS := {
	"title": "res://scripts/ui/title.gd",
	"menu": "res://scripts/ui/main_menu.gd",
	"options": "res://scripts/ui/options_screen.gd",
	"credits": "res://scripts/ui/credits.gd",
	"club_select": "res://scripts/ui/club_select.gd",
	"char_select": "res://scripts/ui/char_select.gd",
	"flashback": "res://scripts/story/flashback.gd",
	"opening": "res://scripts/story/opening.gd",
	"hub": "res://scripts/world/hub.gd",
	"club": "res://scripts/club_room.gd",
	"ending": "res://scripts/story/ending.gd",
	"calibrate": "res://scripts/ui/calibrate.gd",
	"how_to_play": "res://scripts/ui/how_to_play.gd",
	"slots": "res://scripts/ui/save_slots.gd",
}

var world: Node2D
var fx_layer: Node2D
var ui: CanvasLayer
var screen: Node = null
var screen_name := ""
var _mosaic: ColorRect
var _flash: ColorRect
var _palette: ColorRect
var _pause: CanvasLayer
var _busy := false
var _frame: SubViewportContainer
var _vp: SubViewport
var _crt := ShaderMaterial.new()


func _ready() -> void:
	Game.main = self
	_fit_window.call_deferred()
	_frame = SubViewportContainer.new()
	_frame.stretch = true
	_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_frame.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_frame)
	_vp = SubViewport.new()
	_vp.size = Vector2i(Px.W, Px.H)
	_vp.snap_2d_transforms_to_pixel = true
	_vp.snap_2d_vertices_to_pixel = true
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_frame.add_child(_vp)
	_crt.shader = load("res://shaders/crt.gdshader")
	get_tree().root.size_changed.connect(_fit_frame)
	_fit_frame()
	apply_crt()
	var tap := PauseTap.new()
	tap.main = self
	_vp.add_child(tap)

	world = Node2D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	_vp.add_child(world)
	fx_layer = Node2D.new()
	fx_layer.name = "FxLayer"
	fx_layer.z_index = 50
	world.add_child(fx_layer)
	ui = CanvasLayer.new()
	ui.layer = 45
	ui.process_mode = Node.PROCESS_MODE_PAUSABLE
	_vp.add_child(ui)

	var pal_layer := CanvasLayer.new()
	pal_layer.layer = 40
	_vp.add_child(pal_layer)
	_palette = _overlay_rect(load("res://shaders/palette.gdshader"))
	_palette.visible = false
	pal_layer.add_child(_palette)

	var top := CanvasLayer.new()
	top.layer = 90
	top.process_mode = Node.PROCESS_MODE_PAUSABLE
	_vp.add_child(top)
	_mosaic = _overlay_rect(load("res://shaders/mosaic.gdshader"))
	_mosaic.visible = false
	top.add_child(_mosaic)
	_flash = ColorRect.new()
	_flash.size = Vector2(Px.W, Px.H)
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_flash)

	_pause = preload("res://scripts/ui/pause_menu.gd").new()
	_vp.add_child(_pause)

	var first := "title"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screen="):
			first = a.substr(9)
	var args := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--club="):
			args["id"] = a.substr(7)
		if a == "--fight":
			args["fight"] = true
		if a.begins_with("--char="):
			Game.character = a.substr(7)
	_swap(first, args)


func _overlay_rect(sh: Shader) -> ColorRect:
	var r := ColorRect.new()
	r.size = Vector2(Px.W, Px.H)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = sh
	r.material = m
	return r


func change(name: String, args := {}) -> void:
	if _busy:
		return
	mosaic_transition(func(): _swap(name, args))


func _swap(name: String, args: Dictionary) -> void:
	get_tree().paused = false
	Fx.slowmo = 1.0
	set_palette([], 0.0)
	if screen:
		screen.queue_free()
		world.remove_child(screen)
	for c in ui.get_children():
		c.queue_free()
	for c in fx_layer.get_children():
		c.queue_free()
	_vp.canvas_transform = Transform2D()
	var s: Node = load(SCREENS[name]).new()
	screen = s
	screen_name = name
	if s.has_method("setup"):
		s.setup(args)
	world.add_child(s)
	world.move_child(fx_layer, -1)


func mosaic_transition(mid: Callable) -> void:
	_busy = true
	_mosaic.visible = true
	var m: ShaderMaterial = _mosaic.material
	var steps := [2.0, 4.0, 8.0, 16.0]
	if Game.opts.reduce_flash:
		steps = [2.0, 4.0]
	for b in steps:
		m.set_shader_parameter("block", b)
		await get_tree().create_timer(0.04, true, false, true).timeout
	_flash.color = Color(Px.C.ink, 1.0)
	mid.call()
	await get_tree().process_frame
	_flash.color = Color(1, 1, 1, 0)
	steps.reverse()
	for b in steps:
		m.set_shader_parameter("block", b)
		await get_tree().create_timer(0.04, true, false, true).timeout
	_mosaic.visible = false
	m.set_shader_parameter("block", 1.0)
	Audio.play("door", 0.0, -8.0)
	_busy = false


## Sets a full-screen mosaic block size directly (1 = off).
func set_mosaic(b: float) -> void:
	_mosaic.visible = b > 1.0
	(_mosaic.material as ShaderMaterial).set_shader_parameter("block", b)


func flash(color: Color, sec: float) -> void:
	_flash.color = color
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, sec)


## Applies a club's 4-colour palette over the screen. colors: 4 Colors.
func set_palette(colors: Array, amount: float) -> void:
	if colors.size() < 4 or amount <= 0.0:
		_palette.visible = false
		return
	var m: ShaderMaterial = _palette.material
	for i in 4:
		m.set_shader_parameter("c%d" % i, colors[i])
	m.set_shader_parameter("amount", amount)
	_palette.visible = true


## 1536 x 864 does not fit a 1366 x 768 or 1600 x 900 laptop. Shrink the window
## to the largest whole-number scale that fits the screen's free area.
func _fit_window() -> void:
	if OS.has_feature("web") or OS.has_feature("movie") or DisplayServer.get_name() == "headless" or Game.opts.get("fullscreen", false):
		return
	var free := DisplayServer.screen_get_usable_rect()
	var k := maxi(1, mini(floori(free.size.x / float(Px.W)), floori((free.size.y - 40) / float(Px.H))))
	var want := Vector2i(Px.W * k, Px.H * k)
	var win := get_window()
	if win.size.x > want.x or win.size.y > want.y:
		win.size = want
		win.position = free.position + (free.size - want) / 2


## Scales the game frame by the largest whole number that fits the window,
## so every game pixel stays a sharp square, and centres it.
func _fit_frame() -> void:
	var win := Vector2(get_tree().root.size)
	var k := maxi(1, mini(floori(win.x / Px.W), floori(win.y / Px.H)))
	_frame.stretch_shrink = k
	_frame.size = Vector2(Px.W * k, Px.H * k)
	_frame.position = ((win - _frame.size) / 2.0).floor()


## Applies the CRT options: on or off, and how far the screen bulges.
func apply_crt() -> void:
	_frame.material = _crt if Game.opts.get("crt", true) else null
	_crt.set_shader_parameter("curve", 0.004 * float(Game.opts.get("crt_curve", 3)))


## Alt-tabbing out or the browser tab losing focus pauses the game, so a fight
## or a minigame timer never runs on unattended.
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT] and not Game.autoplay and not OS.has_feature("movie"):
		if not get_tree().paused and screen and screen.get("pausable") == true and not _busy:
			_pause.open()


func pause_open() -> bool:
	return _pause != null and _pause.visible


## Opens the pause menu. Runs inside the game viewport, so menus that use
## Esc as "back" mark it handled first.
class PauseTap extends Node:
	var main: Node

	func _unhandled_input(e: InputEvent) -> void:
		if e.is_action_pressed("pause") and not get_tree().paused and main.screen and main.screen.get("pausable") == true and not main._busy:
			get_viewport().set_input_as_handled()
			main._pause.open()
