extends Minigame
## Chess Club: Knight's Path. A 6 x 6 board, one knight and some pawns. Move the
## cursor onto a lit L-move and press J to jump. Take every pawn within the move
## limit. Each puzzle is made by walking random knight moves from the start and
## dropping pawns on that path, so it can always be solved.

const N := 6
const CELL := 26
const ORIGIN := Vector2i(114, 32)
const JUMPS := [Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
	Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2)]
const KNIGHT := ["...kk.....", "..kwwk....", ".kwwwwkk..", "kwwkwwwwk.", "kwwwwwwwk.", ".kkkwwwwk.",
	"...kwwwk..", "..kwwwwk..", "..kwwwwwk.", ".kwwwwwwk.", ".kkkkkkkk."]
const PAWN := ["..kkkk..", ".kddddk.", ".kddddk.", "..kddk..", "..kddk..", ".kddddk.", "kddddddk", "kkkkkkkk"]

var pawn_counts: Array[int] = [4, 5, 6]
var level := 0
var start := Vector2i.ZERO
var path: Array[Vector2i] = []
var pawns: Array[Vector2i] = []
var start_pawns: Array[Vector2i] = []
var total_best := 0
var knight := Vector2i.ZERO
var cur := Vector2i.ZERO
var moves := 0
var limit := 0
var used := 0
var best := 0
var bot_t := 0.0
var k_tex: Texture2D
var p_tex: Texture2D


func info() -> Dictionary:
	return {"goal": "TAKE EVERY PAWN WITH THE KNIGHT BEFORE YOU RUN OUT OF MOVES. 3 PUZZLES.",
		"keys": ["ARROWS: MOVE THE CURSOR", "J: JUMP TO A LIT SQUARE"], "time": 90.0}


func _ready() -> void:
	super._ready()
	if short_round:
		pawn_counts = [2]
	k_tex = Px.tex_from("chess_knight", KNIGHT, {"k": Px.C.dark, "w": Px.C.white})
	p_tex = Px.tex_from("chess_pawn", PAWN, {"k": Px.C.dark, "d": Px.C.maroon})
	_new_puzzle()


func goal_text() -> String:
	return "PUZZLE %d/%d   PAWNS %d   MOVES %d/%d" % [mini(level + 1, pawn_counts.size()), pawn_counts.size(), pawns.size(), moves, limit]


static func on_board(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < N and c.y < N


func _legal(from: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for j: Vector2i in JUMPS:
		if on_board(from + j):
			out.append(from + j)
	return out


func _new_puzzle() -> void:
	var n: int = pawn_counts[level]
	var steps := n + randi() % 3
	while true:
		start = Vector2i(randi() % N, randi() % N)
		path = [start]
		while path.size() <= steps:
			var opts := _legal(path[-1]).filter(func(c: Vector2i) -> bool: return not path.has(c))
			if opts.is_empty():
				break
			path.append(opts.pick_random())
		if path.size() > steps:
			break
	# The last square always gets a pawn, the rest are picked from the path.
	var middle := path.slice(1, path.size() - 1)
	middle.shuffle()
	start_pawns = [path[-1]]
	start_pawns.append_array(middle.slice(0, n - 1))
	best = steps
	limit = steps + 2
	_reset()


func _reset() -> void:
	knight = start
	cur = start
	moves = 0
	pawns = start_pawns.duplicate()


func tick(delta: float) -> void:
	var mv := Vector2i.ZERO
	var press := Input.is_action_just_pressed("attack")
	if Game.autoplay:
		press = false
		bot_t -= delta
		if bot_t <= 0.0:
			bot_t = 0.12
			var i := path.find(knight)
			var goal: Vector2i = path[mini(i + 1, path.size() - 1)]
			mv = Vector2i(signi(goal.x - cur.x), signi(goal.y - cur.y))
			press = mv == Vector2i.ZERO
	else:
		mv.x = int(Input.is_action_just_pressed("right")) - int(Input.is_action_just_pressed("left"))
		mv.y = int(Input.is_action_just_pressed("down")) - int(Input.is_action_just_pressed("up"))
	if mv != Vector2i.ZERO:
		cur = (cur + mv).clamp(Vector2i.ZERO, Vector2i(N - 1, N - 1))
		Audio.play("move", 0.0)
	if press:
		_jump()


func _cell_pos(c: Vector2i) -> Vector2:
	return Vector2(ORIGIN + c * CELL)


func _jump() -> void:
	if not _legal(knight).has(cur):
		penalty(4.0, "NOT AN L!", _cell_pos(cur) + Vector2(13, -8))
		return
	knight = cur
	moves += 1
	Audio.play("throw", 0.0)
	if pawns.has(knight):
		pawns.erase(knight)
		Audio.play("hit", 0.0)
		Fx.burst(_cell_pos(knight) + Vector2(13, 13), [Px.C.maroon, Px.C.red, Px.C.dark], 24)
		Fx.word("TAKES!", _cell_pos(knight) + Vector2(13, -8), Px.C.gold)
	if pawns.is_empty():
		used += moves
		total_best += best
		Audio.play("right", 0.0)
		level += 1
		if level >= pawn_counts.size():
			finish(true, clampf(float(total_best) / maxi(1, used), 0.0, 1.0))
		else:
			_new_puzzle()
	elif moves >= limit:
		penalty(10.0, "OUT OF MOVES! RESET", Vector2(Px.W / 2.0, 100))
		used += moves
		_reset()


func judge() -> Array:
	return [false, float(level) / pawn_counts.size() * 0.5]


func _draw() -> void:
	draw_rect(PLAY, Px.C.night)
	var b := Rect2(Vector2(ORIGIN), Vector2(N * CELL, N * CELL))
	Px.panel(self, b.grow(3), Px.C.dark, Px.C.tan)
	var lit := _legal(knight)
	for y in N:
		for x in N:
			var c := Vector2i(x, y)
			var r := Rect2(_cell_pos(c), Vector2(CELL, CELL))
			draw_rect(r, Px.C.sand if (x + y) % 2 == 0 else Px.C.brown)
			if lit.has(c):
				draw_rect(r.grow(-3), Color(Px.C.lime, 0.55))
	for p in pawns:
		draw_texture(p_tex, _cell_pos(p) + Vector2(9, 9))
	var kp := _cell_pos(knight) + Vector2(8, 7)
	draw_texture(k_tex, kp)
	var cr := Rect2(_cell_pos(cur), Vector2(CELL, CELL))
	var cc: Color = Px.C.gold if lit.has(cur) else Px.C.red
	draw_rect(cr, cc, false, 2.0)
	Px.text(self, "CHESS CLUB", Vector2(8, 32), Px.C.cyan)
	Px.text(self, "MOVES LEFT", Vector2(8, 60), Px.C.steel)
	Px.text(self, str(limit - moves), Vector2(8, 70), Px.C.white, 16)
	Px.text(self, "PAWNS", Vector2(8, 100), Px.C.steel)
	for i in pawns.size():
		draw_texture(p_tex, Vector2(8 + i * 10, 112))
	Px.text(self, "BEST: %d" % best, Vector2(8, 130), Px.C.slate)
	Px.text(self, "GREEN = LEGAL", Vector2(286, 60), Px.C.lime)
	Px.text(self, "L-SHAPE ONLY", Vector2(286, 72), Px.C.steel)
	draw_timer()
	draw_card()
