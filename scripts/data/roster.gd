class_name Roster
## The Badmosi gang: every playable character, their look, their theme song,
## and their perks. A perk is a fraction (0.15 = 15%) or, for hype, a count.
## Positive is always good for the player; negative is a nerf.
##
## Perk keys:
##   speed  - move speed            dmg    - fight damage
##   guard  - less Attendance lost  dodge  - shorter dodge cooldown
##   px     - more pixels earned    time   - longer minigame timers
##   window - wider timing windows  hype   - hype at the start of each fight
## quirk (optional): "dhairya", "phone", "cartwheel", "blackhole".

const ORDER := ["aarpeet", "ivan", "dhulli", "gupta", "betala", "kaushal", "modi",
	"sachan", "nikunj", "kanav", "jayant", "tyagi", "nirbhay", "gary",
	"mittal", "antala", "pratham", "suryans", "bhavya", "sodhi", "gathik"]

const DATA := {
	"aarpeet": {"name": "AARPEET", "tag": "ALWAYS IN A HURRY",
		"look": {"hair": "ink", "skin": "skin2", "cloth": "red", "shade": "maroon", "accent": "white", "pants": "navy"},
		"perks": {"speed": 0.15, "dodge": 0.3, "guard": -0.15},
		"theme": {"bpm": 138, "roots": [45, 41, 48, 43], "minor": [true, false, false, false], "lead": 2, "drums": "drive"}},
	"ivan": {"name": "IVAN", "tag": "HITS FIRST, ASKS LATER",
		"look": {"hair": "sand", "skin": "skin1", "cloth": "slate", "shade": "navy", "accent": "red", "pants": "ink"},
		"perks": {"dmg": 0.2, "guard": 0.1, "speed": -0.1},
		"theme": {"bpm": 126, "roots": [40, 43, 45, 38], "minor": [true, false, true, false], "lead": 2, "drums": "rock"}},
	"dhulli": {"name": "DHULLI", "tag": "FINDS PIXELS EVERYWHERE",
		"look": {"hair": "brown", "skin": "skin2", "cloth": "gold", "shade": "orange", "accent": "ink", "pants": "slate"},
		"perks": {"px": 0.3, "time": 0.2, "dmg": -0.1},
		"theme": {"bpm": 112, "roots": [43, 47, 48, 45], "minor": [false, true, false, true], "lead": 1, "drums": "soft"}},
	"gupta": {"name": "GUPTA", "tag": "NEVER MISSES A CLASS",
		"look": {"hair": "ink", "skin": "skin1", "cloth": "blue", "shade": "navy", "accent": "gold", "pants": "grey"},
		"perks": {"guard": 0.2, "px": 0.15, "window": -0.15},
		"theme": {"bpm": 104, "roots": [48, 45, 41, 43], "minor": [false, true, false, false], "lead": 1, "drums": "soft"}},
	"betala": {"name": "BETALA", "tag": "BORN ON THE BEAT",
		"look": {"hair": "ink", "skin": "skin3", "cloth": "violet", "shade": "plum", "accent": "lime", "pants": "ink"},
		"perks": {"window": 0.25, "hype": 3.0, "speed": -0.1},
		"theme": {"bpm": 120, "roots": [41, 43, 45, 45], "minor": [false, false, true, true], "lead": 2, "drums": "four"}},
	"kaushal": {"name": "KAUSHAL", "tag": "QUICK HANDS",
		"look": {"hair": "brown", "skin": "skin2", "cloth": "teal", "shade": "jade", "accent": "orange", "pants": "navy"},
		"perks": {"dmg": 0.15, "speed": 0.1, "time": -0.2},
		"theme": {"bpm": 132, "roots": [38, 41, 43, 36], "minor": [true, false, false, false], "lead": 2, "drums": "drive"}},
	"modi": {"name": "MODI", "tag": "KNOWS A GUY FOR EVERYTHING",
		"look": {"hair": "grey", "skin": "skin2", "cloth": "white", "shade": "mist", "accent": "orange", "pants": "brown"},
		"perks": {"px": 0.25, "guard": 0.1, "dodge": -0.3},
		"theme": {"bpm": 100, "roots": [43, 40, 36, 38], "minor": [false, true, false, false], "lead": 1, "drums": "rock"}},
	"sachan": {"name": "SACHAN", "tag": "ENDLESS PATIENCE. ALMOST.",
		"look": {"hair": "ink", "skin": "skin2", "cloth": "orange", "shade": "brown", "accent": "gold", "pants": "ink"},
		"perks": {"guard": 0.25, "dmg": 0.1, "speed": -0.05},
		"quirk": "dhairya",
		"theme": {"bpm": 116, "roots": [40, 40, 36, 38], "minor": [true, true, false, false], "lead": 3, "drums": "drive"}},
	"nikunj": {"name": "NIKUNJ", "tag": "TOPS EVERY QUIZ",
		"look": {"hair": "brown", "skin": "skin1", "cloth": "lime", "shade": "green", "accent": "white", "pants": "slate"},
		"perks": {"time": 0.25, "window": 0.15, "dmg": -0.15},
		"theme": {"bpm": 108, "roots": [48, 43, 45, 41], "minor": [false, false, true, false], "lead": 1, "drums": "soft"}},
	"kanav": {"name": "KANAV", "tag": "THE PLAN GUY",
		"look": {"hair": "brown", "skin": "skin2", "cloth": "cyan", "shade": "teal", "accent": "pink", "pants": "navy"},
		"perks": {"dmg": 0.1, "speed": 0.1, "hype": 2.0, "guard": -0.1},
		"theme": {"bpm": 128, "roots": [45, 41, 43, 40], "minor": [true, false, false, true], "lead": 2, "drums": "rock"}},
	"jayant": {"name": "JAYANT", "tag": "ZERO TO HYPE",
		"look": {"hair": "ink", "skin": "skin3", "cloth": "pink", "shade": "maroon", "accent": "cyan", "pants": "ink"},
		"perks": {"speed": 0.2, "hype": 2.0, "px": -0.2},
		"theme": {"bpm": 140, "roots": [41, 43, 40, 45], "minor": [false, false, true, true], "lead": 3, "drums": "four"}},
	"tyagi": {"name": "TYAGI", "tag": "A WALL WITH A HOODIE",
		"look": {"hair": "ink", "skin": "skin2", "cloth": "olive", "shade": "jade", "accent": "sand", "pants": "brown"},
		"perks": {"guard": 0.3, "hype": 1.0, "speed": -0.15},
		"theme": {"bpm": 96, "roots": [36, 36, 41, 43], "minor": [true, true, false, false], "lead": 1, "drums": "rock"}},
	"nirbhay": {"name": "NIRBHAY", "tag": "OPENS A BLACK HOLE",
		"look": {"hair": "ink", "skin": "skin2", "cloth": "night", "shade": "dark", "accent": "violet", "pants": "plum"},
		"perks": {"dmg": 0.1, "hype": 1.0, "time": -0.15},
		"quirk": "blackhole",
		"theme": {"bpm": 124, "roots": [38, 39, 38, 36], "minor": [true, false, true, true], "lead": 3, "drums": "drive"}},
	"gary": {"name": "GARY", "tag": "CAN'T BE TOUCHED",
		"look": {"hair": "gold", "skin": "skin1", "cloth": "steel", "shade": "slate", "accent": "red", "pants": "navy"},
		"perks": {"dodge": 0.4, "speed": 0.1, "guard": -0.2},
		"theme": {"bpm": 134, "roots": [43, 45, 41, 48], "minor": [false, true, false, false], "lead": 2, "drums": "drive"}},
	"mittal": {"name": "MITTAL", "tag": "COUNTS EVERY PIXEL",
		"look": {"hair": "ink", "skin": "skin1", "cloth": "sand", "shade": "tan", "accent": "navy", "pants": "slate"},
		"perks": {"px": 0.2, "window": 0.15, "dmg": -0.1},
		"theme": {"bpm": 110, "roots": [41, 45, 43, 48], "minor": [false, true, false, false], "lead": 1, "drums": "four"}},
	"antala": {"name": "ANTALA", "tag": "ONE BIG SWING",
		"look": {"hair": "ink", "skin": "skin2", "cloth": "maroon", "shade": "dark", "accent": "gold", "pants": "ink"},
		"perks": {"dmg": 0.25, "dodge": -0.3, "window": -0.1},
		"theme": {"bpm": 146, "roots": [40, 36, 38, 35], "minor": [true, false, false, false], "lead": 3, "drums": "drive"}},
	"pratham": {"name": "PRATHAM", "tag": "FIRST IN, LAST OUT",
		"look": {"hair": "brown", "skin": "skin3", "cloth": "green", "shade": "jade", "accent": "white", "pants": "navy"},
		"perks": {"time": 0.2, "guard": 0.15, "speed": -0.1},
		"theme": {"bpm": 106, "roots": [43, 48, 45, 41], "minor": [false, false, true, false], "lead": 1, "drums": "soft"}},
	"suryans": {"name": "SURYANS", "tag": "SUNNY, SHARP, ON TIME",
		"look": {"hair": "ink", "skin": "skin2", "cloth": "orange", "shade": "red", "accent": "gold", "pants": "brown"},
		"perks": {"window": 0.2, "dmg": 0.1, "px": -0.2},
		"theme": {"bpm": 122, "roots": [48, 47, 45, 43], "minor": [false, true, true, false], "lead": 2, "drums": "four"}},
	"bhavya": {"name": "BHAVYA", "tag": "ONE MORE SCROLL",
		"look": {"hair": "ink", "skin": "skin1", "cloth": "pink", "shade": "violet", "accent": "white", "pants": "navy"},
		"perks": {"speed": 0.15, "px": 0.2, "hype": 1.0},
		"quirk": "phone",
		"theme": {"bpm": 118, "roots": [41, 40, 38, 36], "minor": [false, true, true, false], "lead": 2, "drums": "four"}},
	"sodhi": {"name": "SODHI", "tag": "CARTWHEELS INTO EVERYTHING",
		"look": {"hair": "ink", "skin": "skin2", "cloth": "lime", "shade": "olive", "accent": "red", "pants": "ink", "hat": "cap"},
		"perks": {"speed": 0.1, "dodge": 0.2, "guard": -0.1},
		"quirk": "cartwheel",
		"theme": {"bpm": 136, "roots": [43, 41, 40, 38], "minor": [false, false, true, true], "lead": 3, "drums": "rock"}},
	"gathik": {"name": "GATHIK", "tag": "HYPE MAN",
		"look": {"hair": "brown", "skin": "skin2", "cloth": "gold", "shade": "brown", "accent": "violet", "pants": "ink", "hat": "visor"},
		"perks": {"hype": 3.0, "dmg": 0.1, "time": -0.15},
		"theme": {"bpm": 130, "roots": [45, 43, 41, 40], "minor": [true, false, false, true], "lead": 2, "drums": "drive"}},
}

