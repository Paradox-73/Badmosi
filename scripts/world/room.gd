class_name Room
extends Node2D
## A 24 x 12 tile room read from a text file. Draws its tiles and answers
## collision questions. See GDD 5.7 for the characters.

const SOLID := "#="
const KNOWN := "#.~o=@Xmtbjc MTBJC123456789$?gp"

var grid: Array[String] = []
var pal := {}
var club := ""
var broken := {}       # Vector2i -> true for broken props
var spawns := {}       # char -> Array[Vector2i]
var entrance := Vector2i(0, 5)
var boss_cell := Vector2i(11, 5)
var dim := 0.0          # darkens the room, for minigames that cover it


static func parse(text: String) -> Array[String]:
	var out: Array[String] = []
	for line in text.split("\n"):
		var l := line.strip_edges(false, true)
		if l.length() > 0:
			out.append(l)
	return out


## Returns a list of problems with a room. Empty means valid.
static func validate(rows: Array[String]) -> Array[String]:
	var errs: Array[String] = []
	if rows.size() != Px.ROWS:
		errs.append("has %d rows, needs %d" % [rows.size(), Px.ROWS])
	var ats := 0
	for y in rows.size():
		if rows[y].length() != Px.COLS:
			errs.append("row %d has %d columns" % [y, rows[y].length()])
		for ch in rows[y]:
			if KNOWN.find(ch) < 0:
				errs.append("unknown character '%s' on row %d" % [ch, y])
			if ch == "@":
				ats += 1
	if ats != 1:
		errs.append("has %d entrances, needs 1" % ats)
	if errs.is_empty():
		# Flood fill from the entrance; every spawn and X must be reachable.
		var start := Vector2i(-1, -1)
		for y in rows.size():
			var x := rows[y].find("@")
			if x >= 0:
				start = Vector2i(x, y)
		var seen := {start: true}
		var q := [start]
		while not q.is_empty():
			var c: Vector2i = q.pop_back()
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = c + d
				if n.x < 0 or n.y < 0 or n.x >= Px.COLS or n.y >= Px.ROWS or seen.has(n):
					continue
				if SOLID.find(rows[n.y][n.x]) >= 0:
					continue
				seen[n] = true
				q.append(n)
		for y in rows.size():
			for x in rows[y].length():
				if "XmtbjcMTBJC".find(rows[y][x]) >= 0 and not seen.has(Vector2i(x, y)):
					errs.append("'%s' at %d,%d can't be reached" % [rows[y][x], x, y])
	return errs


func load_club(id: String) -> void:
	club = id
	pal = Clubs.room_pal(id)
	var f := FileAccess.open("res://levels/%s.txt" % id, FileAccess.READ)
	if f == null:
		f = FileAccess.open("res://levels/impulse.txt", FileAccess.READ)
	load_rows(parse(f.get_as_text()))


func load_rows(rows: Array[String]) -> void:
	grid = rows
	spawns.clear()
	for y in grid.size():
		for x in grid[y].length():
			var ch := grid[y][x]
			if ch == "@":
				entrance = Vector2i(x, y)
			elif ch == "X":
				boss_cell = Vector2i(x, y)
			elif "mtbjcMTBJC".find(ch) >= 0:
				if not spawns.has(ch):
					spawns[ch] = []
				spawns[ch].append(Vector2i(x, y))
	queue_redraw()


func at(c: Vector2i) -> String:
	if c.y < 0 or c.y >= grid.size() or c.x < 0 or c.x >= grid[c.y].length():
		return "#"
	var ch := grid[c.y][c.x]
	if ch == "o" and broken.has(c):
		return "."
	return ch


func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / Px.TILE), floori((p.y - Px.TOP) / Px.TILE))


func cell_center(c: Vector2i) -> Vector2:
	return Vector2(c.x * Px.TILE + 8, Px.TOP + c.y * Px.TILE + 8)


func is_solid(c: Vector2i) -> bool:
	var ch := at(c)
	return SOLID.find(ch) >= 0 or ch == "o"


func is_hazard(p: Vector2) -> bool:
	return at(cell_of(p)) == "~"


## Moves a box of half-size he from pos by motion, sliding along walls.
func move(pos: Vector2, motion: Vector2, he := Vector2(5, 3)) -> Vector2:
	var p := pos
	p.x += motion.x
	if _box_hits(p, he):
		p.x = pos.x
	p.y += motion.y
	if _box_hits(p, he):
		p.y = pos.y
	return p


func _box_hits(p: Vector2, he: Vector2) -> bool:
	for c in [p + Vector2(-he.x, -he.y), p + Vector2(he.x, -he.y), p + Vector2(-he.x, he.y), p + Vector2(he.x, he.y)]:
		if is_solid(cell_of(c)):
			return true
	return false


## Breaks a prop if pos is on one. Returns true if something broke.
func hit_prop(pos: Vector2) -> bool:
	for d in [Vector2(0, 0), Vector2(8, 0), Vector2(-8, 0), Vector2(0, 8), Vector2(0, -8)]:
		var c := cell_of(pos + d)
		if at(c) == "o":
			broken[c] = true
			queue_redraw()
			Fx.shatter_tex(Px.tile_tex("prop", pal), Vector2(c.x * 16, Px.TOP + c.y * 16))
			return true
	return false


func floor_cells() -> Array:
	var out := []
	for y in range(1, Px.ROWS - 1):
		for x in range(1, Px.COLS - 1):
			if not is_solid(Vector2i(x, y)):
				out.append(Vector2i(x, y))
	return out


func _draw() -> void:
	for y in grid.size():
		for x in grid[y].length():
			var ch := at(Vector2i(x, y))
			var kind := "floor"
			match ch:
				"#": kind = "wall"
				"~": kind = "hazard"
				"o": kind = "prop"
				"=": kind = "desk"
				"@": kind = "door"
				"$": kind = "desk"
			draw_texture(Px.tile_tex(kind, pal), Vector2(x * Px.TILE, Px.TOP + y * Px.TILE))
	if dim > 0.0:
		draw_rect(Rect2(0, Px.TOP, Px.W, Px.H - Px.TOP), Color(Px.C.ink, dim))
