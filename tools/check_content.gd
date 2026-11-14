extends SceneTree
## Checks the question banks: every quiz question has four options and one
## valid answer, no question appears twice, every DebSoc line has a valid mark,
## and every club has its minigame, room and two attacks.
## godot --headless --path . --script res://tools/check_content.gd

const MARKS := ["FAIR", "AD HOMINEM", "STRAWMAN", "SLIPPERY SLOPE", "FALSE DILEMMA", "BANDWAGON",
	"APPEAL TO AUTHORITY", "CIRCULAR", "HASTY GENERALISATION", "RED HERRING", "TU QUOQUE",
	"APPEAL TO TRADITION", "FALSE CAUSE"]
const PIECES := ["tiles", "fan", "dash", "ring", "summon", "hazard", "freeze", "shield"]

var _done := false
var bad := 0


func fail(msg: String) -> void:
	print("FAIL ", msg)
	bad += 1


func _process(_d: float) -> bool:
	if _done:
		return true
	_done = true
	var QuizG = load("res://scripts/minigames/quiz.gd")
	var DebG = load("res://scripts/minigames/debate.gd")
	var bank: Array = QuizG.load_bank()
	var seen := {}
	for q in bank:
		if q.opts.size() != 4:
			fail("quiz '%s' has %d options" % [q.q, q.opts.size()])
		if q.ans < 0 or q.ans > 3:
			fail("quiz '%s' has no valid answer" % q.q)
		if seen.has(q.q):
			fail("quiz '%s' appears twice" % q.q)
		seen[q.q] = true
	if bank.size() < 10:
		fail("quiz bank has only %d questions" % bank.size())
	var lines: Array = DebG.load_lines()
	var fallacies := 0
	for l in lines:
		if not l.mark in MARKS:
			fail("debsoc line '%s' has unknown mark %s" % [l.text, l.mark])
		if l.mark != "FAIR":
			fallacies += 1
	if fallacies < 6:
		fail("debsoc has only %d fallacies" % fallacies)
	var ClubsS = load("res://scripts/data/clubs.gd")
	for id in ClubsS.DATA:
		var c: Dictionary = ClubsS.DATA[id]
		if not ResourceLoader.exists("res://scripts/minigames/%s.gd" % c.game):
			fail("%s: minigame %s missing" % [id, c.game])
		if not FileAccess.file_exists("res://levels/%s.txt" % id):
			fail("%s: room file missing" % id)
		if c.attacks.size() != 2:
			fail("%s: needs exactly 2 attacks" % id)
		for a in c.attacks:
			if not a in PIECES:
				fail("%s: unknown attack %s" % [id, a])
		if c.stats.size() != 3:
			fail("%s: needs 3 name-card stats" % id)
	print("checked %d questions, %d debate lines, %d clubs: %d problems" % [bank.size(), lines.size(), ClubsS.DATA.size(), bad])
	quit(1 if bad > 0 else 0)
	return true
