extends Minigame
## 8-Bit: proofread the cover. The PROOF is approved; the PRINT has 5 errors.
## Cover 1: wrong 2 x 2 blocks. Cover 2: single pixels. Cover 3: single pixels
## in close colours. Click each error on the PRINT.

const CW := 36
const CH := 44
const S := 3
const PROOF_POS := Vector2(30, 46)
const PRINT_POS := Vector2(Px.W - 30 - CW * S, 46)

var cover := 0
var covers := 3
var proof: Image
var print_img: Image
var errors := []     # {pos: Vector2i, size, found}
var found_total := 0
var per_cover := 60.0
var cover_t := 0.0
var flash_pos := Vector2(-99, -99)
var flash_t := 0.0
var proof_tex: Texture2D
var print_tex: Texture2D
var rng := RandomNumberGenerator.new()
var need := 12


func info() -> Dictionary:
	return {"goal": "FIND THE 5 WRONG PIXELS ON EACH PRINT BEFORE THE DEADLINE. 12 OF 15 TO PASS.",
		"keys": ["MOUSE CLICK, OR MOVE THE CURSOR AND PRESS J"], "time": 180.0}


func uses_timer() -> bool:
	return false


func _ready() -> void:
	super._ready()
	rng.randomize()
	per_cover = 60.0 * Game.time_mult()
	if short_round:
		covers = 1
		need = 3
		per_cover = 12.0 * Game.time_mult()
	cursor_speed = 60.0
	cursor = PRINT_POS + Vector2(CW, CH) * S / 2.0


func begin() -> void:
	_make_cover()


func goal_text() -> String:
	return "COVER %d/%d   FOUND %d/%d   DEADLINE %d" % [cover + 1, covers, found_total, need, ceili(per_cover - cover_t)]


func _make_cover() -> void:
	cover_t = 0.0
	errors.clear()
	proof = Image.create_empty(CW, CH, false, Image.FORMAT_RGBA8)
	var bg: Color = [Px.C.sand, Px.C.mist, Px.C.cyan.lightened(0.5)][cover % 3]
	proof.fill(bg)
	# Masthead.
	for y in 8:
		for x in CW:
			proof.set_pixel(x, y, Px.C.red if y < 7 else Px.C.dark)
	var letters := ["###.##..###.###", "#.#.#.#..#...#.", "###.##...#...#.", "#.#.#.#..#...#.", "###.##..###..#."]
	for y in 5:
		for x in letters[y].length():
			if letters[y][x] == "#":
				proof.set_pixel(10 + x, 1 + y, Px.C.white)
	# The cover star: a club head at 1x.
	var id: String = Clubs.ORDER[rng.randi() % Clubs.ORDER.size()]
	var star := Px.char_tex(Clubs.get_club(id).head_look, "idle").get_image()
	for y in star.get_height():
		for x in star.get_width():
			var c := star.get_pixel(x, y)
			if c.a > 0.5:
				proof.set_pixel(10 + x, 12 + y - (star.get_height() - 16) + 2, c)
	# Text lines and a barcode.
	for i in 4:
		var w := rng.randi_range(12, 30)
		for x in w:
			proof.set_pixel(3 + x, 34 + i * 2, Px.C.slate if i % 2 else Px.C.dark)
	for x in 8:
		for y in 4:
			if (x * 3 + cover) % 2 == 0:
				proof.set_pixel(26 + x, 38 + y, Px.C.dark)
	print_img = proof.duplicate()
	# Errors.
	var tries := 0
	while errors.size() < 5 and tries < 500:
		tries += 1
		var size := 2 if cover == 0 else 1
		var p := Vector2i(rng.randi_range(1, CW - 3), rng.randi_range(1, CH - 3))
		var ok := true
		for e in errors:
			if (e.pos - p).length() < 6:
				ok = false
		if not ok:
			continue
		var orig := proof.get_pixel(p.x, p.y)
		var wrong: Color
		if cover == 2:
			wrong = orig.lightened(0.22) if orig.get_luminance() < 0.6 else orig.darkened(0.22)
		else:
			wrong = [Px.C.red, Px.C.lime, Px.C.violet, Px.C.cyan, Px.C.dark][rng.randi() % 5]
			if wrong.is_equal_approx(orig):
				wrong = Px.C.pink
		for dy in size:
			for dx in size:
				print_img.set_pixel(p.x + dx, p.y + dy, wrong)
		errors.append({"pos": p, "size": size, "found": false})
	proof_tex = ImageTexture.create_from_image(proof)
	print_tex = ImageTexture.create_from_image(print_img)


