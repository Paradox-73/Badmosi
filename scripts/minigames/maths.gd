extends Minigame
## Pioneers: type the answer and press Enter. 8 right in 60 s, then a bonus:
## make 404 from six numbers, checked with Godot's Expression class.

const WORD := [
	["A CHAI COSTS 30 PX. HOW MUCH FOR 4 CHAIS?", 120],
	["SYNERGY HAS 3 DAYS OF 8 EVENTS EACH. HOW MANY EVENTS?", 24],
	["A 16 X 16 SPRITE HAS HOW MANY PIXELS?", 256],
	["ROOM 404 MINUS ROOM 400 IS ROOM...?", 4],
	["A PUFF IS 60 PX. YOU HAVE 200 PX. HOW MANY PUFFS?", 3],
	["THE CANTEEN SHUTS AT 2 AM. IT IS 11 PM. HOURS LEFT?", 3],
	["12 CLUBS, 5 MEMBERS EACH. HOW MANY MEMBERS?", 60],
	["384 PIXELS WIDE, 16 PER TILE. HOW MANY TILES?", 24],
	["A SONG IS 120 BEATS PER MINUTE. BEATS IN 30 SECONDS?", 60],
	["90% ATTENDANCE OF 40 CLASSES IS HOW MANY?", 36],
]
const PUZZLES := [
	[100, 25, 4, 3, 2, 1],
	[50, 8, 4, 2, 6, 10],
	[75, 5, 9, 7, 3, 1],
	[25, 16, 4, 10, 2, 6],
]

var q := ""
var ans := 0
var typed := ""
var right := 0
var asked := 0
var bonus_mode := false
var nums := []
var feedback := ""
var feedback_t := 0.0
var rng := RandomNumberGenerator.new()
var need := 8
var word_pool := []


func info() -> Dictionary:
	return {"goal": "8 RIGHT ANSWERS IN 60 SECONDS. THEN THE 404 BONUS.",
		"keys": ["TYPE NUMBERS, BACKSPACE, ENTER"], "time": 60.0}


func _ready() -> void:
	super._ready()
	rng.randomize()
	word_pool = WORD.duplicate()
	word_pool.shuffle()
	if short_round:
		need = 2


func begin() -> void:
	_new_q()


func goal_text() -> String:
	if bonus_mode:
		return "BONUS: MAKE 404   TIME %d" % ceili(time_left)
	return "CORRECT %d/%d   TIME %d" % [right, need, ceili(time_left)]


func _new_q() -> void:
	typed = ""
	asked += 1
	var kind := rng.randi() % 6
	if asked % 3 == 0 and not word_pool.is_empty():
		kind = 6
	match kind:
		0:
			var a := rng.randi_range(12, 99)
			var b := rng.randi_range(12, 99)
			q = "%d + %d" % [a, b]
			ans = a + b
		1:
			var a2 := rng.randi_range(3, 12)
			var b2 := rng.randi_range(3, 12)
			q = "%d X %d" % [a2, b2]
			ans = a2 * b2
		2:
			var a3 := rng.randi_range(4, 20)
			q = "%d SQUARED" % a3
			ans = a3 * a3
		3:
			var p: int = [10, 20, 25, 50, 75][rng.randi() % 5]
			var base: int = [40, 80, 120, 200, 400][rng.randi() % 5]
			q = "%d%% OF %d" % [p, base]
			ans = p * base / 100
		4:
			var s := rng.randi_range(2, 9)
			var st := rng.randi_range(1, 20)
			q = "%d, %d, %d, %d, ?" % [st, st + s, st + 2 * s, st + 3 * s]
			ans = st + 4 * s
		5:
			var a4 := rng.randi_range(50, 200)
			var b4 := rng.randi_range(10, a4 - 1)
			q = "%d - %d" % [a4, b4]
			ans = a4 - b4
		6:
			var w: Array = word_pool.pop_back()
			q = w[0]
			ans = w[1]


func _unhandled_input(e: InputEvent) -> void:
	if not running or over or not (e is InputEventKey) or not e.pressed:
		return
	var k: InputEventKey = e
	if k.keycode == KEY_BACKSPACE:
		typed = typed.substr(0, maxi(0, typed.length() - 1))
	elif k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
		_submit()
	else:
		var ch := char(k.unicode) if k.unicode > 0 else ""
		var allowed := "0123456789" if not bonus_mode else "0123456789+-*/() xX"
		if ch != "" and allowed.find(ch) >= 0 and typed.length() < 32:
			typed += "*" if ch in ["x", "X"] and bonus_mode else ch
			Audio.play("type", 0.1)
		else:
			return
	get_viewport().set_input_as_handled()


