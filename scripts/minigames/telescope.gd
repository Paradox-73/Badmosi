extends Minigame
## ECLIPSE: a dark sky of single-pixel stars, seen only through a small round
## telescope view. Find 5 objects before dawn. City lights fade the low stars.

const R := 30.0

var stars := []
var objects := []    # {id, name, pos, found}
var need := 4
var sat_t := 0.0


func info() -> Dictionary:
	return {"goal": "FIND 4 OF 5 OBJECTS IN THE SKY. CENTRE ONE IN THE VIEW AND PRESS.",
		"keys": ["MOUSE TO AIM, CLICK   OR ARROWS + J"], "time": 75.0}


func _ready() -> void:
	super._ready()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 520:
		stars.append([Vector2(rng.randi_range(0, Px.W), rng.randi_range(26, Px.H - 4)), rng.randf()])
	var spots := [Vector2(60, 60), Vector2(300, 70), Vector2(190, 110), Vector2(90, 150), Vector2(320, 160), Vector2(200, 50)]
	spots.shuffle()
	objects = [
		{"id": "moon", "name": "THE MOON", "pos": spots[0]},
		{"id": "saturn", "name": "SATURN", "pos": spots[1]},
		{"id": "orion", "name": "ORION'S BELT", "pos": spots[2]},
		{"id": "comet", "name": "A COMET", "pos": spots[3]},
		{"id": "sat", "name": "A SATELLITE", "pos": Vector2(0, 90)},
	]
	if short_round:
		objects = objects.slice(0, 2)
		need = 1
	for o in objects:
		o.found = false
	cursor = Vector2(Px.W / 2.0, 120)
	cursor_speed = 90.0


func goal_text() -> String:
	return "FOUND %d/%d   DAWN IN %d" % [objects.filter(func(o): return o.found).size(), need, ceili(time_left)]


func tick(delta: float) -> void:
	sat_t += delta
	for o in objects:
		if o.id == "sat":
			o.pos = Vector2(fmod(sat_t * 22.0, Px.W + 40) - 20, 90 + sin(sat_t * 0.3) * 30)
	if cursor_step(delta):
		var hit := false
		for o in objects:
			if not o.found and o.pos.distance_to(cursor) < 12.0:
				o.found = true
				hit = true
				Audio.play("right", 0.0)
				Fx.word(o.name + "!", cursor + Vector2(0, -R - 8), Px.C.gold)
				break
		if not hit:
			penalty(10.0, "JUST A STREETLIGHT.", cursor + Vector2(0, -R - 8))
	var found := objects.filter(func(o): return o.found).size()
	if found == objects.size():
		finish(true, 1.0)


func judge() -> Array:
	var found := objects.filter(func(o): return o.found).size()
	return [found >= need, float(found) / objects.size()]


func _draw_object(o: Dictionary) -> void:
	var p: Vector2 = o.pos.round()
	match o.id:
		"moon":
			for y in range(-6, 7):
				for x in range(-6, 7):
					if x * x + y * y <= 36 and (x - 3) * (x - 3) + y * y > 20:
						draw_rect(Rect2(p + Vector2(x, y), Vector2.ONE), Px.C.sand)
		"saturn":
			for y in range(-3, 4):
				for x in range(-3, 4):
					if x * x + y * y <= 9:
						draw_rect(Rect2(p + Vector2(x, y), Vector2.ONE), Px.C.gold)
			for x in range(-7, 8):
				draw_rect(Rect2(p + Vector2(x, roundi(x * 0.3)), Vector2.ONE), Px.C.tan)
		"orion":
			for i in 3:
				draw_rect(Rect2(p + Vector2(-6 + i * 6, -2 + i * 2), Vector2(2, 2)), Px.C.white)
		"comet":
			draw_rect(Rect2(p, Vector2(2, 2)), Px.C.white)
			for i in 10:
				draw_rect(Rect2(p + Vector2(2 + i, -i / 2), Vector2.ONE), Color(Px.C.cyan, 1.0 - i / 10.0))
		"sat":
			var on := int(sat_t * 4) % 2 == 0
			draw_rect(Rect2(p, Vector2(2, 1)), Px.C.white if on else Px.C.red)


func _draw() -> void:
	draw_rect(PLAY, Px.C.dark)
	var view := running or over
	for s in stars:
		var p: Vector2 = s[0]
		if view and p.distance_to(cursor) > R:
			continue
		var fade := clampf((p.y - 140.0) / 70.0, 0.0, 0.85)  # Electronic City glow
		if s[1] < fade:
			continue
		var c: Color = Px.C.white if s[1] > 0.8 else (Px.C.mist if s[1] > 0.4 else Px.C.steel)
		draw_rect(Rect2(p, Vector2.ONE), c)
	for o in objects:
		if not view or o.pos.distance_to(cursor) <= R + 4:
			_draw_object(o)
		if o.found:
			draw_rect(Rect2(o.pos - Vector2(9, 9), Vector2(18, 18)), Px.C.lime, false, 1.0)
	if view:
		# The telescope's round view: darken everything outside the circle.
		for y in range(24, Px.H, 2):
			var dy := y + 1 - cursor.y
			if absf(dy) >= R:
				draw_rect(Rect2(0, y, Px.W, 2), Color(Px.C.dark, 0.97))
			else:
				var half := sqrt(R * R - dy * dy)
				draw_rect(Rect2(0, y, maxf(0, cursor.x - half), 2), Color(Px.C.dark, 0.97))
				draw_rect(Rect2(cursor.x + half, y, Px.W, 2), Color(Px.C.dark, 0.97))
		for i in 48:
			var a := i * TAU / 48.0
			draw_rect(Rect2((cursor + Vector2(cos(a), sin(a)) * R).round(), Vector2.ONE), Px.C.slate)
		draw_cursor(Px.C.gold)
	# City glow along the bottom.
	for x in range(0, Px.W, 4):
		draw_rect(Rect2(x, Px.H - 6, 4, 6), Color(Px.C.orange, 0.25 + 0.1 * sin(x * 0.3)))
	# Checklist.
	Px.panel(self, Rect2(Px.W - 108, 28, 104, 12 + objects.size() * 10), Px.C.ink, Px.C.violet)
	for i in objects.size():
		var o: Dictionary = objects[i]
		Px.text(self, ("[X] " if o.found else "[ ] ") + o.name, Vector2(Px.W - 104, 32 + i * 10), Px.C.lime if o.found else Px.C.mist)
	draw_timer()
	draw_card()
