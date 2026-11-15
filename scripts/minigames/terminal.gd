extends Minigame
## Genesys: terminal. A task appears; pick the command that does it from 3.
## A wrong command glitches the terminal into loose pixels. 7 of 10 to pass.
## shayari.gd reuses this pick-one-of-three loop with its own bank and art.

const BANK := [
	["LIST FILES", "ls", "rm -rf *", "cat ls", "notes.txt  game/  todo.md"],
	["GO UP A FOLDER", "cd ..", "rmdir ..", "mv .. .", "/home/fresher"],
	["FIND 'TODO' IN FILES", "grep -r TODO .", "find TODO", "rm -r TODO", "main.c:12: // TODO fix"],
	["SHOW RUNNING PROCESSES", "ps aux", "kill -9 -1", "top secret", "PID 1 init  PID 42 godot"],
	["PRINT THE CURRENT FOLDER", "pwd", "passwd", "whoami", "/home/fresher/club"],
	["MAKE A FOLDER CALLED ART", "mkdir art", "rm -r art", "cd art", "(folder art created)"],
	["READ NOTES.TXT", "cat notes.txt", "rm notes.txt", "> notes.txt", "buy chai. fix bug."],
	["WHO AM I LOGGED IN AS", "whoami", "sudo su", "passwd", "fresher"],
	["SHOW FREE DISK SPACE", "df -h", "dd if=/dev/zero of=/dev/sda", "du -rm /", "/dev/sda1  42G free"],
	["COPY A.TXT TO B.TXT", "cp a.txt b.txt", "mv b.txt a.txt", "rm a.txt", "(b.txt written)"],
	["SEE UNSAVED GIT CHANGES", "git status", "git push --force", "git reset --hard", "modified: main.c"],
	["MAKE RUN.SH RUNNABLE", "chmod +x run.sh", "chmod 000 /", "rm run.sh", "-rwxr-xr-x run.sh"],
	["CLEAR THE SCREEN", "clear", "shutdown now", "exit", ""],
	["SHOW LAST LINES OF A LOG", "tail log.txt", "rm log.txt", "> log.txt", "[ok] server up"],
	["INSTALL UPDATES", "sudo apt update", "sudo rm -rf /", "apt remove sudo", "reading package lists..."],
]

var rounds := []    # {prompt, opts: Array, ans: int, out: String}
var ri := 0
var sel := 0
var answered := -1
var ans_t := 0.0
var q_t := 0.0
var right := 0
var need := 7
var count := 10
var history := ["genesys club shell. type carefully."]
var bot_t := 0.0


func info() -> Dictionary:
	return {"goal": "GET 7 OF 10 TASKS RIGHT. PICK THE COMMAND THAT DOES THE TASK.",
		"keys": ["ARROWS: PICK A COMMAND   J: RUN IT"], "time": 999.0}


func bank() -> Array:
	return BANK


func uses_timer() -> bool:
	return false


func _ready() -> void:
	super._ready()
	if short_round:
		need = 2
		count = 2
	var b := bank().duplicate()
	b.shuffle()
	for i in mini(count, b.size()):
		var row: Array = b[i]
		var opts := [row[1], row[2], row[3]]
		opts.shuffle()
		rounds.append({"prompt": row[0], "opts": opts, "ans": opts.find(row[1]), "out": row[4]})


func per_q() -> float:
	return 8.0 * Game.time_mult() * (0.7 if short_round else 1.0) / speedup


func goal_text() -> String:
	return "TASK %d/%d   RIGHT %d/%d" % [mini(ri + 1, rounds.size()), rounds.size(), right, need]


