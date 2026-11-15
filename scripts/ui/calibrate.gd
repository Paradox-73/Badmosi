extends Node2D
## Rhythm offset: tap J on 8 beats; the game sets the offset from the average error.

var taps := []
var t := 0.0
var started := false
var result := ""


func _exit_tree() -> void:
	Audio.tempo_lock = false


func _ready() -> void:
	Audio.tempo_lock = true
	Audio.play_music("dance")


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("pause"):
		Game.goto("menu")
		return
	if (Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("accept")) and taps.size() < 8:
		var bl := Audio.beat_len()
		var st := Audio.song_time() + float(Game.opts.rhythm_offset) / 1000.0
		var err := st - roundf(st / bl) * bl
		taps.append(err)
		Audio.play("tick", 0.0)
		if taps.size() == 8:
			var sum := 0.0
			for e in taps:
				sum += e
			var off := roundi(sum / taps.size() * 1000.0)
			Game.opts.rhythm_offset = clampi(off, -300, 300)
			Game.save_options()
			result = "OFFSET SET TO %d MS. PRESS K TO GO BACK." % Game.opts.rhythm_offset


func _draw() -> void:
	draw_rect(Rect2(0, 0, Px.W, Px.H), Px.C.ink)
	Px.text_c(self, "RHYTHM CALIBRATION", Px.W / 2.0, 20, Px.C.gold, 16)
	Px.text_c(self, "PRESS J ON EVERY KICK DRUM. 8 TAPS.", Px.W / 2.0, 60, Px.C.white)
	var bl := Audio.beat_len()
	var ph := fmod(Audio.song_time(), bl) / bl
	var s := 24 if ph < 0.15 else 16
	draw_rect(Rect2(Px.W / 2.0 - s / 2.0, 100 - s / 2.0, s, s), Px.C.pink if ph < 0.15 else Px.C.plum)
	for i in 8:
		draw_rect(Rect2(Px.W / 2.0 - 64 + i * 16, 140, 12, 12), Px.C.gold if i < taps.size() else Px.C.slate)
	Px.text_c(self, result if result != "" else "CURRENT OFFSET: %d MS" % int(Game.opts.rhythm_offset), Px.W / 2.0, 170, Px.C.mist)
