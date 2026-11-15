class_name Hud
extends Node2D
## The 24 px band at the top: Attendance, Proxies, SEM, pixels, the special
## and Hype in fights, or the minigame's goal. Also the club head's health bar.

var mode := "fight"     # fight, minigame or hub
var goal := ""
var hold_f := 0.0        # 0..1 progress of the F-it hold
var boss: Node = null
var _t := 0.0
var show_fit_hint := true


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, Px.W, Px.TOP), Px.C.ink)
	draw_rect(Rect2(0, Px.TOP - 1, Px.W, 1), Px.C.plum)
	var att := Game.attendance
	var low := att < 30.0
	var col: Color = Px.C.lime if att >= 60 else (Px.C.gold if att >= 30 else Px.C.red)
	Px.text(self, "ATTENDANCE", Vector2(3, 3), Px.C.steel if not low or int(_t * 4) % 2 == 0 else Px.C.red)
	# Bar built from 2 px blocks.
	var bx := 66
	for i in 25:
		var filled := att >= (i + 1) * 4 - 2
		draw_rect(Rect2(bx + i * 3, 3, 2, 7), col if filled else Px.C.plum)
	Px.text(self, "%d%%" % roundi(att), Vector2(bx + 78, 3), col)
	var right := "PROXY x%d  SEM %d  %d PX" % [Game.proxies, Game.sem, Game.pixels]
	Px.text(self, right, Vector2(Px.W - Px.text_w(right) - 3, 3), Px.C.white)
	if low and int(_t * 4) % 2 == 0:
		Px.text(self, "LOW!", Vector2(bx + 104, 3), Px.C.red)
	if mode == "fight":
		var sp: Dictionary = Game.current_special()
		Px.text(self, "L:" + sp.name, Vector2(3, 13), Px.C.cyan)
		Px.text(self, "HYPE", Vector2(100, 13), Px.C.steel)
		for i in 10:
			var on := Game.hype > i
			var cost_mark := i < int(sp.cost)
			draw_rect(Rect2(128 + i * 5, 14, 4, 6), (Px.C.gold if on else (Px.C.plum if cost_mark else Px.C.night)))
		if Game.quirk() == "dhairya":
			var rage := Game.rage_t > 0.0
			Px.text(self, "RAGE!" if rage else "DHAIRYA", Vector2(184, 13), Px.C.red if rage else Px.C.steel)
			Px.bar(self, Rect2(230, 14, 40, 6), 1.0 if rage else Game.dhairya / 100.0, Px.C.red if rage or Game.dhairya < 30.0 else Px.C.orange)
		var cards := "CARDS %d/%d" % [Game.club_card_count(), Clubs.ORDER.size()]
		Px.text(self, cards, Vector2(Px.W - Px.text_w(cards) - 3, 13), Px.C.mist)
	elif mode == "minigame":
		var room := Px.W - 6
		if show_fit_hint:
			room -= _w("HOLD F: " + Game.fit_words()) + 8
		Px.text(self, _fit(goal, room), Vector2(3, 13), Px.C.gold)
		if show_fit_hint:
			var hint := "HOLD F: " + Game.fit_words()
			if Game.opts.clean_text:
				Px.text(self, hint, Vector2(Px.W - _w(hint) - 3, 13), Px.C.steel)
			else:
				Px.text(self, "HOLD F: F", Vector2(Px.W - _w(hint) - 3, 13), Px.C.steel)
				_censor(Vector2(Px.W - _w(hint) - 3 + _w("HOLD F: F"), 13), 3)
				Px.text(self, " IT!", Vector2(Px.W - Px.text_w(" IT!") - 3, 13), Px.C.steel)
		if hold_f > 0.0:
			Px.bar(self, Rect2(Px.W - 120, 21, 117, 3), hold_f, Px.C.red)
	elif mode == "hub":
		var cards2 := "CLUB CARDS %d/%d" % [Game.club_card_count(), Clubs.ORDER.size()]
		Px.text(self, cards2, Vector2(3, 13), Px.C.gold)
		var food := ", ".join(Game.buffs.keys().map(func(k): return Game.BUFFS[k].name))
		if food != "":
			Px.text(self, food, Vector2(110, 13), Px.C.red if Game.has_buff("upset") else Px.C.lime)
		var spn := "SIDE CLUBS %d/%d" % [Clubs.SIDE.filter(func(i): return Game.cards.has(i)).size(), Clubs.SIDE.size()]
		Px.text(self, spn, Vector2(Px.W - Px.text_w(spn) - 3, 13), Px.C.cyan)
		# Bottom strip: the jogging-track score and the phone.
		var walk := "WALKED %.2f KM   LAPS %d   L: PHONE   I: MAP" % [float(Game.tallies.get("walk_m", 0.0)) / 1000.0, int(Game.tallies.get("laps", 0))]
		if Game.truffles_t >= 0.0:
			walk += "   %s: %s" % [Game.order_item, "ON ITS WAY" if Game.truffles_t == 0.0 else "%dS" % ceili(Game.truffles_t)]
		draw_rect(Rect2(0, Px.H - 11, Px.text_w(walk) + 6, 11), Color(Px.C.ink, 0.8))
		Px.text(self, walk, Vector2(3, Px.H - 9), Px.C.lime)
	if Game.speedrun:
		var clk := Game.clock(Game.run_time)
		var w2 := Px.text_w(clk) + 6
		draw_rect(Rect2(Px.W - w2 - 2, Px.TOP + 1, w2, 10), Color(Px.C.ink, 0.8))
		Px.text(self, clk, Vector2(Px.W - w2 + 1, Px.TOP + 2), Px.C.lime)
	if boss and is_instance_valid(boss) and boss.active:
		var d: Dictionary = Clubs.get_club(boss.club)
		var w := 200
		var r := Rect2(Px.W / 2.0 - w / 2.0, Px.H - 10, w, 6)
		Px.text_c(self, d.head, Px.W / 2.0, Px.H - 20, Px.C.white)
		Px.bar(self, r, boss.hp / boss.max_hp, Px.C.red)


## Width of s as drawn: on a pad, prompts read "HOLD LT+RT" instead of "HOLD F".
func _w(s: String) -> int:
	return Px.text_w(Game.pad_text(s) if Game.pad else s)


## Cuts s to w pixels with ".." at the end. The minigame goal shares its row with the
## hold-F hint, and long goals ran underneath it. The full goal is on the key card.
func _fit(s: String, w: int) -> String:
	if Px.text_w(s) <= w:
		return s
	while s.length() > 1 and Px.text_w(s + "..") > w:
		s = s.substr(0, s.length() - 1)
	return s.strip_edges() + ".."


## A pixel-mosaic censor block over n characters.
func _censor(pos: Vector2, n: int) -> void:
	var cols := [Px.C.pink, Px.C.violet, Px.C.gold, Px.C.cyan, Px.C.red]
	for i in n * 2:
		for j in 3:
			var c: Color = cols[(i * 3 + j + int(_t * 6)) % cols.size()]
			draw_rect(Rect2(pos + Vector2(i * 3, j * 3), Vector2(3, 3)), c)
