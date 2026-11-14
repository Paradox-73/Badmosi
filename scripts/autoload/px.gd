extends Node
## Pixel art library: the palette, sprites drawn from text, generated tiles,
## and small helpers for pixel-font labels. Every texture is built once and cached.

const W := 384
const H := 216
const TOP := 24          # height of the HUD band
const TILE := 16
const COLS := 24
const ROWS := 12

const C := {
	"ink": Color("140f1d"), "night": Color("22182f"), "plum": Color("3b2a4d"),
	"slate": Color("4b5a7a"), "steel": Color("7d8fb3"), "mist": Color("c3d0e6"),
	"white": Color("f4f1e8"), "red": Color("e2384a"), "tele": Color("ffffff"),
	"orange": Color("f27d2e"), "gold": Color("f6c445"), "lime": Color("9bdc4b"),
	"green": Color("3a9e58"), "teal": Color("2b7f86"), "cyan": Color("5fd3e0"),
	"blue": Color("3a5fcf"), "violet": Color("8c4fd6"), "pink": Color("f07ab5"),
	"brown": Color("7a4a33"), "tan": Color("c98e5f"), "dark": Color("0b0910"),
	"skin1": Color("f2c49b"), "skin2": Color("c68a5c"), "skin3": Color("8d5a3b"),
	"grey": Color("8a8580"), "olive": Color("6f7d3a"), "navy": Color("1f2a55"),
	"maroon": Color("7a2236"), "sand": Color("e6cf98"), "jade": Color("1f6e5a"),
}

var font: FontFile
var _cache := {}

# Front-facing chibi body. Keys: k outline, h hair, s skin, e eye, c cloth,
# d cloth shade, a accent, p pants, b shoes.
const BODY := [
	"................",
	".....kkkkkk.....",
	"....khhhhhhk....",
	"...khhhhhhhhk...",
	"...ahssssssha...",
	"...asessssesa...",
	"...kssssssssk...",
	"....ksseessk....",
	".....kkkkkk.....",
	"....kccccccdk...",
	"...kcccaacccdk..",
	"...sccccccccds..",
	"....kpppppppk...",
]
const LEGS := {
	"idle": ["....kppk.kppk...", "....kppk.kppk...", "....kbbk.kbbk..."],
	"walk1": ["....kppk.kppk...", "....kbbk.kppk...", ".........kbbk..."],
	"walk2": ["....kppk.kppk...", "....kppk.kbbk...", "....kbbk........"],
}
# A smaller 12 x 12 body, for Juniors.
const MINI := [
	"............",
	"...kkkkkk...",
	"..khhhhhhk..",
	"..ksesssesk.",
	"..kssssssk..",
	"...kkkkkk...",
	"..kccaaccdk.",
	".scccccccds.",
	"..kppppppk..",
]
const MINI_LEGS := {
	"idle": ["..kpk..kpk..", "..kbk..kbk..", "............"],
	"walk1": ["..kbk..kpk..", ".......kbk..", "............"],
	"walk2": ["..kpk..kbk..", "..kbk.......", "............"],
}
# Hats sit in 4 rows above the 16 x 16 body, for club heads.
const HATS := {
	"none": ["................", "................", "................", "................"],
	"crown": ["................", "....a..a..a.....", "....aaaaaaa.....", "....kkkkkkk....."],
	"cap": ["................", "................", "....kkkkkkk.....", "...kaaaaaaaaa..."],
	"beret": ["................", "......kkk.......", "....kaaaaaak....", "...kaaaaaaaaak.."],
	"tophat": ["....kkkkkkk.....", "....kaaaaak.....", "....kaaaaak.....", "..kkkkkkkkkkk..."],
	"antenna": ["........a.......", "........k.......", ".......kak......", "........k......."],
	"headset": ["................", "....kkkkkkkk....", "...k........k...", "..ak........ka.."],
	"bun": ["................", "......kkkk......", ".....khhhhk.....", "......kkkk......"],
	"horns": ["................", "...a........a...", "...ka......ak...", "....k......k...."],
	"visor": ["................", "................", "................", "..kaaaaaaaaaak.."],
}