func tick(delta: float) -> void:
	if ri >= rounds.size():
		return
	if answered >= 0:
		ans_t -= delta
		if ans_t <= 0.0:
			_next()
		return
	q_t += delta
	var r: Dictionary = rounds[ri]
	if Game.autoplay:
		bot_t -= delta
		if bot_t <= 0.0 and q_t > 0.8:
			bot_t = 0.3
			if sel == r.ans:
				_answer(sel)
			else:
				sel = (sel + 1) % 3
				Audio.play("move", 0.0)
		return
	if Input.is_action_just_pressed("up"):
		sel = (sel + 2) % 3
		Audio.play("move", 0.0)
	if Input.is_action_just_pressed("down"):
		sel = (sel + 1) % 3
		Audio.play("move", 0.0)
	if _clicked:
		_clicked = false
		for k in 3:
			if opt_rect(k).has_point(cursor):
				sel = k
				_answer(k)
				return
	if Input.is_action_just_pressed("attack"):
		_answer(sel)
	elif q_t >= per_q():
		answered = 9
		ans_t = 1.0
		penalty(10.0, "TIMED OUT!")


func _answer(k: int) -> void:
	var r: Dictionary = rounds[ri]
	answered = k
	ans_t = 0.9
	if k == r.ans:
		right += 1
		Audio.play("right", 0.0)
		on_right(r)
	else:
		Fx.burst(opt_rect(k).get_center(), [Px.C.lime, Px.C.red, Px.C.dark], 28, null, 0, 110.0)
		Fx.flash(Color(Px.C.red, 0.5), 0.08)
		on_wrong(r, k)


func on_right(r: Dictionary) -> void:
	history.append("$ " + r.opts[r.ans])
	if r.out != "":
		history.append(r.out)
	else:
		history.clear()
	Fx.word(["SUDO!", "GREP!", "OK!"].pick_random(), Vector2(Px.W / 2.0, 120), Px.C.lime)


func on_wrong(r: Dictionary, k: int) -> void:
	history.append("$ " + r.opts[k])
	history.append("ERROR: SEGMENTATION FAULT (PIXELS DUMPED)")
	penalty(10.0, "WRONG COMMAND!", Vector2(Px.W / 2.0, 120))


func _next() -> void:
	ri += 1
	q_t = 0.0
	answered = -1
	sel = 0
	if ri >= rounds.size():
		finish(right >= need, float(right) / rounds.size())


func opt_rect(k: int) -> Rect2:
	return Rect2(40, 148 + k * 14, 304, 13)


func draw_options(r: Dictionary, col: Color) -> void:
	for k in 3:
		var o := opt_rect(k)
		var fill: Color = Px.C.night
		if answered >= 0 and k == r.ans:
			fill = Px.C.green
		elif answered == k:
			fill = Px.C.maroon
		Px.panel(self, o, fill, Px.C.gold if k == sel and answered < 0 else Px.C.slate)
		Px.text(self, "%s %s" % ["ABC"[k], r.opts[k]], o.position + Vector2(5, 3), col, 8, false)
	Px.bar(self, Rect2(40, 192, 304, 4), 1.0 - q_t / per_q(), Px.C.cyan if q_t < per_q() * 0.7 else Px.C.red)


func _draw() -> void:
	draw_rect(PLAY, Color(Px.C.dark, 0.96))
	var term := Rect2(16, 30, 352, 96)
	Px.panel(self, term, Px.C.ink, Px.C.slate)
	draw_rect(Rect2(term.position + Vector2(2, 2), Vector2(term.size.x - 4, 10)), Px.C.slate)
	Px.text(self, "fresher@genesys: ~/club", term.position + Vector2(6, 3), Px.C.white, 8, false)
	for i in 3:
		draw_rect(Rect2(term.end.x - 12 - i * 8, term.position.y + 5, 4, 4), [Px.C.red, Px.C.gold, Px.C.lime][i])
	var lines: Array = history.slice(maxi(0, history.size() - 7))
	for i in lines.size():
		var s: String = lines[i]
		Px.text(self, s.substr(0, 56), term.position + Vector2(6, 16 + i * 10), Px.C.lime if s.begins_with("$") else Px.C.mist, 8, false)
	if ri < rounds.size():
		var r: Dictionary = rounds[ri]
		if answered < 0 and int(t * 2) % 2 == 0:
			draw_rect(Rect2(term.position + Vector2(6, 16 + lines.size() * 10), Vector2(5, 7)), Px.C.lime)
		Px.text(self, "TASK: " + r.prompt, Vector2(40, 134), Px.C.gold)
		draw_options(r, Px.C.white)
	draw_card()
