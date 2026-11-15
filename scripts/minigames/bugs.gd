extends Minigame
## Zense: bug squash. Bugs crawl out of scrolling code toward the deploy line.
## Squash them before they reach prod. Green crawlers are features.

const DEPLOY_Y := 196.0
const CODE := [
	"func deploy():", "  if friday and time > 17:", "    push --force", "  # TODO: tests",
	"var room = 404", "while true:", "  coffee += 1", "assert(works_on_my_machine)",
	"for bug in prod:", "  bug.feature = true", "return pixels", "if not found: 404",
	"print(\"hello campus\")", "x = x + 1  # trust me", "merge(main, chaos)", "sleep(0)",
]
const BUG_ART := [".k.k.", "kbbbk", ".bwb.", "kbbbk", ".k.k."]

var crawlers := []   # {pos, vel, feature, wiggle}
var spawn_t := 0.0
var squashed := 0
var deployed := 0
var scroll := 0.0
var need := 20
var bug_tex: Texture2D
var feat_tex: Texture2D
var splats := []


func info() -> Dictionary:
	return {"goal": "SQUASH 20 BUGS. LET FEWER THAN 3 REACH DEPLOY. DON'T SQUASH FEATURES (GREEN, WITH A +).",
		"keys": ["MOUSE CLICK, OR MOVE THE CURSOR AND PRESS J"], "time": 60.0}


func _ready() -> void:
	super._ready()
	if short_round:
		need = 5
	bug_tex = Px.tex_from("bug", BUG_ART, {"k": Px.C.dark, "b": Px.C.red, "w": Px.C.white})
	feat_tex = Px.tex_from("feature", BUG_ART, {"k": Px.C.dark, "b": Px.C.lime, "w": Px.C.white})
	cursor_speed = 140.0


func goal_text() -> String:
	return "SQUASHED %d/%d   DEPLOYED %d/3   TIME %d" % [squashed, need, deployed, ceili(time_left)]


func tick(delta: float) -> void:
	scroll += delta * 12.0
	spawn_t -= delta
	var rate := lerpf(0.9, 0.45, 1.0 - time_left / time_total) * Game.time_mult() * (0.6 if short_round else 1.0)
	if spawn_t <= 0.0:
		spawn_t = rate
		var feature := randf() < 0.22
		crawlers.append({"pos": Vector2(randf_range(24, Px.W - 24), 40), "vel": randf_range(16, 30) * (1.0 + (1.0 - time_left / time_total) * 0.6),
			"feature": feature, "wig": randf() * TAU})
	for c in crawlers:
		c.wig += delta * 8.0
		c.pos.y += c.vel * delta
		c.pos.x += sin(c.wig) * 20.0 * delta
		c.pos.x = clampf(c.pos.x, 8, Px.W - 8)
		if c.pos.y >= DEPLOY_Y:
			c.dead = true
			if not c.feature:
				deployed += 1
				penalty(10.0, "BUG IN PROD!", Vector2(c.pos.x, DEPLOY_Y - 14))
			else:
				Fx.word("SHIPPED!", Vector2(c.pos.x, DEPLOY_Y - 14), Px.C.lime)
	crawlers = crawlers.filter(func(c): return not c.has("dead"))
	if cursor_step(delta):
		_squash(cursor)
	if squashed >= need:
		finish(deployed < 3, clampf(1.0 - deployed * 0.2 - mistakes * 0.05, 0.3, 1.0))
	for s in splats:
		s.t -= delta
	splats = splats.filter(func(s): return s.t > 0.0)


func judge() -> Array:
	return [squashed >= need and deployed < 3, float(squashed) / need * 0.8]


func _squash(p: Vector2) -> void:
	var best = null
	var bd := 9.0
	for c in crawlers:
		var d: float = c.pos.distance_to(p)
		if d < bd:
			bd = d
			best = c
	Audio.play("squash", 0.1)
	if best == null:
		splats.append({"pos": p, "t": 0.3, "col": Px.C.slate})
		return
	best.dead = true
	crawlers.erase(best)
	if best.feature:
		penalty(10.0, "IT'S A FEATURE!", p + Vector2(0, -10))
		splats.append({"pos": p, "t": 0.6, "col": Px.C.lime})
	else:
		squashed += 1
		Fx.burst(p, [Px.C.red, Px.C.dark], 12, null, 0, 50.0)
		Fx.word(["SQUASHED!", "FIXED!", "SEGFAULT!"].pick_random(), p + Vector2(0, -10), Px.C.gold)
		splats.append({"pos": p, "t": 1.0, "col": Px.C.red})


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.dark, 0.96))
	# Scrolling code in the pixel font.
	var y0 := fmod(scroll, 12.0)
	var first := int(scroll / 12.0)
	for i in 15:
		var line: String = CODE[(first + i) % CODE.size()]
		Px.text(self, "%3d %s" % [(first + i) % 999, line.to_upper()], Vector2(20, 186 - i * 12 + y0), Color(Px.C.lime, 0.35), 8, false)
	for s in splats:
		draw_rect(Rect2(s.pos - Vector2(3, 2), Vector2(7, 4)), s.col)
	for c in crawlers:
		var tex: Texture2D = feat_tex if c.feature else bug_tex
		draw_texture_rect(tex, Rect2((c.pos - Vector2(5, 5)).round(), Vector2(10, 10)), false)
		if c.feature:
			var m: Vector2 = c.pos.round() + Vector2(0, -8)
			draw_rect(Rect2(m - Vector2(2, 0), Vector2(5, 1)), Px.C.white)
			draw_rect(Rect2(m - Vector2(0, 2), Vector2(1, 5)), Px.C.white)
	# Deploy line.
	for x in range(0, Px.W, 4):
		draw_rect(Rect2(x, DEPLOY_Y, 2, 2), Px.C.red if int(t * 4) % 2 == 0 else Px.C.orange)
	Px.text(self, "DEPLOY TO PROD", Vector2(Px.W - 90, DEPLOY_Y + 4), Px.C.red)
	draw_cursor(Px.C.lime)
	draw_timer()
	draw_card()
