extends "res://scripts/minigames/walk_game.gd"
## The SAC: house rules. Collect 5 signed forms in the MPH while the enforcers
## announce a new rule every 10 s. Each broken rule costs Attendance.

const RULES := [
	{"id": "norun", "text": "NO RUNNING! (NO DODGING)"},
	{"id": "carpet", "text": "STAY ON THE CARPET!"},
	{"id": "lanyard", "text": "LANYARDS ON! (HOLD L)"},
	{"id": "left", "text": "QUEUE ON THE LEFT!"},
	{"id": "eyes", "text": "NO EYE CONTACT! (DON'T FACE CLIPBOARD)"},
]
const CARPET_ROWS := [4, 5, 6, 7]

var rule := {}
var rule_t := 0.0
var forms := []
var got := 0
var need := 5
var grace := 0.0
var cool := 0.0
var enforcer_pos := Vector2(300, 60)
var order := []


func info() -> Dictionary:
	return {"goal": "COLLECT 5 SIGNED FORMS. OBEY THE HOUSE RULE ON THE BANNER. IT CHANGES EVERY 10 S.",
		"keys": ["MOVE: WASD OR ARROWS   L: LANYARD   K: DODGE"], "time": 90.0}


func _ready() -> void:
	super._ready()
	if short_round:
		need = 2
	order = RULES.duplicate()
	order.shuffle()
	var cells := room.floor_cells()
	cells.shuffle()
	for c in cells:
		if forms.size() >= need:
			break
		if c.x > 2:
			forms.append({"pos": room.cell_center(c), "got": false})


func begin() -> void:
	super.begin()
	_new_rule()


func _new_rule() -> void:
	rule = order[0]
	order.push_back(order.pop_front())
	rule_t = 10.0 * Game.time_mult()
	grace = 1.5
	Audio.play("whistle", 0.0)
	Fx.word("NEW RULE!", Vector2(Px.W / 2.0, 60), Px.C.red)


func goal_text() -> String:
	return "FORMS %d/%d   RULE CHANGES IN %d" % [got, need, ceili(rule_t)]


func _broken() -> bool:
	match rule.id:
		"norun":
			return pix.state == Player.S.DODGE
		"carpet":
			return not (room.cell_of(pix.position).y in CARPET_ROWS)
		"lanyard":
			return not Input.is_action_pressed("special")
		"left":
			return pix.position.x > Px.W / 2.0
		"eyes":
			var to := (enforcer_pos - pix.position).normalized()
			return pix.facing.dot(to) > 0.8
	return false


func tick(delta: float) -> void:
	rule_t -= delta
	grace -= delta
	cool -= delta
	enforcer_pos = Vector2(Px.W / 2.0 + sin(t * 0.7) * 150, 52)
	if rule_t <= 0.0:
		_new_rule()
	if grace <= 0.0 and cool <= 0.0 and _broken():
		cool = 1.5
		penalty(10.0, "FINED! " + rule.text.split("!")[0] + "!", pix.position + Vector2(0, -22))
	for f in forms:
		if not f.got and f.pos.distance_to(pix.position + Vector2(0, -4)) < 12.0:
			f.got = true
			got += 1
			Audio.play("stamp", 0.0)
			Fx.word("SIGNED!", f.pos + Vector2(0, -14), Px.C.gold)
	if got >= need:
		finish(true, clampf(1.0 - mistakes * 0.1, 0.2, 1.0))


func judge() -> Array:
	return [got >= need, float(got) / need]


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.ink, 0.35))
	for y in CARPET_ROWS:
		for x in range(1, Px.COLS - 1):
			var p := Vector2(x * 16, Px.TOP + y * 16)
			draw_rect(Rect2(p, Vector2(16, 16)), Color(Px.C.maroon, 0.85))
			if y == CARPET_ROWS[0] or y == CARPET_ROWS[-1]:
				draw_rect(Rect2(p + Vector2(0, 0 if y == CARPET_ROWS[0] else 15), Vector2(16, 1)), Px.C.gold)
	if rule.get("id", "") == "left":
		draw_rect(Rect2(Px.W / 2.0, 40, 1, 176), Px.C.red)
	for f in forms:
		if not f.got:
			draw_rect(Rect2(f.pos - Vector2(4, 5), Vector2(8, 10)), Px.C.white)
			for i in 3:
				draw_rect(Rect2(f.pos + Vector2(-2, -3 + i * 3), Vector2(5, 1)), Px.C.slate)
	# CLIPBOARD patrols the top.
	var cb := Px.char_tex(Clubs.get_club("sac").head_look, "walk1" if int(t * 4) % 2 == 0 else "idle")
	draw_texture(cb, enforcer_pos - Vector2(8, 20))
	# Rule banner.
	var txt: String = rule.get("text", "")
	if txt != "":
		var w := Px.text_w(txt) + 16
		Px.panel(self, Rect2(Px.W / 2.0 - w / 2.0, 186, w, 16), Px.C.red if grace > 0.0 and int(t * 6) % 2 == 0 else Px.C.ink, Px.C.white)
		Px.text_c(self, txt, Px.W / 2.0, 190, Px.C.white)
	if rule.get("id", "") == "lanyard" and Input.is_action_pressed("special"):
		draw_rect(Rect2(pix.position + Vector2(-1, -10), Vector2(2, 5)), Px.C.red)
	draw_timer()
	draw_card()
