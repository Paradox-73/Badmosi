extends Minigame
## Symphony: piano tiles. Each correct press plays the melody's next note,
## so the player performs Ode to Joy (public domain). Speed rises every 16 tiles.

const KEYS := [[KEY_D, KEY_LEFT], [KEY_F, KEY_DOWN], [KEY_J, KEY_UP], [KEY_K, KEY_RIGHT]]
const KEY_NAMES := ["D", "F", "J", "K"]
# Ode to Joy: MIDI notes and lengths in beats.
const MELODY := [
	[64, 1], [64, 1], [65, 1], [67, 1], [67, 1], [65, 1], [64, 1], [62, 1],
	[60, 1], [60, 1], [62, 1], [64, 1], [64, 1.5], [62, 0.5], [62, 2],
	[64, 1], [64, 1], [65, 1], [67, 1], [67, 1], [65, 1], [64, 1], [62, 1],
	[60, 1], [60, 1], [62, 1], [64, 1], [62, 1.5], [60, 0.5], [60, 2],
	[62, 1], [62, 1], [64, 1], [60, 1], [62, 1], [64, 0.5], [65, 0.5], [64, 1], [60, 1],
	[62, 1], [64, 0.5], [65, 0.5], [64, 1], [62, 1], [60, 1], [62, 1], [55, 2],
	[64, 1], [64, 1], [65, 1], [67, 1], [67, 1], [65, 1], [64, 1], [62, 1],
	[60, 1], [60, 1], [62, 1], [64, 1], [62, 1.5], [60, 0.5], [60, 2],
]
const BAR_Y := 176.0
const COL_X := 116.0
const COL_W := 38

var tiles := []    # {t (arrival time), col, len, done, wrong}
var now := 0.0
var idx := 0
var correct := 0
var wrong := 0
var stop_t := 0.0
var speed := 70.0   # pixels per second
var pressed_col := -1
var press_t := 0.0
var _down := [false, false, false, false]


func info() -> Dictionary:
	return {"goal": "PLAY THE MELODY: PRESS EACH TILE'S COLUMN AS IT REACHES THE BAR",
		"keys": ["D F J K  OR  ARROW KEYS"], "time": 60.0}


func uses_timer() -> bool:
	return false


static func col_for(midi: int) -> int:
	match midi:
		55, 60: return 0
		62: return 1
		64: return 2
		_: return 3


func _ready() -> void:
	super._ready()
	var tt := 2.0
	var gap := 0.62
	var count := MELODY.size() if not short_round else 12
	for i in count:
		if i > 0 and i % 16 == 0:
			gap *= 0.88
		var m: Array = MELODY[i]
		tiles.append({"t": tt, "col": col_for(m[0]), "len": float(m[1]), "midi": m[0], "done": false})
		tt += gap * maxf(1.0, float(m[1])) if m[1] >= 1.0 else gap * 0.75
	speed = 70.0 / Game.time_mult() * (1.3 if short_round else 1.0)


func begin() -> void:
	Audio.stop_music()


func goal_text() -> String:
	return "SONG %d%%   WRONG NOTES %d" % [roundi(100.0 * idx / tiles.size()), wrong]


func _key_down(c: int) -> bool:
	for k in KEYS[c]:
		if Input.is_physical_key_pressed(k):
			return true
	return false


func tick(delta: float) -> void:
	press_t -= delta
	if stop_t > 0.0:
		stop_t -= delta
		return
	now += delta
	var window := 0.22 * Game.window_mult()
	for c in 4:
		var d := _key_down(c)
		if d and not _down[c]:
			_press(c, window)
		_down[c] = d
	# A tile that passes the bar unplayed is a wrong note.
	if idx < tiles.size() and now - tiles[idx].t > window:
		_wrong(tiles[idx].col)
	if idx >= tiles.size():
		var acc := float(correct) / tiles.size()
		finish(true, acc)


func _press(c: int, window: float) -> void:
	pressed_col = c
	press_t = 0.12
	if idx >= tiles.size():
		return
	var tile: Dictionary = tiles[idx]
	if tile.col == c and absf(now - tile.t) <= window:
		tile.done = true
		idx += 1
		correct += 1
		Audio.note(tile.midi, 0.25 + 0.2 * tile.len)
		Fx.burst(Vector2(COL_X + c * COL_W + COL_W / 2.0, BAR_Y), [Px.C.white, Px.C.gold], 10, null, 0, 60.0)
	elif absf(now - tile.t) <= window * 2.5:
		_wrong(c)


func _wrong(c: int) -> void:
	wrong += 1
	var tile: Dictionary = tiles[idx]
	tile.done = true
	idx += 1
	stop_t = 1.0
	penalty(10.0, "WRONG NOTE!", Vector2(Px.W / 2.0, 90))
	Fx.burst(Vector2(COL_X + c * COL_W + COL_W / 2.0, BAR_Y - 8), [Px.C.dark, Px.C.red, Px.C.white], 30)
	# Push the rest back so play resumes fairly after the stop.
	for i in range(idx, tiles.size()):
		tiles[i].t += 1.0


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.ink, 0.95))
	# Stage and keyboard frame.
	draw_rect(Rect2(COL_X - 4, 24, COL_W * 4 + 8, 192), Px.C.maroon.darkened(0.5))
	for c in 4:
		var x := COL_X + c * COL_W
		draw_rect(Rect2(x, 24, COL_W - 2, 192), Px.C.mist if c % 2 == 0 else Px.C.white)
		if pressed_col == c and press_t > 0.0:
			draw_rect(Rect2(x, BAR_Y - 2, COL_W - 2, 20), Px.C.gold)
		Px.text_c(self, KEY_NAMES[c], x + COL_W / 2.0 - 1, BAR_Y + 6, Px.C.slate)
	draw_rect(Rect2(COL_X - 4, BAR_Y - 2, COL_W * 4 + 8, 2), Px.C.red)
	for i in range(idx, mini(idx + 14, tiles.size())):
		var tile: Dictionary = tiles[i]
		var h: float = 22.0 * maxf(1.0, tile.len)
		var y: float = BAR_Y - (tile.t - now) * speed
		if y < 0:
			continue
		var x2: float = COL_X + tile.col * COL_W
		var r := Rect2(x2 + 1, roundf(y - h), COL_W - 4, h)
		draw_rect(r, Px.C.dark)
		draw_rect(r.grow(-1), Px.C.navy if i != idx else Px.C.ink)
		draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(4, 2)), Px.C.steel)
	# FEEDBACK on the side, and the crowd.
	var head := Px.char_tex(Clubs.get_club("symphony").head_look, "walk1" if int(t * 4) % 2 == 0 else "idle")
	draw_texture_rect(head, Rect2(Vector2(30, 120), head.get_size() * 2), false)
	Px.text_c(self, "FEEDBACK", 46, 166, Px.C.gold)
	var pix := Px.char_tex(Game.pix_look(), "idle")
	draw_texture_rect(pix, Rect2(Vector2(Px.W - 66, 124), pix.get_size() * 2), false)
	Px.text_c(self, "ODE TO JOY", Px.W - 52, 40, Px.C.mist)
	Px.text_c(self, "(L. VAN BEETHOVEN)", Px.W - 52, 50, Px.C.slate)
	if stop_t > 0.0:
		Px.text_c(self, "WRONG NOTE!", Px.W / 2.0, 100, Px.C.red, 16)
	draw_card()
