extends RefCounted
## Campus backdrop pieces shared by the sports minigames: daytime sky, the
## Aryabhatta block (light grey, sand-yellow panels, white tower), the
## Ramanujan block (white, mustard panel, black window slots), trees, and the
## courts' netting and floodlight poles.


## Sky and both academic blocks, standing on the line y = horizon.
static func sky_and_blocks(ci: CanvasItem, horizon: float) -> void:
	for i in 6:
		var y := 24.0 + (horizon - 24.0) * i / 6.0
		ci.draw_rect(Rect2(0, y, Px.W, (horizon - 24.0) / 6.0 + 1.0), Px.C.blue.lerp(Px.C.cyan, 0.5 + i / 12.0))
	_aryabhatta(ci, Rect2(0, horizon - 34, 150, 34))
	_ramanujan(ci, Rect2(214, horizon - 30, 170, 30))


## Block names. Drawn after any trees so a canopy never hides them.
static func labels(ci: CanvasItem, horizon: float, ary_x := 28.0) -> void:
	Px.text(ci, "ARYABHATTA", Vector2(ary_x, horizon - 44), Px.C.ink, 8, false)
	Px.text(ci, "RAMANUJAN", Vector2(220, horizon - 40), Px.C.ink, 8, false)


static func _aryabhatta(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r.grow(1), Px.C.slate)
	ci.draw_rect(r, Px.C.white.darkened(0.12))
	# Bays of windows, every third bay a sand-yellow panel.
	var i := 0
	for x in range(int(r.position.x) + 26, int(r.end.x) - 4, 20):
		if i % 3 == 1:
			ci.draw_rect(Rect2(x, r.position.y + 4, 16, r.size.y - 6), Px.C.sand)
		else:
			for y in range(int(r.position.y) + 6, int(r.end.y) - 4, 9):
				ci.draw_rect(Rect2(x + 2, y, 4, 4), Px.C.slate)
				ci.draw_rect(Rect2(x + 9, y, 4, 4), Px.C.slate)
		i += 1
	# The white tower at the west end, taller than the block.
	var tw := Rect2(r.position.x + 6, r.position.y - 18, 16, r.size.y + 18)
	ci.draw_rect(tw.grow(1), Px.C.slate)
	ci.draw_rect(tw, Px.C.white)
	for y in range(int(tw.position.y) + 5, int(tw.end.y) - 6, 8):
		ci.draw_rect(Rect2(tw.position.x + 6, y, 4, 4), Px.C.slate)


static func _ramanujan(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r.grow(1), Px.C.slate)
	ci.draw_rect(r, Px.C.white)
	ci.draw_rect(Rect2(r.position.x + 10, r.position.y + 3, 40, r.size.y - 3), Px.C.gold.darkened(0.2))
	# Black vertical window slots.
	for x in range(int(r.position.x) + 58, int(r.end.x) - 4, 7):
		for y in range(int(r.position.y) + 5, int(r.end.y) - 9, 12):
			ci.draw_rect(Rect2(x, y, 2, 9), Px.C.dark)


## A blocky side-on tree standing on the ground at x. A longer trunk makes a tall tree.
static func tree(ci: CanvasItem, x: float, ground: float, s := 1.0, trunk := 14.0) -> void:
	var top := ground - trunk * s
	ci.draw_rect(Rect2(x - 2, top, 4, trunk * s), Px.C.brown)
	ci.draw_rect(Rect2(x - 10 * s, top - 16 * s, 20 * s, 16 * s), Px.C.jade)
	ci.draw_rect(Rect2(x - 7 * s, top - 22 * s, 14 * s, 8 * s), Px.C.green)
	ci.draw_rect(Rect2(x - 6 * s, top - 14 * s, 4, 3), Px.C.lime)


## Court netting seen side-on: a thin mesh with posts and a top rail.
static func fence(ci: CanvasItem, r: Rect2) -> void:
	var mesh := Color(Px.C.dark, 0.3)
	for x in range(int(r.position.x), int(r.end.x), 4):
		ci.draw_rect(Rect2(x, r.position.y, 1, r.size.y), mesh)
	for y in range(int(r.position.y), int(r.end.y), 4):
		ci.draw_rect(Rect2(r.position.x, y, r.size.x, 1), mesh)
	for x in range(int(r.position.x), int(r.end.x) + 1, 48):
		ci.draw_rect(Rect2(x - 1, r.position.y, 2, r.size.y), Px.C.slate)
	ci.draw_rect(Rect2(r.position.x, r.position.y - 1, r.size.x, 2), Px.C.slate)


## A floodlight pole h pixels tall, lamps off in daylight.
static func floodlight(ci: CanvasItem, x: float, ground: float, h: float) -> void:
	ci.draw_rect(Rect2(x - 1, ground - h, 2, h), Px.C.slate)
	ci.draw_rect(Rect2(x - 7, ground - h - 5, 14, 6), Px.C.dark)
	for i in 3:
		ci.draw_rect(Rect2(x - 6 + i * 4, ground - h - 4, 3, 3), Px.C.mist)


## A tree seen from above, for top-down courts.
static func tree_top(ci: CanvasItem, p: Vector2) -> void:
	ci.draw_rect(Rect2(p - Vector2(11, 9), Vector2(22, 18)), Px.C.jade)
	ci.draw_rect(Rect2(p - Vector2(8, 12), Vector2(16, 24)), Px.C.jade)
	ci.draw_rect(Rect2(p - Vector2(6, 8), Vector2(10, 8)), Px.C.green)
	ci.draw_rect(Rect2(p - Vector2(4, 6), Vector2(3, 2)), Px.C.lime)
