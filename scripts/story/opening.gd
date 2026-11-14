extends Node2D
## The opening at the main gate, after the flashback: brainwashed club
## members on patrol, an SAC enforcer reads Circular No. 404 and picks the
## tutorial fight.

var pausable := true
var room: Room
var player: Player
var hud: Hud
var npcs := []
var fight: Fight


func _ready() -> void:
	room = Room.new()
	room.pal = {"floor": Px.C.jade.darkened(0.2), "wall": Px.C.tan.darkened(0.3), "hazard": Px.C.teal}
	room.load_rows(Room.parse("""########################
#......................#
#..m.......t...........#
#......................#
#......................#
@...........X..........#
#......................#
#......................#
#.........m............#
#......................#
#......................#
########################"""))
	add_child(room)
	player = Player.new()
	player.room = room
	player.position = room.cell_center(room.entrance) + Vector2(16, 6)
	player.input_enabled = false
	add_child(player)
	hud = Hud.new()
	hud.mode = "fight"
	Game.main.ui.add_child(hud)
	for id in ["impulse", "zense", "eightbit", "quiz"]:
		var a := Actor.new()
		a.set_look(Clubs.get_club(id).look)
		npcs.append(a)
		add_child(a)
	for i in npcs.size():
		npcs[i].position = Vector2(120 + i * 60, 70)
	var enf := Actor.new()
	enf.set_look(Clubs.get_club("sac").look)
	enf.position = Vector2(300, 140)
	enf.sprite.flip_h = true
	add_child(enf)
	npcs.append(enf)
	Audio.play_music("hub")
	_run()


func _run() -> void:
	var tw := create_tween()
	tw.tween_property(player, "position:x", 110.0, 1.2)
	var me := Game.char_name()
	await _talk([
		{"who": me, "text": "MAIN GATE. CHAINED. AND THE CLUBS ARE ON PATROL. GREAT.", "look": Game.pix_look()},
		{"who": "IMPULSE", "text": "5-6-7-COMPLY. 5-6-7-COMPLY.", "look": Clubs.get_club("impulse").look},
		{"who": "ZENSE", "text": "ERROR 404: STUDENT FUN NOT FOUND. PLEASE RETURN TO HOSTEL.", "look": Clubs.get_club("zense").look},
		{"who": "8-BIT", "text": "TODAY'S HEADLINE: EVERYTHING IS FINE, SAYS THE ADMIN.", "look": Clubs.get_club("eightbit").look},
		{"who": me, "text": "THEY'RE BRAINWASHED. ALL OF THEM.", "look": Game.pix_look()},
		{"who": "SAC ENFORCER", "text": "CIRCULAR NO. 404: EVERY CLUB NOW ANSWERS TO THE ADMIN. YOU ARE OUT AFTER CURFEW.", "look": Clubs.get_club("sac").look},
		{"who": "SAC ENFORCER", "text": "THAT'S A FINE. HAND OVER YOUR PIXELS.", "look": Clubs.get_club("sac").look},
	])
	for i in 4:
		npcs[i].queue_free()
	npcs[4].queue_free()
	Fx.word("FIGHT!", Vector2(Px.W / 2.0, 70), Px.C.red, 16)
	fight = Fight.new()
	fight.no_boss = true
	add_child(fight)
	fight.setup("sac", room, player)
	fight.spawn_enemy("member", Vector2i(18, 8))
	fight.spawn_enemy("member", Vector2i(17, 3))
	fight.banner("J: ATTACK (PRESS 3x FOR A COMBO)   K: DODGE")
	player.input_enabled = true
	Audio.play_music("fight")
	fight.won.connect(_after_fight)
	fight.lost.connect(func(): Game.attendance = 100.0; Game.goto("opening"))


func _after_fight() -> void:
	Audio.play_music("hub")
	var me := Game.char_name()
	await _talk([
		{"who": me, "text": "THIRTEEN CLUBS. BEAT EACH ONE AT ITS OWN GAME AND IT SNAPS OUT OF IT.", "look": Game.pix_look()},
		{"who": me, "text": "FREED CLUBS WILL OWE US. AND IF A GAME IS RIGGED... HOLD F. FLIP THE TABLE.", "look": Game.pix_look()},
	])
	Game.save_run()
	Game.goto("hub")


func _talk(pages: Array) -> void:
	var d := DialogueBox.new()
	d.pages = pages
	Game.main.ui.add_child(d)
	await d.finished
