extends Node
## Run state (Attendance, Proxies, pixels, SEM, club cards), options,
## the input map, and screen changes.

signal detained
signal proxy_used
signal stats_changed

const SAVE_PATH := "user://save.json"
const OPTS_PATH := "user://options.json"
const DIFFS := ["HD", "SD", "8-BIT"]
const SPECIALS := [
	{"id": "downscale", "name": "DOWNSCALE", "cards": 0, "cost": 5},
	{"id": "spin", "name": "SPIN MOVE", "cards": 3, "cost": 4},
	{"id": "bass", "name": "BASS DROP", "cards": 6, "cost": 5},
	{"id": "redpen", "name": "RED PEN", "cards": 9, "cost": 8},
	{"id": "pi", "name": "PI SHIELD", "cards": 12, "cost": 6},
]

var main: Node = null

# Run state
var attendance := 100.0
var proxies := 1
var pixels := 0
var credits := 0
var sem := 1
var hype := 0
var special_idx := 0
var cards := {}          # club id -> "straight" or "flipped"
var practice := false    # true when a club was opened from club select
var autoplay := false    # --autoplay: scenes advance themselves, for frame captures

# Settings
var difficulty := 1
var assist_invincible := false
var assist_double := false
var opts := {
	"music": 0.7, "sfx": 0.8, "clean_text": false, "shake": true,
	"reduce_flash": false, "fullscreen": false, "rhythm_offset": 0, "hoodie": 0,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	autoplay = "--autoplay" in OS.get_cmdline_user_args()
	load_options()


# ---------------------------------------------------------------- input map

func _setup_input() -> void:
	var map := {
		"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT],
		"up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
		"attack": [KEY_J, KEY_Z, KEY_ENTER, KEY_SPACE], "dodge": [KEY_K, KEY_X],
		"special": [KEY_L, KEY_C], "switch": [KEY_I, KEY_V],
		"fit": [KEY_F], "pause": [KEY_ESCAPE, KEY_P],
		"fullscreen": [KEY_F11],
	}
	var pads := {
		"left": [JOY_BUTTON_DPAD_LEFT], "right": [JOY_BUTTON_DPAD_RIGHT],
		"up": [JOY_BUTTON_DPAD_UP], "down": [JOY_BUTTON_DPAD_DOWN],
		"attack": [JOY_BUTTON_X], "dodge": [JOY_BUTTON_A], "special": [JOY_BUTTON_Y],
		"switch": [JOY_BUTTON_RIGHT_SHOULDER], "fit": [JOY_BUTTON_BACK], "pause": [JOY_BUTTON_START],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.3)
		for k in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
		for b in pads.get(action, []):
			var jb := InputEventJoypadButton.new()
			jb.button_index = b
			InputMap.action_add_event(action, jb)
	var axes := {"left": [JOY_AXIS_LEFT_X, -1.0], "right": [JOY_AXIS_LEFT_X, 1.0],
		"up": [JOY_AXIS_LEFT_Y, -1.0], "down": [JOY_AXIS_LEFT_Y, 1.0]}
	for action in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = axes[action][0]
		jm.axis_value = axes[action][1]
		InputMap.action_add_event(action, jm)


func move_vec() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("fullscreen"):
		opts.fullscreen = not opts.fullscreen
		apply_options()
		save_options()


# ---------------------------------------------------------------- screens

func goto(screen: String, args := {}) -> void:
	if main:
		main.change(screen, args)


# ---------------------------------------------------------------- difficulty

func diff_name() -> String:
	return DIFFS[difficulty]


## Multiplier on Attendance losses and enemy damage.
func dmg_mult() -> float:
	return [0.5, 1.0, 1.5][difficulty]


## Multiplier on timing windows.
func window_mult() -> float:
	return [1.5, 1.0, 0.7][difficulty]


## Multiplier on minigame timers.
func time_mult() -> float:
	return [1.5, 1.0, 0.75][difficulty]


func max_attackers() -> int:
	return 3 if difficulty == 2 else 2


# ---------------------------------------------------------------- run state

func new_run() -> void:
	attendance = 100.0
	proxies = 3 if difficulty == 0 else 1
	pixels = 0
	credits = 0
	sem = 1
	hype = 0
	special_idx = 0
	cards = {}
	practice = false
	stats_changed.emit()


## Loses Attendance. pct is a percentage before modifiers.
func hurt(pct: float) -> void:
	if assist_invincible or pct <= 0.0:
		return
	var loss := pct * dmg_mult() * pow(0.95, sem - 1)
	attendance = maxf(0.0, attendance - loss)
	stats_changed.emit()
	if attendance <= 0.0:
		if proxies > 0:
			proxies -= 1
			attendance = 50.0
			proxy_used.emit()
			stats_changed.emit()
		else:
			detained.emit()


func heal(pct: float) -> void:
	attendance = minf(100.0, attendance + pct)
	stats_changed.emit()


func add_pixels(n: int) -> void:
	pixels = maxi(0, pixels + n)
	stats_changed.emit()


func add_hype(n: int) -> void:
	hype = clampi(hype + n, 0, 10)
	stats_changed.emit()


func player_dmg_mult() -> float:
	return (1.0 + 0.1 * (sem - 1)) * (2.0 if assist_double else 1.0)


func is_detained() -> bool:
	return attendance <= 0.0 and proxies <= 0


func card_count() -> int:
	return cards.size()


## Cards from the thirteen clubs only, without the SAC and the Admin.
func club_card_count() -> int:
	var n := 0
	for k in cards:
		if not k in ["sac", "admin"]:
			n += 1
	return n


func unlocked_specials() -> Array:
	var out := []
	for s in SPECIALS:
		if card_count() >= s.cards:
			out.append(s)
	return out


func current_special() -> Dictionary:
	var u := unlocked_specials()
	return u[special_idx % u.size()]


func cycle_special() -> void:
	special_idx = (special_idx + 1) % unlocked_specials().size()
	stats_changed.emit()


## Records a beaten club. how is "straight" or "flipped". Returns true on SEM UP.
func beat_club(id: String, how: String) -> bool:
	var first := not cards.has(id)
	cards[id] = how
	credits += 100
	var up := false
	if first and sem < 8:
		sem += 1
		up = true
	stats_changed.emit()
	save_run()
	return up


func straight_count() -> int:
	var n := 0
	for k in cards:
		if cards[k] == "straight":
			n += 1
	return n


func flipped_count() -> int:
	return cards.size() - straight_count()


## Words for the F-it switch, censored or clean.
func fit_words() -> String:
	return "FORGET IT!" if opts.clean_text else "F*** IT!"


## Hoodie colours for Pix: [cloth, shade]. Chosen in Options.
const HOODIES := [["gold", "orange"], ["cyan", "teal"], ["pink", "maroon"], ["lime", "green"], ["violet", "plum"], ["white", "mist"]]


func pix_look() -> Dictionary:
	var h: Array = HOODIES[int(opts.get("hoodie", 0)) % HOODIES.size()]
	return {"hair": "brown", "skin": "skin2", "cloth": h[0], "shade": h[1],
		"accent": "pink" if h[0] != "pink" else "cyan", "pants": "navy", "shoes": "white"}


# ---------------------------------------------------------------- saving

func save_run() -> void:
	if practice:
		return
	var d := {"attendance": attendance, "proxies": proxies, "pixels": pixels,
		"credits": credits, "sem": sem, "cards": cards, "difficulty": difficulty}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_run() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return false
	attendance = maxf(30.0, float(d.get("attendance", 100)))
	proxies = int(d.get("proxies", 1))
	pixels = int(d.get("pixels", 0))
	credits = int(d.get("credits", 0))
	sem = int(d.get("sem", 1))
	cards = d.get("cards", {})
	difficulty = int(d.get("difficulty", 1))
	practice = false
	stats_changed.emit()
	return true


func save_options() -> void:
	var f := FileAccess.open(OPTS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(opts))


func load_options() -> void:
	if FileAccess.file_exists(OPTS_PATH):
		var f := FileAccess.open(OPTS_PATH, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text())
		if typeof(d) == TYPE_DICTIONARY:
			for k in d:
				opts[k] = d[k]
	apply_options.call_deferred()


func apply_options() -> void:
	if not DisplayServer.get_name() == "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if opts.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
	if has_node("/root/Audio"):
		get_node("/root/Audio").apply_volumes()