func _ready() -> void:
	font = load("res://assets/fonts/pix5x7.fnt")


func col(name: String) -> Color:
	return C.get(name, Color.MAGENTA)


## Builds an image from rows of characters. pal maps a character to a Color.
func img(rows: Array, pal: Dictionary) -> Image:
	var h := rows.size()
	var w := 0
	for r in rows:
		w = maxi(w, r.length())
	var im := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var r: String = rows[y]
		for x in r.length():
			var ch := r[x]
			if pal.has(ch):
				im.set_pixel(x, y, pal[ch])
	return im


func tex_from(key: String, rows: Array, pal: Dictionary) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var t := ImageTexture.create_from_image(img(rows, pal))
	_cache[key] = t
	return t


## A character palette from a look dictionary (hair, skin, cloth, shade, accent, pants, shoes).
func char_pal(look: Dictionary) -> Dictionary:
	return {
		"k": C.dark, "e": C.dark,
		"h": col(look.get("hair", "brown")), "s": col(look.get("skin", "skin2")),
		"c": col(look.get("cloth", "steel")), "d": col(look.get("shade", "slate")),
		"a": col(look.get("accent", "gold")), "p": col(look.get("pants", "navy")),
		"b": col(look.get("shoes", "white")), "w": C.white,
	}


## A 16 x 16 character frame, or 16 x 20 with a hat.
func char_tex(look: Dictionary, frame := "idle") -> Texture2D:
	var hat: String = look.get("hat", "none")
	var key := "char:%s:%s" % [str(look.hash()), frame]
	if _cache.has(key):
		return _cache[key]
	var rows: Array = []
	if look.get("mini", false):
		rows.append_array(MINI)
		rows.append_array(MINI_LEGS.get(frame, MINI_LEGS.idle))
		return tex_from(key, rows, char_pal(look))
	if hat != "none":
		rows.append_array(HATS[hat])
	rows.append_array(BODY)
	rows.append_array(LEGS.get(frame, LEGS.idle))
	return tex_from(key, rows, char_pal(look))


## Generated 16 x 16 tiles. kind: floor, wall, hazard, prop, desk, door, carpet.
func tile_tex(kind: String, pal: Dictionary) -> Texture2D:
	var key := "tile:%s:%s" % [kind, str(pal.hash())]
	if _cache.has(key):
		return _cache[key]
	var im := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	var a: Color = pal.get("floor", C.plum)
	var b: Color = pal.get("floor2", a.darkened(0.15))
	var w: Color = pal.get("wall", C.slate)
	var w2: Color = pal.get("wall2", w.darkened(0.35))
	var acc: Color = pal.get("accent", C.gold)
	match kind:
		"floor":
			im.fill(a)
			for i in 16:
				im.set_pixel(i, 15, b)
				im.set_pixel(15, i, b)
			im.set_pixel(4, 5, b); im.set_pixel(11, 9, b); im.set_pixel(7, 12, b)
		"wall":
			im.fill(w)
			for y in 16:
				for x in 16:
					var row := y / 4
					var off := 4 if row % 2 == 1 else 0
					if y % 4 == 3 or (x + off) % 8 == 7:
						im.set_pixel(x, y, w2)
			for x in 16:
				im.set_pixel(x, 0, w.lightened(0.25))
		"hazard":
			im.fill(a)
			var hz: Color = pal.get("hazard", C.teal)
			for y in range(2, 14):
				for x in range(2, 14):
					if (x + y) % 4 < 2:
						im.set_pixel(x, y, hz)
		"prop":
			im.fill(a)
			var pc: Color = C.brown
			for y in range(3, 15):
				for x in range(2, 14):
					im.set_pixel(x, y, pc if (x == 2 or x == 13 or y == 3 or y == 14 or x == y) else C.tan)
		"desk":
			im.fill(a)
			for y in range(4, 13):
				for x in range(0, 16):
					im.set_pixel(x, y, C.dark if (y == 4 or y == 12) else C.brown)
			for x in range(1, 15):
				im.set_pixel(x, 5, C.tan)
		"door":
			im.fill(w2)
			for y in range(2, 16):
				for x in range(3, 13):
					im.set_pixel(x, y, C.brown if (x != 3 and x != 12) else C.dark)
			im.set_pixel(10, 9, C.gold)
		"carpet":
			im.fill(pal.get("carpet", C.maroon))
			for x in 16:
				im.set_pixel(x, 0, acc)
				im.set_pixel(x, 15, acc)
		"grass":
			im.fill(C.green)
			var g2: Color = C.green.darkened(0.2)
			for p in [Vector2i(3, 4), Vector2i(10, 2), Vector2i(6, 11), Vector2i(13, 13), Vector2i(1, 9)]:
				im.set_pixel(p.x, p.y, g2); im.set_pixel(p.x, p.y + 1, g2)
				im.set_pixel(p.x + 1, p.y - 1, C.lime)
		"path":
			im.fill(C.sand)
			for p in [Vector2i(2, 3), Vector2i(9, 7), Vector2i(5, 12), Vector2i(13, 1)]:
				im.set_pixel(p.x, p.y, C.tan)
		_:
			im.fill(Color.MAGENTA)
	var t := ImageTexture.create_from_image(im)
	_cache[key] = t
	return t


