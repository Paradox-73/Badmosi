extends Minigame
## Algo Club: Sort It. Three arrays of pixel bars, 5, 7 and 8 long. Move the
## cursor between two neighbours and press J to swap them. Sort each array
## ascending; the fewest swaps possible is the number of inversions.

const BAR_W := 24
const GAP := 8
const FLOOR_Y := 176
const UNIT := 11

var sizes: Array[int] = [5, 7, 8]
var level := 0
var arr: Array[int] = []
var sel := 0
var swaps := 0
var min_swaps := 0
var total_swaps := 0
var total_min := 0
var bot_t := 0.0
var flash_t := 0.0


func info() -> Dictionary:
	return {"goal": "SORT 3 ARRAYS SMALLEST TO BIGGEST. EVERY SWAP COUNTS - USE AS FEW AS YOU CAN.",
		"keys": ["LEFT / RIGHT: PICK A PAIR", "J: SWAP THE PAIR"], "time": 75.0}


func _ready() -> void:
	super._ready()
	if short_round:
		sizes = [4]
	_new_array()


func goal_text() -> String:
	return "ARRAY %d/%d   SWAPS %d   BEST %d" % [mini(level + 1, sizes.size()), sizes.size(), swaps, min_swaps]


static func inversions(a: Array[int]) -> int:
	var n := 0
	for i in a.size():
		for j in range(i + 1, a.size()):
			if a[i] > a[j]:
				n += 1
	return n


func _new_array() -> void:
	var n: int = sizes[level]
	var vals: Array[int] = []
	for i in range(1, 10):
		vals.append(i)
	while true:
		vals.shuffle()
		arr = vals.slice(0, n)
		if inversions(arr) >= n - 1:
			break
	min_swaps = inversions(arr)
	swaps = 0
	sel = n / 2 - 1


func _x0() -> int:
	var n := arr.size()
	return Px.W / 2 - (n * BAR_W + (n - 1) * GAP) / 2


func _bar_rect(i: int) -> Rect2:
	var h := arr[i] * UNIT
	return Rect2(_x0() + i * (BAR_W + GAP), FLOOR_Y - h, BAR_W, h)


func tick(delta: float) -> void:
	flash_t -= delta
	if flash_t > 0.0:
		return
	if Game.autoplay:
		bot_t -= delta
		if bot_t <= 0.0:
			bot_t = 0.22 / speedup
			_bot_step()
		return
	if Input.is_action_just_pressed("left") and sel > 0:
		sel -= 1
		Audio.play("move", 0.0)
	if Input.is_action_just_pressed("right") and sel < arr.size() - 2:
		sel += 1
		Audio.play("move", 0.0)
	if Input.is_action_just_pressed("attack"):
		_swap()


## Bubble sort, one cursor step at a time: walk to the first out-of-order pair.
func _bot_step() -> void:
	var target := 0
	for i in arr.size() - 1:
		if arr[i] > arr[i + 1]:
			target = i
			break
	if target < sel:
		sel -= 1
	elif target > sel:
		sel += 1
	else:
		_swap()


func _swap() -> void:
	var worse := arr[sel] < arr[sel + 1]
	var tmp := arr[sel]
	arr[sel] = arr[sel + 1]
	arr[sel + 1] = tmp
	swaps += 1
	var mid := Vector2(_x0() + sel * (BAR_W + GAP) + BAR_W + GAP / 2.0, FLOOR_Y - 20)
	if worse:
		penalty(5.0, "WRONG WAY!", mid + Vector2(0, -90))
	else:
		Audio.play("tick", 0.0)
		Fx.burst(mid, [Px.C.cyan, Px.C.white], 8, null, 0, 50.0)
	if inversions(arr) == 0:
		total_swaps += swaps
		total_min += min_swaps
		for i in arr.size():
			var r := _bar_rect(i)
			Fx.burst(r.get_center(), [Px.C.lime, Px.C.green, Px.C.white], 10)
		Audio.play("right", 0.0)
		Fx.word("SORTED IN %d!" % swaps if swaps > min_swaps else "OPTIMAL!", Vector2(Px.W / 2.0, 44), Px.C.lime)
		level += 1
		if level >= sizes.size():
			finish(true, float(total_min) / maxi(1, total_swaps))
			return
		flash_t = 0.6
		_new_array.call_deferred()


func judge() -> Array:
	return [false, float(level) / sizes.size() * 0.5]


func _draw() -> void:
	draw_rect(PLAY, Px.C.ink)
	for y in range(40, FLOOR_Y, UNIT):
		draw_rect(Rect2(24, y, Px.W - 48, 1), Px.C.night)
	draw_rect(Rect2(16, FLOOR_Y, Px.W - 32, 2), Px.C.slate)
	for i in arr.size():
		var r := _bar_rect(i)
		var picked := i == sel or i == sel + 1
		var c: Color = Px.C.cyan.lerp(Px.C.violet, (arr[i] - 1) / 8.0)
		if flash_t > 0.0:
			c = Px.C.lime
		# Each bar is a stack of pixel blocks, one per unit of value.
		for k in arr[i]:
			var b := Rect2(r.position.x, FLOOR_Y - (k + 1) * UNIT, BAR_W, UNIT - 1)
			draw_rect(b, c.darkened(0.25))
			draw_rect(Rect2(b.position, Vector2(BAR_W - 2, UNIT - 3)), c)
		if picked and flash_t <= 0.0:
			draw_rect(Rect2(r.position - Vector2(2, 2), Vector2(BAR_W + 4, 2)), Px.C.gold)
		Px.text_c(self, str(arr[i]), r.get_center().x, FLOOR_Y + 4, Px.C.gold if picked else Px.C.white)
	if flash_t <= 0.0:
		var cx := _x0() + sel * (BAR_W + GAP) + BAR_W + GAP / 2
		Px.text_c(self, "<SWAP>", cx, FLOOR_Y + 16, Px.C.gold)
	Px.text(self, "ALGO CLUB", Vector2(8, 30), Px.C.cyan)
	var inv := "OUT OF ORDER PAIRS: %d" % inversions(arr)
	Px.text(self, inv, Vector2(Px.W - 8 - Px.text_w(inv), 30), Px.C.steel)
	draw_timer()
	draw_card()