func _submit() -> void:
	if typed.strip_edges() == "":
		return
	if bonus_mode:
		_check_404()
		return
	if int(typed) == ans:
		right += 1
		Audio.play("right", 0.0)
		Fx.word("QED!", Vector2(Px.W / 2.0, 120), Px.C.lime)
		if right >= need and short_round:
			finish(true, 1.0)
			return
		if right >= need:
			_start_bonus()
			return
	else:
		penalty(10.0, "WRONG! IT WAS %d" % ans, Vector2(Px.W / 2.0, 120))
	_new_q()


func _start_bonus() -> void:
	bonus_mode = true
	typed = ""
	nums = PUZZLES[rng.randi() % PUZZLES.size()].duplicate()
	time_left = maxf(time_left, 0.0) + 25.0
	time_total = time_left
	Audio.play("sting", 0.0)


## Valid if it uses only the given numbers, each at most once, and equals 404.
static func check_expr(text: String, given: Array) -> String:
	var re := RegEx.new()
	re.compile("\\d+")
	var pool := given.duplicate()
	for m in re.search_all(text):
		var v := int(m.get_string())
		if not pool.has(v):
			return "%d IS NOT ONE OF YOUR NUMBERS" % v
		pool.erase(v)
	var ex := Expression.new()
	if ex.parse(text.replace("x", "*")) != OK:
		return "THAT DOESN'T PARSE"
	var r = ex.execute()
	if ex.has_execute_failed() or r == null:
		return "THAT DOESN'T PARSE"
	if absf(float(r) - 404.0) > 0.0001:
		return "THAT MAKES %s, NOT 404" % str(r)
	return ""


func _check_404() -> void:
	var err := check_expr(typed, nums)
	if err == "":
		Audio.play("semup", 0.0)
		Fx.word("404 FOUND! QED!", Vector2(Px.W / 2.0, 120), Px.C.gold, 16)
		Game.add_pixels(100)
		finish(true, 1.0)
	else:
		feedback = err
		feedback_t = 2.0
		Audio.play("wrong", 0.0)


func time_up() -> void:
	if bonus_mode:
		finish(true, 0.8)
	else:
		finish(false, float(right) / need)


func tick(delta: float) -> void:
	feedback_t -= delta


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.navy.darkened(0.6), 0.95))
	# Blackboard grid.
	for x in range(0, Px.W, 16):
		draw_rect(Rect2(x, 24, 1, 192), Color(Px.C.blue, 0.15))
	if bonus_mode:
		Px.text_c(self, "MAKE 404 FROM THESE NUMBERS (EACH ONCE):", Px.W / 2.0, 40, Px.C.white)
		for i in nums.size():
			var r := Rect2(Px.W / 2.0 - 132 + i * 46, 56, 40, 24)
			Px.panel(self, r, Px.C.night, Px.C.gold)
			Px.text_c(self, str(nums[i]), r.get_center().x, 62, Px.C.gold, 8)
		Px.text_c(self, "USE + - * / AND ( ). ENTER TO CHECK.", Px.W / 2.0, 90, Px.C.steel)
		if feedback_t > 0.0:
			Px.text_c(self, feedback, Px.W / 2.0, 160, Px.C.red)
	else:
		var lines := DialogueBox.wrap_text(q, 30)
		var size := 16 if lines.size() == 1 and q.length() <= 22 else 8
		for i in lines.size():
			Px.text_c(self, lines[i], Px.W / 2.0, 52 + i * 12, Px.C.white, size)
		var qed := Px.char_tex(Clubs.get_club("pioneers").head_look, "idle")
		draw_texture_rect(qed, Rect2(Vector2(16, 140), qed.get_size() * 2), false)
	var box := Rect2(Px.W / 2.0 - 120, 112, 240, 30)
	Px.panel(self, box, Px.C.ink, Px.C.cyan)
	var cur := "_" if int(t * 3) % 2 == 0 else " "
	Px.text_c(self, typed + cur, Px.W / 2.0, 117, Px.C.cyan, 16)
	draw_timer()
	draw_card()
