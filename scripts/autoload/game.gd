extends Node
## Run state (Attendance, Proxies, pixels, SEM, club cards), options,
## the input map, and screen changes.

signal detained
signal proxy_used
signal stats_changed

const SAVE_PATH := "user://save.json"  # the old single save, moved into slot 1
const SLOTS := 3
const OPTS_PATH := "user://options.json"
const DIFFS := ["HD", "SD", "8-BIT"]
const SPECIALS := [
	{"id": "downscale", "name": "DOWNSCALE", "cards": 0, "cost": 5},
	{"id": "spin", "name": "SPIN MOVE", "cards": 3, "cost": 4},
	{"id": "bass", "name": "BASS DROP", "cards": 6, "cost": 5},
	{"id": "redpen", "name": "RED PEN", "cards": 9, "cost": 8},
	{"id": "pi", "name": "PI SHIELD", "cards": 12, "cost": 6},
]

## Short-lived boosts from campus food. Each lasts until the next club is over.
const BUFFS := {
	"speed": {"name": "COLD COFFEE", "desc": "+25% MOVE SPEED"},
	"power": {"name": "TRUFFLES ORDER", "desc": "+25% FIGHT DAMAGE"},
	"guard": {"name": "CAPPUCCINO", "desc": "-25% ATTENDANCE LOSS"},
	"upset": {"name": "PET KHARAB", "desc": "-25% MOVE SPEED, WASHROOM BREAKS"},
}

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
var character := "kanav" # Roster id of the player's character
var buffs := {}          # buff id -> clubs left (see BUFFS)
var tallies := {}        # run counters for the end-of-sem summary
var dhairya := 100.0     # Sachan's patience meter
var rage_t := 0.0        # seconds of Sachan's rage left
var run_time := 0.0      # seconds played this run, for the speedrun timer
var speedrun := false    # shows the timer and keeps a best time
var practice := false    # true when a club was opened from club select
var autoplay := false    # --autoplay: scenes advance themselves, for frame captures
var truffles_t := -1.0   # seconds until a Truffles order leaves the gate, -1 when none
var order_item := ""     # what the rider is bringing: TRUFFLES or JUICY
var slot := 1            # save slot this run writes to, 1..SLOTS

