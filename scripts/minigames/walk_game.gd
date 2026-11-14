class_name WalkGame
extends Minigame
## Base for minigames played by walking Pix around the club room
## (Parvaaz's stage fright, the SAC's house rules).

var pix: Player
var room: Room


func _ready() -> void:
	super._ready()
	room = get_parent().get("room")
	pix = Player.new()
	pix.room = room
	pix.input_enabled = false
	pix.position = room.cell_center(room.entrance) + Vector2(16, 6)
	add_child(pix)
	var parent_pix = get_parent().get("player")
	if parent_pix:
		parent_pix.visible = false


func _exit_tree() -> void:
	var parent_pix = get_parent().get("player") if get_parent() else null
	if parent_pix:
		parent_pix.visible = true
		parent_pix.position = pix.position


func begin() -> void:
	pix.input_enabled = true


func finish(won: bool, acc: float) -> void:
	pix.input_enabled = false
	super.finish(won, acc)
