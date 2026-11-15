class_name NameCard
extends Node2D
## Freeze-frame introduction for a club head: portrait, name, club, three joke stats.

signal finished

var club := ""
## One-line tells for the eight shared attack pieces, shown on the card.
const TELLS := {
	"tiles": "GLOWING TILES, STEP OFF", "fan": "THROWN FAN, DASH THRU",
	"dash": "CHARGE, SIDESTEP", "ring": "SHOCK RINGS, DASH THRU",
	"summon": "CALLS HELP, CLEAR THEM", "hazard": "FLOOR SPILLS, AVOID",
	"freeze": "FREEZE, KEEP MOVING", "shield": "SHIELD, WAIT IT OUT",
}

var t := 0.0
var done := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if t > 0.4 and Input.is_action_just_pressed("accept"):
		t = 4.5
	if t >= 4.5 and not done:
		done = true
		get_tree().paused = false
		finished.emit()
		queue_free()


func _draw() -> void:
	var d: Dictionary = Clubs.get_club(club)
	var slide := clampf(t / 0.2, 0.0, 1.0)
	var x := roundf(lerpf(-Px.W, 0, slide))
	draw_rect(Rect2(0, 56, Px.W, 104), Color(Px.C.ink, 0.85))
	draw_rect(Rect2(x, 60, Px.W, 96), Px.col(d.wall).darkened(0.4))
	for i in 12:
		draw_rect(Rect2(x + i * 34 - fmod(t * 40.0, 34.0), 60, 14, 96), Color(Px.C.white, 0.04))
	# Portrait at 3x, in a frame.
	var tex: Texture2D
	if club == "admin":
		tex = Px._cache.get("admin")
	if tex == null:
		tex = Px.char_tex(d.head_look, "idle")
	var s := 3 if tex.get_height() <= 20 else 2
	var pr := Rect2(x + 24, 66, 64, 84)
	Px.panel(self, pr, Px.C.night, Px.C.gold)
	draw_texture_rect(tex, Rect2(pr.position + Vector2((64 - tex.get_width() * s) / 2.0, 84 - tex.get_height() * s - 6), tex.get_size() * s), false)
	Px.text(self, d.head, Vector2(x + 100, 70), Px.C.gold, 16)
	Px.text(self, d.name + " - " + d.full, Vector2(x + 100, 92), Px.C.white)
	for i in 2:
		Px.text(self, "> " + d.stats[i], Vector2(x + 100, 108 + i * 12), Px.C.mist)
	# What the fight is: the head's two attacks and how to beat each.
	for i in d.get("attacks", []).size():
		Px.text(self, "! " + TELLS.get(d.attacks[i], d.attacks[i].to_upper()), Vector2(x + 100, 132 + i * 12), Px.C.gold)