const PERK_NAMES := {
	"speed": "MOVE SPEED", "dmg": "FIGHT DAMAGE", "guard": "ATTENDANCE LOSS",
	"dodge": "DODGE COOLDOWN", "px": "PIXELS EARNED", "time": "MINIGAME TIME",
	"window": "TIMING WINDOWS", "hype": "HYPE AT FIGHT START",
}

const QUIRKS := {
	"dhairya": ["DHAIRYA METER", "EVERY HIT DRAINS THE PATIENCE. AT ZERO: 6 S OF RAGE, DOUBLE DAMAGE."],
	"phone": ["PHONE BUZZ", "THE PHONE BUZZES NOW AND THEN. PRESS K IN TIME TO IGNORE IT."],
	"cartwheel": ["CARTWHEEL", "SPECIAL: CARTWHEELS THROUGH A WHOLE LINE OF ENEMIES."],
	"blackhole": ["BLACK HOLE", "SPECIAL: OPENS A BLACK HOLE THAT PULLS EVERYONE IN."],
}


static func get_char(id: String) -> Dictionary:
	return DATA.get(id, DATA["kanav"])


## Display lines for a character's perks: [[text, good], ...], buffs first.
static func perk_lines(id: String) -> Array:
	var good := []
	var bad := []
	var perks: Dictionary = get_char(id).perks
	for k in perks:
		var v: float = perks[k]
		var line := ""
		if k == "hype":
			line = "%+d %s" % [int(v), PERK_NAMES[k]]
		else:
			var shown := v
			if k in ["guard", "dodge"]:
				shown = -v    # less loss and a shorter cooldown are the buffs
			line = "%+d%% %s" % [roundi(shown * 100), PERK_NAMES[k]]
		(good if v > 0.0 else bad).append([line, v > 0.0])
	return good + bad


## The theme song for a character, in the same shape as Audio.SONGS entries.
static func theme(id: String) -> Dictionary:
	var t: Dictionary = get_char(id).theme.duplicate()
	t["seed"] = hash(id) % 100000
	return t