# Settings
var difficulty := 1
var assist_invincible := false
var assist_double := false
var opts := {
	"music": 0.7, "sfx": 0.8, "clean_text": false, "shake": true,
	"reduce_flash": false, "fullscreen": false, "rhythm_offset": 0, "crt": true,
	"crt_curve": 3,
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
		# Menus read accept/cancel, fights read attack/dodge/dash. On a keyboard
		# they share keys; on a pad A confirms and dashes, B backs out and dodges.
		"accept": [KEY_J, KEY_Z, KEY_ENTER, KEY_SPACE], "cancel": [KEY_K, KEY_X],
		"dash": [],
	}
	var pads := {
		"left": [JOY_BUTTON_DPAD_LEFT], "right": [JOY_BUTTON_DPAD_RIGHT],
		"up": [JOY_BUTTON_DPAD_UP], "down": [JOY_BUTTON_DPAD_DOWN],
		"attack": [JOY_BUTTON_X], "dodge": [JOY_BUTTON_B], "dash": [JOY_BUTTON_A],
		"special": [JOY_BUTTON_Y], "switch": [JOY_BUTTON_RIGHT_SHOULDER], "pause": [JOY_BUTTON_START],
		"accept": [JOY_BUTTON_A], "cancel": [JOY_BUTTON_B],
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
			jb.device = -1    # any controller, not only the first one
			InputMap.action_add_event(action, jb)
	var axes := {"left": [JOY_AXIS_LEFT_X, -1.0], "right": [JOY_AXIS_LEFT_X, 1.0],
		"up": [JOY_AXIS_LEFT_Y, -1.0], "down": [JOY_AXIS_LEFT_Y, 1.0]}
	for action in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = axes[action][0]
		jm.axis_value = axes[action][1]
		jm.device = -1
		InputMap.action_add_event(action, jm)


## Movement snapped to 8 directions. A stick pushed "up" is never exactly up,
## and the leftover sideways part made players drift while walking straight.
func move_vec() -> Vector2:
	var v := Input.get_vector("left", "right", "up", "down")
	if v.length() < 0.1:
		return Vector2.ZERO
	var d := Vector2.from_angle(snappedf(v.angle(), PI / 4.0))
	return Vector2(snappedf(d.x, 0.001), snappedf(d.y, 0.001)) * minf(v.length(), 1.0)


## True after the last input came from a gamepad: on-screen prompts then
## name pad buttons (Xbox layout) instead of keys.
var pad := false
var _pad_cache := {}
const PAD_NAMES := {"J": "X", "K": "B", "L": "Y", "I": "RB", "F": "LT+RT"}


## Flip the table: F on a keyboard, or both triggers held on a pad.
func fit_held() -> bool:
	if Input.is_action_pressed("fit"):
		return true
	for dev in Input.get_connected_joypads():
		if Input.get_joy_axis(dev, JOY_AXIS_TRIGGER_LEFT) > 0.5 and Input.get_joy_axis(dev, JOY_AXIS_TRIGGER_RIGHT) > 0.5:
			return true
	return false


func _input(e: InputEvent) -> void:
	if e is InputEventJoypadButton or (e is InputEventJoypadMotion and absf(e.axis_value) > 0.5):
		pad = true
	elif e is InputEventKey or e is InputEventMouseButton:
		pad = false


## Rewrites keyboard prompts in s for a gamepad: "J:" becomes "X:", ESC becomes START.
func pad_text(s: String) -> String:
	if _pad_cache.has(s):
		return _pad_cache[s]
	var out := s
	# Menu prompts first: there J means confirm, which is A on a pad.
	for pair in [["J/ENTER", "A"], ["K/ESC", "B"], ["J: PLAY AS", "A: PLAY AS"], ["J NEXT", "A NEXT"], ["J: NEXT", "A: NEXT"],
			["J >", "A >"], ["J>", "A>"], ["PRESS J.", "PRESS A."], ["ARROWS/WASD", "STICK"], ["WASD OR ARROWS", "STICK"],
			["ENTER OR J", "X"], ["BACKSPACE OR K", "B"], ["J OR CLICK", "X"], ["MOVE THE CURSOR AND PRESS J", "MOVE THE CURSOR AND PRESS X"],
			["K: DODGE", "A/B: DASH"], ["ARROWS:", "STICK:"], ["ESC:", "START:"], ["ESC ", "START "], ["HOLD F", "HOLD LT+RT"], ["PRESS I ", "PRESS RB "], ["PRESS L ", "PRESS Y "]]:
		out = out.replace(pair[0], pair[1])
	var re := RegEx.create_from_string("(^|[ (])([JKLI])(?=:|[.]|$| >| [(])")  # F only via "HOLD F": it also starts the censored word
	var m := re.search(out)
	while m:
		var key := m.get_string(2)
		if key == "I" and m.get_end(2) < out.length() and out[m.get_end(2)] != ":":
			m = re.search(out, m.get_end(2))
			continue
		out = out.substr(0, m.get_start(2)) + PAD_NAMES[key] + out.substr(m.get_end(2))
		m = re.search(out, m.get_start(2) + PAD_NAMES[key].length())
	for k in ["J", "K", "L"]:
		out = out.replace("PRESS " + k + " ", "PRESS " + PAD_NAMES[k] + " ").replace("PRESS " + k + ".", "PRESS " + PAD_NAMES[k] + ".")
		if out.ends_with("PRESS " + k):
			out = out.trim_suffix(k) + PAD_NAMES[k]
	_pad_cache[s] = out
	return out


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
	return [1.5, 1.0, 0.7][difficulty] * (1.0 + stat("window"))


## Multiplier on minigame timers.
func time_mult() -> float:
	return [1.5, 1.0, 0.75][difficulty] * (1.0 + stat("time"))


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
	buffs = {}
	tallies = {}
	dhairya = 100.0
	rage_t = 0.0
	run_time = 0.0
	truffles_t = -1.0
	practice = false
	stats_changed.emit()


## Loses Attendance. pct is a percentage before modifiers.
	order_item = ""
func hurt(pct: float) -> void:
	if assist_invincible or pct <= 0.0:
		return
	var loss := pct * dmg_mult() * pow(0.95, sem - 1) * (1.0 - stat("guard"))
	if has_buff("guard"):
		loss *= 0.75
	if quirk() == "dhairya" and rage_t <= 0.0:
		dhairya = maxf(0.0, dhairya - loss * 2.5)
		if dhairya <= 0.0:
			rage_t = 6.0
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
	if n > 0:
		n = roundi(n * (1.0 + stat("px")))
	pixels = maxi(0, pixels + n)
	stats_changed.emit()


func add_hype(n: int) -> void:
	hype = clampi(hype + n, 0, 10)
	stats_changed.emit()


func player_dmg_mult() -> float:
	var m := (1.0 + 0.1 * (sem - 1)) * (2.0 if assist_double else 1.0) * (1.0 + stat("dmg"))
	if has_buff("power"):
		m *= 1.25
	if rage_t > 0.0:
		m *= 2.0
	return m


func speed_mult() -> float:
	var m := 1.0 + stat("speed")
	if has_buff("speed"):
		m += 0.25
	if has_buff("upset"):
		m -= 0.25
	if rage_t > 0.0:
		m += 0.3
	return m


# ---------------------------------------------------------------- character

func char_data() -> Dictionary:
	return Roster.get_char(character)


func char_name() -> String:
	return char_data().name


## The perk value for a key (see Roster): the character's own plus every
## freed club's.
func stat(key: String) -> float:
	var v := float(char_data().perks.get(key, 0.0))
	for id in cards:
		v += float(Clubs.ALLIES.get(id, {}).get("perks", {}).get(key, 0.0))
	return v


func ally(id: String) -> bool:
	return cards.has(id)


## True when any freed club gives this ally effect (see Clubs.ALLIES).
func ally_effect(effect: String) -> bool:
	for id in cards:
		if Clubs.ALLIES.get(id, {}).get("effect", "") == effect:
			return true
	return false


## Takes a fine in pixels. DebSoc, once freed, argues it down by half.
func fine(px: int) -> int:
	if ally_effect("fine_half"):
		px /= 2
	add_pixels(-px)
	tally("fines", px)
	return px


func quirk() -> String:
	return char_data().get("quirk", "")


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if main and main.screen_name in ["hub", "club", "opening"] and not practice:
		run_time += delta
	if rage_t > 0.0:
		rage_t -= delta
		if rage_t <= 0.0:
			dhairya = 100.0
	elif quirk() == "dhairya" and dhairya < 100.0:
		dhairya = minf(100.0, dhairya + delta)


# ---------------------------------------------------------------- buffs and counters

func add_buff(id: String, clubs := 1) -> void:
	buffs[id] = maxi(int(buffs.get(id, 0)), clubs)
	stats_changed.emit()


func has_buff(id: String) -> bool:
	return int(buffs.get(id, 0)) > 0


## Called when a club visit ends, won or lost: every buff loses one club.
func end_club_buffs() -> void:
	for k in buffs.keys():
		buffs[k] = int(buffs[k]) - 1
		if buffs[k] <= 0:
			buffs.erase(k)
	stats_changed.emit()


## A run time as M:SS.cc.
static func clock(sec: float) -> String:
	return "%d:%05.2f" % [int(sec) / 60, fmod(sec, 60.0)]


## Adds n to a run counter: fines, caught, flips, detained and so on.
func tally(key: String, n := 1) -> void:
	tallies[key] = int(tallies.get(key, 0)) + n


func is_detained() -> bool:
	return attendance <= 0.0 and proxies <= 0


func card_count() -> int:
	return cards.size()


## Cards from the thirteen main clubs only: no side clubs, SAC or Admin.
func club_card_count() -> int:
	var n := 0
	for k in cards:
		if k in Clubs.ORDER:
			n += 1
	return n


## Signature specials replace Downscale for the characters that have one.
const SIGNATURES := {
	"cartwheel": {"id": "cartwheel", "name": "CARTWHEEL", "cards": 0, "cost": 4},
	"blackhole": {"id": "blackhole", "name": "BLACK HOLE", "cards": 0, "cost": 6},
}


func unlocked_specials() -> Array:
	var out := []
	for s in SPECIALS:
		if card_count() >= s.cards:
			out.append(s)
	if SIGNATURES.has(quirk()):
		out[0] = SIGNATURES[quirk()]
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
	if first:
		if ally_effect("heal_on_free"):
			heal(15)
		if Clubs.ALLIES.get(id, {}).get("effect", "") == "proxy":
			proxies += 1
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


## The player character's look.
func pix_look() -> Dictionary:
	return char_data().look


# ---------------------------------------------------------------- saving

func save_run() -> void:
	if practice:
		return
	var d := {"attendance": attendance, "proxies": proxies, "pixels": pixels,
		"credits": credits, "sem": sem, "cards": cards, "difficulty": difficulty,
		"character": character, "buffs": buffs, "tallies": tallies,
		"run_time": run_time, "speedrun": speedrun, "order": [truffles_t, order_item]}
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func slot_path(n: int) -> String:
	return "user://save_%d.json" % n


## True when slot n holds a run. The old single save.json becomes slot 1.
func slot_used(n: int) -> bool:
	if n == 1 and FileAccess.file_exists(SAVE_PATH) and not FileAccess.file_exists(slot_path(1)):
		DirAccess.rename_absolute(SAVE_PATH, slot_path(1))
	return FileAccess.file_exists(slot_path(n))


## True when any slot holds a run.
func has_save() -> bool:
	for n in range(1, SLOTS + 1):
		if slot_used(n):
			return true
	return false


## The saved run in slot n, or {} when the slot is empty or unreadable.
func slot_data(n: int) -> Dictionary:
	if not slot_used(n):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(slot_path(n)))
	return d if typeof(d) == TYPE_DICTIONARY else {}


func delete_slot(n: int) -> void:
	if slot_used(n):
		DirAccess.remove_absolute(slot_path(n))


## Loads slot n and makes it the slot that save_run writes to.
func load_run(n := slot) -> bool:
	var d := slot_data(n)
	if d.is_empty():
		return false
	slot = n
	attendance = maxf(30.0, float(d.get("attendance", 100)))
	proxies = int(d.get("proxies", 1))
	pixels = int(d.get("pixels", 0))
	credits = int(d.get("credits", 0))
	sem = int(d.get("sem", 1))
	cards = d.get("cards", {})
	difficulty = int(d.get("difficulty", 1))
	character = str(d.get("character", "kanav"))
	buffs = d.get("buffs", {})
	tallies = d.get("tallies", {})
	run_time = float(d.get("run_time", 0.0))
	speedrun = bool(d.get("speedrun", false))
	practice = false
	stats_changed.emit()
	return true


	# A paid phone order belongs to its run: it comes back with the save, and a
	# different slot never receives it.
	var order: Array = d.get("order", [-1.0, ""])
	truffles_t = float(order[0])
	order_item = str(order[1])
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
	if main:
		main.apply_crt()