func tick(delta: float) -> void:
	cover_t += delta
	flash_t -= delta
	var pressed := cursor_step(delta)
	if pressed:
		_click(cursor)
	if cover_t >= per_cover:
		penalty(20.0, "MISSED THE DEADLINE!")
		_next_cover()
	elif errors.all(func(e): return e.found):
		Audio.play("card", 0.0)
		Fx.word("COVER APPROVED!", Vector2(Px.W / 2.0, 190), Px.C.lime)
		_next_cover()


func _click(p: Vector2) -> void:
	var local := (p - PRINT_POS) / S
	if local.x < 0 or local.y < 0 or local.x >= CW or local.y >= CH:
		return
	var c := Vector2i(floori(local.x), floori(local.y))
	for e in errors:
		if e.found:
			continue
		var r := Rect2i(e.pos - Vector2i(1, 1), Vector2i(e.size + 2, e.size + 2))
		if r.has_point(c):
			e.found = true
			found_total += 1
			Audio.play("perfect", 0.0)
			Fx.burst(PRINT_POS + Vector2(e.pos) * S + Vector2(2, 2), [Px.C.red, Px.C.gold], 10)
			Fx.word("TYPO!", PRINT_POS + Vector2(e.pos) * S + Vector2(0, -6), Px.C.gold)
			return
	flash_pos = PRINT_POS + Vector2(c) * S
	flash_t = 0.3
	penalty(10.0, "THAT'S FINE!", p + Vector2(0, -10))


func _next_cover() -> void:
	cover += 1
	if cover >= covers:
		finish(found_total >= need, float(found_total) / (covers * 5))
	else:
		_make_cover()


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.night, 0.96))
	if proof_tex:
		Px.text_c(self, "PROOF (APPROVED)", PROOF_POS.x + CW * S / 2.0, 32, Px.C.lime)
		Px.text_c(self, "PRINT (CLICK ERRORS)", PRINT_POS.x + CW * S / 2.0, 32, Px.C.red)
		draw_rect(Rect2(PROOF_POS - Vector2(2, 2), Vector2(CW, CH) * S + Vector2(4, 4)), Px.C.dark)
		draw_rect(Rect2(PRINT_POS - Vector2(2, 2), Vector2(CW, CH) * S + Vector2(4, 4)), Px.C.dark)
		draw_texture_rect(proof_tex, Rect2(PROOF_POS, Vector2(CW, CH) * S), false)
		draw_texture_rect(print_tex, Rect2(PRINT_POS, Vector2(CW, CH) * S), false)
		for e in errors:
			if e.found:
				var r := Rect2(PRINT_POS + Vector2(e.pos) * S - Vector2(2, 2), Vector2(e.size, e.size) * S + Vector2(4, 4))
				draw_rect(r, Px.C.gold, false, 1.0)
				var r2 := Rect2(PROOF_POS + Vector2(e.pos) * S - Vector2(2, 2), Vector2(e.size, e.size) * S + Vector2(4, 4))
				draw_rect(r2, Px.C.lime, false, 1.0)
		if flash_t > 0.0:
			draw_rect(Rect2(flash_pos, Vector2(S, S)), Px.C.white, false, 1.0)
		# Error checklist.
		for i in 5:
			var f: bool = i < errors.size() and errors.filter(func(e): return e.found).size() > i
			draw_rect(Rect2(Px.W / 2.0 - 22 + i * 9, 100, 7, 7), Px.C.gold if f else Px.C.slate)
		Px.text_c(self, "ERRORS", Px.W / 2.0, 88, Px.C.mist)
		var dl := Px.char_tex(Clubs.get_club("eightbit").head_look, "idle")
		draw_texture_rect(dl, Rect2(Vector2(Px.W / 2.0 - 16, 120), dl.get_size() * 2), false)
		Px.text_c(self, "DEADLINE", Px.W / 2.0, 164, Px.C.red)
		Px.bar(self, Rect2(Px.W / 2.0 - 30, 176, 60, 4), 1.0 - cover_t / per_cover, Px.C.red)
	draw_cursor(Px.C.white)
	draw_card()
