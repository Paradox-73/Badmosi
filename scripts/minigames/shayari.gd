extends "res://scripts/minigames/terminal.gd"
## Alfaaz: shayari. A two-line sher with its last word missing. Pick the
## word that rhymes (the qaafiya). A wrong word crumbles into ink pixels.

# [line 1, line 2 without its last word, rhyme, wrong, wrong]
const SHERS := [
	["PADHI NAHI MAINE EK BHI KITAAB,", "PHIR BHI LIKH AAYA LAMBA", "JAWAAB", "PANNA", "NOTE"],
	["HOSTEL KA WIFI PHIR SE GAYA,", "DEADLINE KA DAR PHIR SE", "AAYA", "BADHA", "LAGA"],
	["CANTEEN KI CHAI, HAATH MEIN PYAALA,", "EXAM KI RAAT MEIN YAHI", "UJAALA", "SAATHI", "DAWAA"],
	["THE LAB WAS COLD, THE CODE WAS OLD,", "BUT STILL IT RAN, OR SO I'M", "TOLD", "SURE", "SAID"],
	["MY CGPA IS JUST A NUMBER, THEY SAY,", "I'LL COUNT IT AGAIN SOME OTHER", "DAY", "TIME", "WEEK"],
	["PROFESSOR NE KAHA, ATTENDANCE ZAROORI,", "DOSTON NE MILKAR KI HAAZRI", "POORI", "AADHI", "KHAALI"],
	["MESS KA KHAANA, ROZ WAHI DAAL,", "PHIR BHI KHAATE RAHE SAARA", "SAAL", "DIN", "HAFTA"],
	["I PUSHED TO MAIN AT HALF PAST THREE,", "NOW EVERY BUG BELONGS TO", "ME", "US", "THEM"],
	["SYLLABUS DEKHA, HUA BURA HAAL,", "TOPPER NE POOCHHA, KAUNSA", "SAWAAL", "JAWAAB", "MASLA"],
	["THE FEST LIGHTS GLOW ACROSS THE GROUND,", "AND EVERY CLUB HAS GATHERED", "ROUND", "NEAR", "HERE"],
	["BAARISH MEIN BHEEGE, CYCLE PE SAWAAR,", "CLASS MEIN PAHUNCHE, BAJ GAYE", "CHAAR", "DO", "PAANCH"],
	["I MADE A GAME WITH PIXELS SMALL,", "ONE SQUARE AT A TIME, I DREW THEM", "ALL", "BIG", "NOW"],
]


func info() -> Dictionary:
	return {"goal": "FINISH 6 OF 8 SHERS. PICK THE LAST WORD THAT RHYMES WITH LINE ONE.",
		"keys": ["ARROWS: PICK A WORD   J: RECITE"], "time": 999.0}


func _ready() -> void:
	count = 8
	need = 6
	super._ready()
	# The bank's prompt slot holds both lines; split them back out.
	for r in rounds:
		var parts: PackedStringArray = r.prompt.split("|")
		r.line1 = parts[0]
		r.line2 = parts[1]


func bank() -> Array:
	var out := []
	for s in SHERS:
		out.append([s[0] + "|" + s[1], s[2], s[3], s[4], ""])
	return out


func per_q() -> float:
	return 10.0 * Game.time_mult() * (0.6 if short_round else 1.0) / speedup


func goal_text() -> String:
	return "SHER %d/%d   WAH WAH %d/%d" % [mini(ri + 1, rounds.size()), rounds.size(), right, need]


func on_right(_r: Dictionary) -> void:
	Fx.word(["WAH WAH!", "IRSHAAD!", "MUKARRAR!"].pick_random(), Vector2(Px.W / 2.0, 110), Px.C.gold)
	Fx.burst(Vector2(Px.W / 2.0, 96), [Px.C.gold, Px.C.white], 16, null, 0, 60.0)


func on_wrong(_r: Dictionary, _k: int) -> void:
	penalty(10.0, "THAT DOESN'T RHYME!", Vector2(Px.W / 2.0, 110))


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.night, 0.96))
	# A scroll of paper with an ink pot.
	var page := Rect2(24, 34, 336, 92)
	draw_rect(page, Px.C.dark)
	draw_rect(page.grow(-1), Px.C.sand)
	for x in range(28, 356, 6):
		draw_rect(Rect2(x, 36, 3, 1), Px.C.tan)
		draw_rect(Rect2(x + 3, 122, 3, 1), Px.C.tan)
	draw_rect(Rect2(332, 104, 14, 12), Px.C.ink)
	draw_rect(Rect2(334, 102, 10, 2), Px.C.slate)
	draw_rect(Rect2(342, 88, 2, 14), Px.C.white)
	if ri < rounds.size():
		var r: Dictionary = rounds[ri]
		Px.text_c(self, "ALFAAZ MUSHAIRA - SHER %d" % (ri + 1), Px.W / 2.0, 42, Px.C.maroon, 8, false)
		Px.text_c(self, r.line1, Px.W / 2.0, 64, Px.C.dark, 8, false)
		var word: String = "____" if answered < 0 else r.opts[r.ans]
		Px.text_c(self, r.line2 + " " + word, Px.W / 2.0, 80, Px.C.dark, 8, false)
		Px.text_c(self, "(QAAFIYA: THE RHYME)", Px.W / 2.0, 104, Px.C.brown, 8, false)
		Px.text(self, "WHICH WORD ENDS THE SHER?", Vector2(40, 134), Px.C.gold)
		draw_options(r, Px.C.white)
	draw_card()
