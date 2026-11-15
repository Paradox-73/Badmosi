extends Node2D
## Scrolling credits, from CREDITS.md.

var t := 0.0
var lines := [
	["BADMOSI", "gold"], ["", ""],
	["A GAME BY TEAM CLAUDE LAGGYE", "white"], ["FOR SYNERGY '26 GAME DEV", "mist"], ["", ""],
	["MADE WITH GODOT 4.7.2", "cyan"], ["", ""],
	["ART", "gold"], ["EVERY SPRITE, TILE AND FONT GLYPH", "white"], ["IS DRAWN PIXEL BY PIXEL IN OUR CODE", "white"], ["", ""],
	["MUSIC AND SOUND", "gold"], ["A CHIPTUNE SYNTH WE WROTE", "white"], ["SQUARE, TRIANGLE, SAW AND NOISE", "white"], ["", ""],
	["MELODY", "gold"], ["ODE TO JOY - L. VAN BEETHOVEN", "white"], ["(PUBLIC DOMAIN)", "mist"], ["", ""],
	["THANKS", "gold"], ["EVERY IIIT-B CLUB, FOR BEING", "white"], ["GOOD SPORTS ABOUT THIS", "white"], ["", ""],
	["ALL CHARACTERS ARE INVENTED.", "mist"], ["THE ADMIN IS AN OFFICE, NOT A PERSON.", "mist"], ["", ""],
	["404 CLUB FOUND.", "lime"],
]


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if t > 0.5 and (Input.is_action_just_pressed("accept") or Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("pause")):
		Game.goto("menu")


func _draw() -> void:
	draw_rect(Rect2(0, 0, Px.W, Px.H), Px.C.ink)
	var y0 := Px.H - t * 22.0
	if y0 + lines.size() * 12 < 0:
		t = 0.0
	for i in lines.size():
		var y := y0 + i * 12
		if y > -10 and y < Px.H:
			Px.text_c(self, lines[i][0], Px.W / 2.0, roundf(y), Px.col(lines[i][1]) if lines[i][1] != "" else Px.C.white, 16 if i == 0 else 8)
