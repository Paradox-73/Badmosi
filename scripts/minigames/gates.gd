extends Minigame
## MOSFIT: WIRE THE GATE. Match the truth table. Early rounds have one gate
## on inputs A and B; later rounds chain two: X = G1(A, B), OUT = G2(X, C).
## LEFT/RIGHT picks a gate, J wires it into the empty slot, K pulls it back out.

const GATES := ["AND", "OR", "XOR", "NAND", "NOR"]

var need := 6
var round_i := 0
var chained := false
var answer := []        # gate indexes that built the target
var target := []        # wanted outputs, one per table row
var slots := []         # placed gates (-1 = empty)
var sel := 0
var wrong_rows := []
var show_t := 0.0
var auto_t := 0.0


func info() -> Dictionary:
	return {"goal": "PICK THE GATE THAT MAKES THE OUTPUT MATCH THE TRUTH TABLE. %d CIRCUITS." % (2 if short_round else 6),
		"keys": ["LEFT/RIGHT: CHOOSE GATE   J: WIRE IT", "K: UNWIRE THE LAST GATE"], "time": 80.0}


func _ready() -> void:
	super._ready()
	if short_round:
		need = 2
	_new_round()


static func gate(g: int, a: int, b: int) -> int:
	match g:
		0: return a & b
		1: return a | b
		2: return a ^ b
		3: return 1 - (a & b)
	return 1 - (a | b)


func _rows() -> int:
	return 8 if chained else 4


## Output for table row r with gates gs. Row bits are A B (C), A the highest.
func _out(gs: Array, r: int) -> int:
	if not chained:
		return gate(gs[0], (r >> 1) & 1, r & 1)
	return gate(gs[1], gate(gs[0], (r >> 2) & 1, (r >> 1) & 1), r & 1)


func _new_round() -> void:
	chained = round_i >= 3 and not short_round
	var last := answer.duplicate()
	answer = [randi() % 5, randi() % 5] if chained else [randi() % 5]
	if answer == last:
		answer[0] = (answer[0] + 1) % 5
	target = []
	for r in _rows():
		target.append(_out(answer, r))
	slots = [-1, -1] if chained else [-1]
	wrong_rows = []


func goal_text() -> String:
	return "CIRCUIT %d/%d   %s" % [mini(round_i + 1, need), need, "TWO GATES" if chained else "ONE GATE"]


func tick(delta: float) -> void:
	show_t -= delta
	var place := Input.is_action_just_pressed("attack")
	if Input.is_action_just_pressed("left"):
		sel = (sel + 4) % 5
		Audio.play("move", 0.0)
	if Input.is_action_just_pressed("right"):
		sel = (sel + 1) % 5
		Audio.play("move", 0.0)
	var slot := slots.find(-1)
	if Input.is_action_just_pressed("dodge") and slot != 0:
		slots[(slot if slot > 0 else slots.size()) - 1] = -1
		Audio.play("back", 0.0)
	if Game.autoplay:
		auto_t += delta
		place = false
		if auto_t > 0.25 and slot >= 0:
			auto_t = 0.0
			if sel != answer[slot]:
				sel = (sel + 1) % 5
			else:
				place = true
	if place and slot >= 0:
		slots[slot] = sel
		Audio.play("select", 0.0)
		if slots.find(-1) < 0:
			_check()


func _check() -> void:
	wrong_rows = []
	for r in _rows():
		if _out(slots, r) != target[r]:
			wrong_rows.append(r)
	if wrong_rows.is_empty():
		Audio.play("right", 0.0)
		Fx.word("CIRCUIT LIVE!", Vector2(120, 42), Px.C.lime)
		Fx.burst(Vector2(206, 104), [Px.C.lime, Px.C.gold, Px.C.white], 24)
		round_i += 1
		if round_i >= need:
			finish(true, float(need) / (need + mistakes))
			return
		_new_round()
	else:
		show_t = 1.5
		Fx.burst(Vector2(120, 104), [Px.C.red, Px.C.steel, Px.C.dark], 30)
		penalty(6.0, "SHORT CIRCUIT!", Vector2(120, 42))
		slots[slots.size() - 1] = -1
		if chained:
			slots[0] = -1


