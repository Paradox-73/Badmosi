extends Minigame
## E-Cell: Buy Low. A pixel price chart scrolls past. J buys one share at the
## current price, K sells one. Bank a profit before the closing bell. The price
## is a seeded random walk that switches between up and down trends.

const CHART := Rect2(8, 34, 276, 150)
const LO := 20.0
const HI := 200.0
const STEP := 0.08
const MAX_SHARES := 5

var rng := RandomNumberGenerator.new()
var hist: Array[float] = []
var price := 100.0
var drift := 0.0
var trend_t := 0.0
var step_t := 0.0
var shares := 0
var spent := 0.0     # cost of the shares held now
var bank := 0.0      # realised profit
var target := 300.0
var bot_t := 0.0


func info() -> Dictionary:
	return {"goal": "BANK +300 PX OF PROFIT BEFORE THE CLOSING BELL. BUY LOW, SELL HIGH.",
		"keys": ["J: BUY ONE SHARE   K: SELL ONE SHARE", "HOLD UP TO 5 SHARES"], "time": 75.0}


func _ready() -> void:
	super._ready()
	if short_round:
		target = 60.0
	rng.seed = randi()
	for i in int(CHART.size.x / 2):
		_walk()
		hist.append(price)


func goal_text() -> String:
	return "BANK %+d / %d   SHARES %d   BELL %d" % [int(bank), int(target), shares, ceili(time_left)]


func _walk() -> void:
	trend_t -= STEP
	if trend_t <= 0.0:
		trend_t = rng.randf_range(1.5, 4.5)
		drift = rng.randf_range(0.6, 1.8) * (1.0 if drift <= 0.0 else -1.0)
	price += drift + rng.randf_range(-2.5, 2.5)
	if price < LO or price > HI:
		drift = -drift
		price = clampf(price, LO, HI)


func _avg() -> float:
	return spent / shares if shares > 0 else 0.0


func tick(delta: float) -> void:
	step_t -= delta * speedup
	while step_t <= 0.0:
		step_t += STEP
		_walk()
		hist.append(price)
		hist.pop_front()
	var buy := Input.is_action_just_pressed("attack")
	var sell := Input.is_action_just_pressed("dodge")
	if Game.autoplay:
		bot_t -= delta
		buy = false
		sell = false
		if bot_t <= 0.0:
			bot_t = 0.2
			buy = drift > 0.0 and shares < MAX_SHARES and trend_t > 1.0
			sell = drift < 0.0 and shares > 0 and price > _avg() + 2.0
	if buy:
		_buy()
	elif sell:
		_sell()
	if bank >= target:
		Audio.play("sting", 0.0)
		finish(true, clampf(1.0 - mistakes * 0.12, 0.4, 1.0))


func _py(p: float) -> int:
	return int(CHART.end.y - 2 - (p - LO) / (HI - LO) * (CHART.size.y - 4))


func _now_pos() -> Vector2:
	return Vector2(CHART.end.x - 2, _py(price))


func _buy() -> void:
	if shares >= MAX_SHARES:
		Fx.word("BAG IS FULL", _now_pos() + Vector2(-40, -14), Px.C.gold)
		return
	shares += 1
	spent += price
	Audio.play("buy", 0.0)
	Fx.word("BUY %d" % int(price), _now_pos() + Vector2(-30, 8), Px.C.cyan)


func _sell() -> void:
	if shares == 0:
		Fx.word("NO SHARES", _now_pos() + Vector2(-40, -14), Px.C.steel)
		return
	var cost := _avg()
	shares -= 1
	spent -= cost
	var gain := price - cost
	bank += gain
	if gain < 0.0:
		penalty(5.0, "SOLD AT A LOSS %d" % int(gain), _now_pos() + Vector2(-50, -14))
	else:
		Audio.play("coin", 0.0)
		Fx.burst(_now_pos(), [Px.C.gold, Px.C.lime], int(clampf(gain, 4, 30)))
		Fx.word("+%d" % int(gain), _now_pos() + Vector2(-30, -14), Px.C.lime)


func time_up() -> void:
	Audio.play("whistle", 0.0)
	super.time_up()


func judge() -> Array:
	return [bank >= target, clampf(bank / target, 0.0, 1.0) * 0.5]


func _draw() -> void:
	draw_rect(PLAY, Px.C.ink)
	Px.panel(self, CHART.grow(2), Px.C.dark, Px.C.slate)
	for p in [50.0, 100.0, 150.0]:
		var y := _py(p)
		for x in range(int(CHART.position.x), int(CHART.end.x), 4):
			draw_rect(Rect2(x, y, 2, 1), Px.C.night)
	# Each price is one 2 px column; green when it rose, red when it fell.
	for i in range(1, hist.size()):
		var a := _py(hist[i - 1])
		var b := _py(hist[i])
		var c: Color = Px.C.lime if hist[i] >= hist[i - 1] else Px.C.red
		draw_rect(Rect2(CHART.position.x + i * 2, mini(a, b), 2, absi(a - b) + 1), c)
	if shares > 0:
		var ay := _py(_avg())
		for x in range(int(CHART.position.x), int(CHART.end.x), 6):
			draw_rect(Rect2(x, ay, 3, 1), Px.C.cyan)
	var now := _now_pos()
	draw_rect(Rect2(now - Vector2(1, 1), Vector2(3, 3)), Px.C.white)
	# Side panel.
	var px := 294
	Px.text(self, "E-CELL", Vector2(px, 34), Px.C.cyan)
	Px.text(self, "PRICE", Vector2(px, 50), Px.C.steel)
	Px.text(self, str(int(price)), Vector2(px, 60), Px.C.white, 16)
	Px.text(self, "SHARES", Vector2(px, 82), Px.C.steel)
	for i in MAX_SHARES:
		draw_rect(Rect2(px + i * 9, 93, 7, 7), Px.C.gold if i < shares else Px.C.night)
	Px.text(self, "AVG %d" % int(_avg()), Vector2(px, 104), Px.C.cyan)
	Px.text(self, "BANK", Vector2(px, 120), Px.C.steel)
	Px.text(self, "%+d" % int(bank), Vector2(px, 130), Px.C.lime if bank >= 0.0 else Px.C.red)
	Px.bar(self, Rect2(px, 142, 82, 5), bank / target, Px.C.lime)
	Px.text(self, "GOAL %d" % int(target), Vector2(px, 150), Px.C.steel)
	Px.text(self, "J BUY  K SELL", Vector2(8, 190), Px.C.slate)
	draw_timer()
	draw_card()
