extends Minigame
## Quantum Club: QUBIT FLIP. Five qubits, each |0> or |1>. A gate on one qubit
## flips it and both neighbours. Match the target row within the move limit.
## Puzzles are made by scrambling the target, so every one can be solved.

const N := 5

var need := 6
var solved := 0
var target := 0          # bitmask, bit i = qubit i
var start := 0
var state := 0
var moves := 0
var limit := 0
var sel := 2
var auto_t := 0.0


func info() -> Dictionary:
	return {"goal": "FLIP THE QUBITS TO MATCH THE TARGET ROW. EACH GATE FLIPS ITS NEIGHBOURS TOO. %d PUZZLES." % (1 if short_round else 6),
		"keys": ["LEFT/RIGHT: PICK A QUBIT   J: APPLY THE GATE", "K: RESET THIS PUZZLE"], "time": 80.0}


func _ready() -> void:
	super._ready()
	if short_round:
		need = 1
	_new_puzzle()


## The bits a gate on qubit i flips.
static func mask(i: int) -> int:
	var m := 1 << i
	if i > 0:
		m |= 1 << (i - 1)
	if i < N - 1:
		m |= 1 << (i + 1)
	return m


## The fewest gates that turn s into goal, as qubit indexes ([] if none needed).
static func solve(s: int, goal: int) -> Array:
	var best := []
	var best_n := 99
	for sub in 1 << N:
		var m := 0
		var picks := []
		for i in N:
			if sub & (1 << i):
				m ^= mask(i)
				picks.append(i)
		if m == s ^ goal and picks.size() < best_n:
			best = picks
			best_n = picks.size()
	return best


func _new_puzzle() -> void:
	target = randi() % (1 << N)
	var k := 2 + mini(solved / 2, 2) if not short_round else 2
	start = target
	while start == target:
		var picks := range(N)
		picks.shuffle()
		for i in k:
			start ^= mask(picks[i])
	state = start
	moves = 0
	var opt := solve(start, target).size()
	assert(opt > 0 and opt <= k, "scrambled puzzle must be solvable")
	limit = opt + (1 if solved >= 3 else 2)


func goal_text() -> String:
	return "PUZZLE %d/%d   MOVES %d/%d" % [mini(solved + 1, need), need, moves, limit]


func tick(delta: float) -> void:
	var go := Input.is_action_just_pressed("attack")
	if Input.is_action_just_pressed("left"):
		sel = (sel + N - 1) % N
		Audio.play("move", 0.0)
	if Input.is_action_just_pressed("right"):
		sel = (sel + 1) % N
		Audio.play("move", 0.0)
	if Input.is_action_just_pressed("dodge") and moves > 0:
		state = start
		moves = 0
		Audio.play("back", 0.0)
	if Game.autoplay:
		go = false
		auto_t += delta
		var plan := solve(state, target)
		if auto_t > 0.35 and not plan.is_empty():
			auto_t = 0.0
			if sel == plan[0]:
				go = true
			else:
				sel += 1 if plan[0] > sel else -1
	if not go:
		return
	state ^= mask(sel)
	moves += 1
	Audio.play("zap", 0.0)
	for i in N:
		if mask(sel) & (1 << i):
			Fx.burst(_q_pos(i) + Vector2(12, 12), [Px.C.violet, Px.C.cyan], 6)
	if state == target:
		solved += 1
		Audio.play("right", 0.0)
		Fx.word("COHERENT!", Vector2(Px.W / 2.0, 70), Px.C.lime)
		for i in N:
			Fx.burst(_q_pos(i) + Vector2(12, 12), [Px.C.lime, Px.C.white], 12)
		if solved >= need:
			finish(true, float(need) / (need + mistakes))
			return
		_new_puzzle()
	elif moves >= limit:
		penalty(6.0, "DECOHERED!", Vector2(Px.W / 2.0, 70))
		state = start
		moves = 0


func judge() -> Array:
	return [solved >= need, float(solved) / float(need)]


func _q_pos(i: int) -> Vector2:
	return Vector2(72 + i * 52, 104)


func _draw() -> void:
	draw_rect(PLAY, Px.C.ink)
	# Cryostat stripes.
	for i in 6:
		draw_rect(Rect2(0, 40 + i * 28, Px.W, 1), Px.C.night)
	Px.text(self, "TARGET", Vector2(16, 40), Px.C.gold)
	for i in N:
		var on := (target >> i) & 1
		var x := 72 + i * 52
		Px.panel(self, Rect2(x, 34, 24, 16), Px.C.night, Px.C.gold)
		Px.text_c(self, "|%d>" % on, x + 12, 38, Px.C.gold)
	# The qubits: a dot on a circle, up for |0>, down for |1>.
	for i in N:
		var p := _q_pos(i)
		var on := (state >> i) & 1
		var hit := ((target >> i) & 1) == on
		var ring: Color = Px.C.lime if hit else Px.C.steel
		draw_rect(Rect2(p + Vector2(6, 0), Vector2(12, 2)), ring)
		draw_rect(Rect2(p + Vector2(6, 22), Vector2(12, 2)), ring)
		draw_rect(Rect2(p + Vector2(0, 6), Vector2(2, 12)), ring)
		draw_rect(Rect2(p + Vector2(22, 6), Vector2(2, 12)), ring)
		for c in [Vector2(2, 2), Vector2(4, 1), Vector2(18, 1), Vector2(20, 2), Vector2(1, 4), Vector2(21, 4),
				Vector2(2, 20), Vector2(4, 22), Vector2(18, 22), Vector2(20, 20), Vector2(1, 18), Vector2(21, 18)]:
			draw_rect(Rect2(p + c, Vector2(2, 2)), ring)
		draw_rect(Rect2(p + Vector2(11, 6), Vector2(2, 12)), Px.C.slate)
		var wob := 1 if int(t * 5 + i) % 2 == 0 else 0
		draw_rect(Rect2(p + Vector2(9 + wob, 4 if on == 0 else 16), Vector2(6, 4)), Px.C.violet if on == 0 else Px.C.cyan)
		Px.text_c(self, "|%d>" % on, p.x + 12, p.y + 30, Px.C.white)
		if i == sel and running:
			var m := mask(sel)
			for e in [Rect2(p + Vector2(-4, -8), Vector2(32, 1)), Rect2(p + Vector2(-4, 41), Vector2(32, 1)),
					Rect2(p + Vector2(-4, -8), Vector2(1, 50)), Rect2(p + Vector2(27, -8), Vector2(1, 50))]:
				draw_rect(e, Px.C.gold)
			for j in N:
				if m & (1 << j) and j != i:
					draw_rect(Rect2(_q_pos(j) + Vector2(8, -5), Vector2(8, 2)), Px.C.violet)
	Px.text_c(self, "MOVES LEFT %d" % (limit - moves), Px.W / 2.0, 166, Px.C.cyan if limit - moves > 1 else Px.C.red)
	Px.text_c(self, "SOLVED %d/%d" % [solved, need], Px.W / 2.0, 180, Px.C.steel)
	draw_timer()
	draw_card()