func judge() -> Array:
	return [round_i >= need, float(round_i) / float(need)]


func _draw() -> void:
	draw_rect(PLAY, Px.C.jade.darkened(0.6))
	# Circuit board traces.
	for i in 12:
		draw_rect(Rect2(i * 32 + 6, 24, 1, 192), Color(Px.C.jade, 0.35))
	var row := int(t * 1.2) % _rows()       # wires show one table row at a time
	var bits := []
	var n_in := 3 if chained else 2
	for k in n_in:
		bits.append((row >> (n_in - 1 - k)) & 1)
	var names := ["A", "B", "C"]
	for k in n_in:
		var y := 90 + k * 14
		if chained:
			y = 128 if k == 2 else 66 + k * 12
		Px.text(self, "%s=%d" % [names[k], bits[k]], Vector2(10, y - 4), Px.C.white)
		var x_end := 96 if k < 2 else 160
		draw_rect(Rect2(36, y, x_end - 36, 2), _wire(bits[k]))
	var x_mid := -1
	if slots[0] >= 0:
		x_mid = gate(slots[0], bits[0], bits[1])
	_gate_box(Rect2(96, 60 if chained else 86, 40, 24), slots[0], 0)
	var out_bit := x_mid
	if chained:
		draw_rect(Rect2(136, 72, 16, 2), _wire(x_mid))
		draw_rect(Rect2(150, 72, 2, 44), _wire(x_mid))
		draw_rect(Rect2(150, 116, 10, 2), _wire(x_mid))
		out_bit = gate(slots[1], x_mid, bits[2]) if slots[1] >= 0 and x_mid >= 0 else -1
		_gate_box(Rect2(160, 110, 40, 24), slots[1], 1)
		draw_rect(Rect2(200, 122, 20, 2), _wire(out_bit))
	else:
		draw_rect(Rect2(136, 98, 84, 2), _wire(out_bit))
	var ly := 116 if chained else 92
	draw_rect(Rect2(220, ly, 10, 10), Px.C.lime if out_bit == 1 else Px.C.dark)
	Px.text(self, "OUT", Vector2(214, ly + 12), Px.C.mist)
	_table(row)
	# Gate menu.
	for g in 5:
		var r := Rect2(16 + g * 72, 180, 64, 16)
		Px.panel(self, r, Px.C.navy if g != sel else Px.C.teal, Px.C.gold if g == sel else Px.C.slate)
		Px.text_c(self, GATES[g], r.get_center().x, 184, Px.C.white)
	draw_timer()
	draw_card()


func _wire(b: int) -> Color:
	return Px.C.lime if b == 1 else (Px.C.slate if b == 0 else Px.C.ink)


func _gate_box(r: Rect2, g: int, k: int) -> void:
	var active := slots.find(-1) == k
	Px.panel(self, r, Px.C.ink, Px.C.gold if active and int(t * 3) % 2 == 0 else Px.C.steel)
	Px.text_c(self, GATES[g] if g >= 0 else "?", r.get_center().x, r.position.y + 8, Px.C.white if g >= 0 else Px.C.gold)


## The truth table on the right; failed rows flash red after a wrong wire.
func _table(row: int) -> void:
	var x0 := 248
	var heads := ["A", "B", "C", "OUT"] if chained else ["A", "B", "OUT"]
	Px.panel(self, Rect2(x0 - 6, 30, 136, 22 + _rows() * 10 + 4), Px.C.night, Px.C.steel)
	for i in heads.size():
		Px.text(self, heads[i], Vector2(x0 + i * 22, 36), Px.C.gold)
	var n_in := heads.size() - 1
	for r in _rows():
		var y := 50 + r * 10
		if r == row:
			draw_rect(Rect2(x0 - 3, y - 1, 130, 9), Px.C.plum)
		if show_t > 0.0 and wrong_rows.has(r):
			draw_rect(Rect2(x0 - 3, y - 1, 130, 9), Px.C.maroon)
		for k in n_in:
			Px.text(self, str((r >> (n_in - 1 - k)) & 1), Vector2(x0 + k * 22, y), Px.C.white)
		Px.text(self, str(target[r]), Vector2(x0 + n_in * 22 + 6, y), Px.C.lime if target[r] == 1 else Px.C.steel)
