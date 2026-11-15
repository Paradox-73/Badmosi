extends Minigame
## ACM SIGCHI: USABILITY TEST. A fake app asks for one action. Its buttons
## are full of dark patterns: a giant fake, a typo twin, swapped colours, a tiny
## real button. Move the cursor and press J on the button that does the task.

# [task, real label, decoy labels...]
const TASKS := [
	["CLICK SUBMIT", "SUBMIT", "SUMBIT", "SUBMIT (AD)", "SUBMIT LATER"],
	["CANCEL THE PLAN", "CANCEL PLAN", "KEEP PLAN", "CANCEL? NO", "UPGRADE PLAN"],
	["DECLINE COOKIES", "DECLINE", "ACCEPT ALL", "ACCEPT MOST", "DECIINE"],
	["UNSUBSCRIBE", "UNSUBSCRIBE", "STAY SUBSCRIBED", "SUBSCRIBE+", "UNSUBSCRIBE?NO"],
	["SKIP THE AD", "SKIP", "SKIP? INSTALL", "WATCH 30S", "SK1P"],
	["SAVE YOUR WORK", "SAVE", "DELETE", "SAVE (PRO)", "DONT SAVE"],
	["BUY ONE TICKET", "BUY 1", "BUY 10 BEST!", "BUY 1 + INSURE", "BUY 2"],
	["LOG OUT", "LOG OUT", "LOG OUT LATER", "STAY IN", "L0G OUT"],
	["CLOSE THE POPUP", "CLOSE", "CL0SE", "OPEN DEALS", "CLOSE & SHARE"],
]
const AREA := Rect2(32, 58, 320, 120)

var need := 7
var right := 0
var order := []
var ti := 0
var buttons := []   # {rect, label, real, fill}
var auto_dwell := 0.0


func info() -> Dictionary:
	return {"goal": "DO WHAT THE APP ASKS. FIND THE REAL BUTTON, NOT THE TRAP. %d TASKS." % (2 if short_round else 7),
		"keys": ["ARROWS: MOVE CURSOR", "J: CLICK"], "time": 70.0}


func _ready() -> void:
	super._ready()
	cursor_speed = 150.0 * speedup
	if short_round:
		need = 2
	for i in TASKS.size():
		order.append(i)
	order.shuffle()
	_layout()


func goal_text() -> String:
	return "TASKS DONE %d/%d   TRAPS HIT %d" % [right, need, mistakes]


## Deals the buttons of the current task into a 2 x 3 grid of slots.
func _layout() -> void:
	buttons.clear()
	var task: Array = TASKS[order[ti % order.size()]]
	var slots := [0, 1, 2, 3, 4, 5]
	slots.shuffle()
	var swap := randf() < 0.5          # dark pattern: real one red, a decoy green
	for i in range(1, task.size()):
		var real := i == 1
		var label: String = task[i]
		var s: int = slots[i - 1]
		var cell := Rect2(AREA.position.x + (s % 2) * 162, AREA.position.y + (s / 2) * 40, 158, 36)
		var w := Px.text_w(label) + 12
		var h := 16
		if real and randf() < 0.6:
			w = Px.text_w(label) + 4      # tiny real button
			h = 11
		elif i == 2:
			w = 150                        # giant fake
			h = 30
		var r := Rect2((cell.position + (cell.size - Vector2(w, h)) / 2.0).floor(), Vector2(w, h))
		var fill: Color = Px.C.green if i == (3 if swap else 2) else Px.C.slate
		if real:
			fill = Px.C.red if swap else Px.C.slate
		buttons.append({"rect": r, "label": label, "real": real, "fill": fill})


func tick(delta: float) -> void:
	var click := cursor_step(delta, AREA.grow(8))
	if Game.autoplay:
		click = _auto(delta)
	if not click:
		return
	for b in buttons:
		var r: Rect2 = b.rect
		if r.grow(1).has_point(cursor):
			if b.real:
				right += 1
				Audio.play("right", 0.0)
				Fx.word("USABLE!", r.get_center() - Vector2(0, 12), Px.C.lime)
				Fx.burst(r.get_center(), [Px.C.lime, Px.C.white], 20)
				ti += 1
				if right >= need:
					finish(true, float(right) / (right + mistakes))
					return
				_layout()
			else:
				Fx.burst(r.get_center(), [b.fill, Px.C.white, Px.C.dark], 30)
				penalty(6.0, "DARK PATTERN!", r.get_center() - Vector2(0, 12))
				buttons.erase(b)
			return


## Autoplay glides to the real button and clicks after a short look.
func _auto(delta: float) -> bool:
	for b in buttons:
		if b.real:
			var r: Rect2 = b.rect
			var goal := r.get_center().floor()
			cursor = cursor.move_toward(goal, cursor_speed * delta)
			auto_dwell = auto_dwell + delta if cursor.distance_to(goal) < 1.0 else 0.0
			if auto_dwell > 0.3:
				auto_dwell = 0.0
				return true
	return false


func judge() -> Array:
	return [right >= need, float(right) / float(need)]


func _draw() -> void:
	draw_rect(PLAY, Px.C.navy)
	# A browser window.
	Px.panel(self, Rect2(16, 28, 352, 160), Px.C.mist, Px.C.steel)
	draw_rect(Rect2(18, 30, 348, 12), Px.C.steel)
	for i in 3:
		draw_rect(Rect2(22 + i * 8, 33, 5, 5), [Px.C.red, Px.C.gold, Px.C.lime][i])
	Px.text(self, "TOTALLY-FAIR.APP", Vector2(56, 32), Px.C.ink, 8, false)
	if running:
		var task: Array = TASKS[order[ti % order.size()]]
		Px.text_c(self, "TASK: " + str(task[0]), Px.W / 2.0, 46, Px.C.ink, 8, false)
		for b in buttons:
			var r: Rect2 = b.rect
			var hover := r.grow(1).has_point(cursor)
			Px.panel(self, r, b.fill, Px.C.gold if hover else Px.C.ink)
			if r.size.y >= 30:   # the giant one pulses for attention
				draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 1)), Px.C.lime if int(t * 4) % 2 == 0 else Px.C.white)
			var ty := r.position.y + floorf((r.size.y - 8) / 2.0)
			Px.text_c(self, b.label, roundf(r.get_center().x), ty, Px.C.white)
		draw_cursor(Px.C.white)
	Px.text(self, "DONE %d/%d" % [right, need], Vector2(20, 176), Px.C.ink, 8, false)
	draw_timer()
	draw_card()
