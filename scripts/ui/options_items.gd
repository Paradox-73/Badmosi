class_name OptionsItems
## Builds the Options menu rows, shared by the Options screen and the pause menu.


static func onoff(b: bool) -> String:
	return "ON" if b else "OFF"


static func build(include_difficulty := true) -> Array:
	var items := []
	items.append({"text": "MUSIC", "value": func(): return "%d%%" % roundi(Game.opts.music * 100),
		"change": func(d): Game.opts.music = clampf(Game.opts.music + d * 0.1, 0.0, 1.0); Game.apply_options(); Game.save_options()})
	items.append({"text": "SOUND", "value": func(): return "%d%%" % roundi(Game.opts.sfx * 100),
		"change": func(d): Game.opts.sfx = clampf(Game.opts.sfx + d * 0.1, 0.0, 1.0); Game.apply_options(); Game.save_options(); Audio.play("coin")})
	if include_difficulty:
		items.append({"text": "DIFFICULTY", "value": func(): return Game.diff_name(),
			"change": func(d): Game.difficulty = (Game.difficulty + d + 3) % 3})
	items.append({"text": "CRT FILTER", "value": func(): return onoff(Game.opts.crt),
		"change": func(_d): Game.opts.crt = not Game.opts.crt; Game.apply_options(); Game.save_options()})
	items.append({"text": "CRT CURVE", "value": func(): return "%d%%" % (int(Game.opts.crt_curve) * 10),
		"change": func(d): Game.opts.crt_curve = clampi(int(Game.opts.crt_curve) + d, 0, 10); Game.apply_options(); Game.save_options()})
	items.append({"text": "RHYTHM OFFSET", "value": func(): return "%d MS" % int(Game.opts.rhythm_offset),
		"change": func(d): Game.opts.rhythm_offset = clampi(int(Game.opts.rhythm_offset) + d * 10, -300, 300); Game.save_options()})
	items.append({"text": "CLEAN TEXT", "value": func(): return onoff(Game.opts.clean_text),
		"change": func(_d): Game.opts.clean_text = not Game.opts.clean_text; Game.save_options()})
	items.append({"text": "SCREEN SHAKE", "value": func(): return onoff(Game.opts.shake),
		"change": func(_d): Game.opts.shake = not Game.opts.shake; Game.save_options()})
	items.append({"text": "REDUCE FLASHING", "value": func(): return onoff(Game.opts.reduce_flash),
		"change": func(_d): Game.opts.reduce_flash = not Game.opts.reduce_flash; Game.save_options()})
	items.append({"text": "FULLSCREEN", "value": func(): return onoff(Game.opts.fullscreen),
		"change": func(_d): Game.opts.fullscreen = not Game.opts.fullscreen; Game.apply_options(); Game.save_options()})
	return items