## A small square texture of one colour, used for particles and blocks.
func dot(c: Color, size := 1) -> Texture2D:
	var key := "dot:%s:%d" % [c.to_html(), size]
	if _cache.has(key):
		return _cache[key]
	var im := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	im.fill(c)
	var t := ImageTexture.create_from_image(im)
	_cache[key] = t
	return t


## A pixel-font Label. size 8 is body text, 16 is title text.
func label(text: String, pos := Vector2.ZERO, color: Color = C.white, size := 8, outline := true) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline:
		l.add_theme_color_override("font_shadow_color", C.dark)
		l.add_theme_constant_override("shadow_offset_x", 1)
		l.add_theme_constant_override("shadow_offset_y", 1)
	l.add_theme_constant_override("line_spacing", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Width in pixels of text in the pixel font at a size.
func text_w(text: String, size := 8) -> int:
	return text.length() * 6 * (size / 8)


## Draws a framed panel with a 1 px outline onto a CanvasItem.
func panel(ci: CanvasItem, r: Rect2, fill: Color = C.night, edge: Color = C.mist) -> void:
	ci.draw_rect(r, C.dark)
	ci.draw_rect(r.grow(-1), edge)
	ci.draw_rect(r.grow(-2), fill)


## Draws text with the pixel font onto a CanvasItem. pos is the top-left.
func text(ci: CanvasItem, s: String, pos: Vector2, color: Color = C.white, size := 8, shadow := true) -> void:
	var base := pos + Vector2(0, 8 * (size / 8))
	if shadow:
		ci.draw_string(font, base + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, C.dark)
	ci.draw_string(font, base, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func text_c(ci: CanvasItem, s: String, cx: float, y: float, color: Color = C.white, size := 8, shadow := true) -> void:
	text(ci, s, Vector2(roundi(cx - text_w(s, size) / 2.0), y), color, size, shadow)


## A pixel bar: outline, background and a fill of n whole pixels.
func bar(ci: CanvasItem, r: Rect2, frac: float, fill: Color, back: Color = C.dark) -> void:
	ci.draw_rect(r, C.dark)
	ci.draw_rect(r.grow(-1), back)
	var inner := r.grow(-1)
	var w := floorf(inner.size.x * clampf(frac, 0.0, 1.0))
	ci.draw_rect(Rect2(inner.position, Vector2(w, inner.size.y)), fill)
