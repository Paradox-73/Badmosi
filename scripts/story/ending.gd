extends Node2D
## After the Admin falls: Circular No. 404 is revoked, then the whole gang and
## every freed club head eat together at Corner House. Last, the run's report
## card: "Iss sem ki badmosi".

var t := 0.0
var heads := []
var gang := []
var done := false
var stamped := false
var best := 0.0


func _ready() -> void:
	Audio.play_music("theme_" + Game.character)
	for id in Clubs.ORDER:
		heads.append(Px.char_tex(Clubs.get_club(id).head_look, "idle"))
	for id in Roster.ORDER:
		if id != Game.character:
			gang.append(Roster.get_char(id).look)
	if not Game.practice:
		if Game.speedrun:
			best = float(Game.opts.get("best_time", 0.0))
			if best <= 0.0 or Game.run_time < best:
				best = Game.run_time
				Game.opts["best_time"] = best
				Game.save_options()
		Game.save_run()


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if t > 1.0 and not stamped:
		stamped = true
		Audio.play("stamp", 0.0)
		Fx.shake(3, 0.2)
	var ready := t > 13.0 or (Game.autoplay and t > 12.0)
	if ready and not done and (Input.is_action_just_pressed("accept") or Input.is_action_just_pressed("pause") or Game.autoplay and t > 16.0):
		done = true
		Game.goto("credits")


func _draw() -> void:
	draw_rect(Rect2(0, 0, Px.W, Px.H), Px.C.ink)
	if t < 4.0:
		_revoked()
	elif t < 12.0:
		_cornerhouse(t - 4.0)
	else:
		_report()


func _revoked() -> void:
	var r := Rect2(110, 40, 164, 120)
	draw_rect(r, Px.C.white)
	Px.text_c(self, "CIRCULAR NO. 404", Px.W / 2.0, 50, Px.C.ink)
	for i in 6:
		draw_rect(Rect2(122, 66 + i * 12, 140 - (i % 3) * 20, 2), Px.C.slate)
	if t > 1.0:
		var s := 24 if t < 1.2 else 16
		Px.text_c(self, "REVOKED", Px.W / 2.0, 92, Px.C.red, s)
	if t > 2.0:
		Px.text_c(self, "EVERY CLUB IS FREE. THE LOCKDOWN IS OVER.", Px.W / 2.0, 172, Px.C.gold)


const CH_PURPLE := Color("8652a1")
const CH_BROWN := Color("4e2f27")
const CH_CREAM := Color("fff3f0")


func _cornerhouse(k: float) -> void:
	# Corner House in its own colours, sampled from the brand's logo: a purple and
	# white striped awning, chocolate-brown lettering on cream.
	draw_rect(Rect2(0, 24, Px.W, 192), CH_CREAM)
	draw_rect(Rect2(0, 94, Px.W, 122), CH_PURPLE.darkened(0.15))     # purple lower wall
	for x in range(0, Px.W, 12):
		draw_rect(Rect2(x, 24, 6, 14), CH_PURPLE)                     # awning stripes
		draw_rect(Rect2(x + 6, 24, 6, 14), Color.WHITE)
		draw_rect(Rect2(x + 1, 38, 4, 2), CH_PURPLE)                  # scalloped edge
		draw_rect(Rect2(x + 7, 38, 4, 2), Color.WHITE)
	var sign := Rect2(Px.W / 2.0 - 66, 44, 132, 30)
	Px.panel(self, sign, CH_CREAM, CH_PURPLE)
	var lit := int(k * 4.0) % 6 != 0
	Px.text_c(self, "CORNER HOUSE", Px.W / 2.0, 49, CH_BROWN if lit else CH_PURPLE, 8)
	Px.text_c(self, "ICE CREAMS", Px.W / 2.0, 62, CH_PURPLE)
	# Back row: club heads arrive one by one. Front row: the gang.
	var n := clampi(int(k * 3.0), 0, heads.size())
	for i in n:
		var x := 18 + i * 27
		draw_texture(heads[i], Vector2(x, 84 - (int(k * 4.0 + i) % 2)))
	var g := clampi(int(k * 4.0), 0, gang.size())
	for i in g:
		var x2 := 12 + i * 18
		draw_texture(Px.char_tex(gang[i], "idle"), Vector2(x2, 140 - (int(k * 5.0 + i) % 2)))
	draw_rect(Rect2(8, 108, Px.W - 16, 22), CH_BROWN)
	draw_rect(Rect2(8, 108, Px.W - 16, 3), CH_CREAM)
	# Death by Chocolate, one for everybody.
	for i in 14:
		var bx := 20 + i * 26
		draw_rect(Rect2(bx, 102, 8, 8), Px.C.white)
		draw_rect(Rect2(bx + 1, 98, 6, 5), Px.C.brown)
		draw_rect(Rect2(bx + 3, 96, 2, 2), Px.C.red)
	var you := Px.char_tex(Game.pix_look(), "walk1" if int(k * 3.0) % 2 == 0 else "idle")
	draw_texture_rect(you, Rect2(Vector2(Px.W / 2.0 - 16, 162), you.get_size() * 2), false)
	Px.text_c(self, "DEATH BY CHOCOLATE FOR EVERYONE. %s IS PAYING." % Game.char_name(), Px.W / 2.0, 202, Px.C.white)


## The run's report card.
func _report() -> void:
	Px.text_c(self, "ISS SEM KI BADMOSI", Px.W / 2.0, 10, Px.C.gold, 16)
	var tl: Dictionary = Game.tallies
	var rows := [
		["PLAYED AS", Game.char_name()],
		["TIME", Game.clock(Game.run_time) + ("  (BEST %s)" % Game.clock(best) if Game.speedrun else "")],
		["CLUBS FREED STRAIGHT / BY FLIPPING", "%d / %d" % [Game.straight_count(), Game.flipped_count()]],
		["FINES PAID", "%d PX" % int(tl.get("fines", 0))],
		["CAUGHT BY SECURITY", str(int(tl.get("caught", 0)))],
		["ADMIN SABOTAGES SURVIVED", str(int(tl.get("sabotage", 0)))],
		["DETAINED (PARENTS MAILED)", str(int(tl.get("detained", 0)))],
		["JUICY INCIDENTS", str(int(tl.get("juicy", 0)))],
		["TRUFFLES ORDERS", str(int(tl.get("truffles", 0)))],
	]
	if Game.quirk() == "phone":
		rows.append(["TIMES LOST TO THE PHONE", str(int(tl.get("phone", 0)))])
	var y := 36
	for r in rows:
		Px.text(self, r[0], Vector2(40, y), Px.C.mist)
		Px.text(self, r[1], Vector2(Px.W - 40 - Px.text_w(r[1]), y), Px.C.white)
		y += 14
	Px.text_c(self, "CAMPUS IS FREE. PRESS J.", Px.W / 2.0, Px.H - 14, Px.C.gold)
