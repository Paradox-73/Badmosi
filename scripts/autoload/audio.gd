extends Node
## Chiptune synth. Every sound effect and music loop is generated from
## square, triangle, saw and noise waves when first needed, then cached.
## Also runs the beat clock that the rhythm games read.

const RATE := 16000
const SFX_VOICES := 14

var _sfx := {}
var _notes := {}
var _songs := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var music: AudioStreamPlayer
var music_name := ""
var music_bpm := 120.0
var _last_pos := 0.0
var _loops := 0
var _loop_len := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	music = AudioStreamPlayer.new()
	add_child(music)
	apply_volumes()


func apply_volumes() -> void:
	var g = get_node_or_null("/root/Game")
	var mv := 0.7
	var sv := 0.8
	if g:
		mv = float(g.opts.music)
		sv = float(g.opts.sfx)
	if music:
		music.volume_db = linear_to_db(maxf(mv, 0.0001)) - 6.0
	for p in _players:
		p.volume_db = linear_to_db(maxf(sv, 0.0001)) - 4.0


# ------------------------------------------------------------------ synthesis

static func _freq(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## Renders one tone into a float array.
## wave: square, pulse, tri, saw, noise, sine. slide: semitones over the tone.
func _tone(freq: float, dur: float, wave := "square", vol := 0.5, attack := 0.005, decay := 1.0, slide := 0.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var noise_v := 0.0
	var noise_t := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / dur
		var f := freq * pow(2.0, slide * k / 12.0)
		phase = fmod(phase + f / RATE, 1.0)
		var s := 0.0
		match wave:
			"square":
				s = 1.0 if phase < 0.5 else -1.0
			"pulse":
				s = 1.0 if phase < 0.25 else -1.0
			"tri":
				s = 4.0 * absf(phase - 0.5) - 1.0
			"saw":
				s = 2.0 * phase - 1.0
			"sine":
				s = sin(phase * TAU)
			"noise":
				noise_t += f / RATE
				if noise_t >= 1.0:
					noise_t -= 1.0
					noise_v = _rng.randf_range(-1.0, 1.0)
				s = noise_v
		var env := minf(1.0, t / attack) if attack > 0.0 else 1.0
		env *= pow(1.0 - k, decay) if decay > 0.0 else 1.0
		out[i] = s * vol * env
	return out


func _to_wav(buf: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = buf.size()
	return w


func _cat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out


func _mix_into(dst: PackedFloat32Array, src: PackedFloat32Array, at: int) -> void:
	var n := mini(src.size(), dst.size() - at)
	for i in n:
		dst[at + i] += src[i]


func _make_sfx(name: String) -> AudioStreamWAV:
	_rng.seed = hash(name)
	var b := PackedFloat32Array()
	match name:
		"swing": b = _tone(900, 0.07, "noise", 0.25, 0.002, 2.0, -12)
		"swing2": b = _tone(1100, 0.07, "noise", 0.25, 0.002, 2.0, -12)
		"swing3": b = _tone(700, 0.12, "noise", 0.3, 0.002, 1.5, -18)
		"hit": b = _cat([_tone(180, 0.03, "square", 0.5, 0.001, 0.5, -6), _tone(1600, 0.06, "noise", 0.4, 0.001, 2.0, -24)])
		"hit2": b = _cat([_tone(220, 0.03, "square", 0.5, 0.001, 0.5, -6), _tone(1300, 0.07, "noise", 0.4, 0.001, 2.0, -24)])
		"finisher": b = _cat([_tone(110, 0.05, "square", 0.6, 0.001, 0.3, -12), _tone(900, 0.18, "noise", 0.5, 0.001, 1.5, -24)])
		"hurt": b = _tone(300, 0.18, "square", 0.45, 0.001, 1.0, -14)
		"enemy_hurt": b = _tone(500, 0.08, "pulse", 0.35, 0.001, 1.0, -10)
		"burst": b = _tone(2400, 0.3, "noise", 0.35, 0.001, 1.2, -30)
		"dodge": b = _tone(400, 0.1, "tri", 0.4, 0.002, 1.0, 12)
		"coin": b = _cat([_tone(1319, 0.04, "square", 0.25), _tone(1760, 0.09, "square", 0.25)])
		"select": b = _cat([_tone(880, 0.04, "pulse", 0.3), _tone(1320, 0.07, "pulse", 0.3)])
		"move": b = _tone(660, 0.035, "pulse", 0.25)
		"back": b = _tone(440, 0.07, "pulse", 0.25, 0.002, 1.0, -5)
		"buy": b = _cat([_tone(784, 0.05, "square", 0.3), _tone(1047, 0.05, "square", 0.3), _tone(1568, 0.1, "square", 0.3)])
		"right": b = _cat([_tone(1047, 0.07, "square", 0.3), _tone(1568, 0.14, "square", 0.3)])
		"wrong": b = _cat([_tone(220, 0.1, "saw", 0.4, 0.002, 0.2), _tone(165, 0.2, "saw", 0.4, 0.002, 1.0)])
		"miss": b = _tone(200, 0.12, "saw", 0.3, 0.002, 1.0, -7)
		"perfect": b = _tone(1760, 0.08, "pulse", 0.25, 0.001, 1.5, 7)
		"good": b = _tone(1320, 0.07, "pulse", 0.22, 0.001, 1.5)
		"stamp": b = _cat([_tone(90, 0.06, "square", 0.7, 0.001, 0.4, -12), _tone(600, 0.12, "noise", 0.4, 0.001, 2.0)])
		"bleep": b = _tone(1000, 0.35, "sine", 0.45, 0.005, 0.05)
		"crash": b = _cat([_tone(120, 0.08, "square", 0.6, 0.001, 0.4, -10), _tone(3000, 0.6, "noise", 0.5, 0.001, 1.5, -20)])
		"door": b = _cat([_tone(200, 0.05, "tri", 0.5), _tone(150, 0.08, "tri", 0.5)])
		"tele": b = _tone(1200, 0.06, "pulse", 0.2)
		"sting": b = _cat([_tone(392, 0.08, "square", 0.3), _tone(523, 0.08, "square", 0.3), _tone(784, 0.3, "square", 0.3, 0.002, 1.0)])
		"semup": b = _cat([_tone(523, 0.08, "square", 0.3), _tone(659, 0.08, "square", 0.3), _tone(784, 0.08, "square", 0.3), _tone(1047, 0.35, "square", 0.3)])
		"detained": b = _cat([_tone(392, 0.2, "square", 0.3), _tone(370, 0.2, "square", 0.3), _tone(349, 0.2, "square", 0.3), _tone(330, 0.6, "square", 0.3)])
		"proxy": b = _cat([_tone(523, 0.06, "tri", 0.4), _tone(784, 0.06, "tri", 0.4), _tone(1047, 0.2, "tri", 0.4)])
		"squash": b = _cat([_tone(150, 0.04, "square", 0.5, 0.001, 0.5, -12), _tone(800, 0.08, "noise", 0.35)])
		"shutter": b = _cat([_tone(4000, 0.03, "noise", 0.4), _tone(2000, 0.05, "noise", 0.35)])
		"card": b = _cat([_tone(1047, 0.06, "tri", 0.4), _tone(1319, 0.06, "tri", 0.4), _tone(1568, 0.06, "tri", 0.4), _tone(2093, 0.25, "tri", 0.4)])
		"throw": b = _tone(600, 0.08, "noise", 0.2, 0.002, 1.0, 12)
		"zap": b = _tone(1500, 0.2, "saw", 0.3, 0.001, 1.0, -24)
		"whistle": b = _tone(2200, 0.4, "sine", 0.4, 0.01, 0.2, 2)
		"tick": b = _tone(2000, 0.02, "pulse", 0.2)
		"special": b = _tone(200, 0.4, "saw", 0.4, 0.002, 1.0, 24)
		"shatter": b = _tone(5000, 0.8, "noise", 0.45, 0.001, 1.0, -36)
		"objection": b = _cat([_tone(330, 0.1, "square", 0.45), _tone(440, 0.25, "square", 0.45)])
		"type": b = _tone(1800, 0.015, "noise", 0.2)
		_: b = _tone(440, 0.1)
	return _to_wav(b)


func play(name: String, pitch_var := 0.05, vol_db := 0.0) -> void:
	if not _sfx.has(name):
		_sfx[name] = _make_sfx(name)
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sfx[name]
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	var sv := 0.8
	var g = get_node_or_null("/root/Game")
	if g:
		sv = float(g.opts.sfx)
	p.volume_db = linear_to_db(maxf(sv, 0.0001)) - 4.0 + vol_db
	p.play()


var _coin_chain := 0
var _coin_last := 0.0


## The pixel pickup sound. Its pitch rises along a chain of quick pickups.
func coin() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_coin_chain = _coin_chain + 1 if now - _coin_last < 0.6 else 0
	_coin_last = now
	play("coin", 0.0)
	_players[(_next - 1 + _players.size()) % _players.size()].pitch_scale = minf(1.0 + 0.06 * _coin_chain, 1.8)


## Plays a melodic note (a MIDI number), used by the piano tiles.
func note(midi: int, dur := 0.35, wave := "tri") -> void:
	var key := "%d:%s:%f" % [midi, wave, dur]
	if not _notes.has(key):
		var a := _tone(_freq(midi), dur, wave, 0.45, 0.003, 1.2)
		var b := _tone(_freq(midi + 12), dur, "pulse", 0.08, 0.003, 2.0)
		for i in a.size():
			a[i] += b[i]
		_notes[key] = _to_wav(a)
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _notes[key]
	p.pitch_scale = 1.0
	p.play()


# ------------------------------------------------------------------ music

## Songs: bpm, chord roots per bar (MIDI), chord type per bar, a style.
const SONGS := {
	"title": {"bpm": 124, "roots": [48, 45, 41, 43], "minor": [false, true, false, false], "lead": 2, "drums": "rock", "seed": 11},
	"hub": {"bpm": 104, "roots": [43, 40, 36, 38], "minor": [false, true, false, false], "lead": 1, "drums": "soft", "seed": 7},
	"fight": {"bpm": 144, "roots": [45, 41, 43, 40], "minor": [true, false, false, true], "lead": 2, "drums": "drive", "seed": 3},
	"boss": {"bpm": 152, "roots": [40, 40, 36, 38], "minor": [true, true, false, false], "lead": 3, "drums": "drive", "seed": 21},
	"dance": {"bpm": 120, "roots": [41, 43, 45, 45], "minor": [false, false, true, true], "lead": 1, "drums": "four", "seed": 5},
	"admin": {"bpm": 132, "roots": [38, 39, 38, 36], "minor": [true, false, true, true], "lead": 3, "drums": "drive", "seed": 404},
	"minigame": {"bpm": 116, "roots": [48, 43, 45, 41], "minor": [false, false, true, false], "lead": 1, "drums": "soft", "seed": 13},
	"ending": {"bpm": 96, "roots": [41, 43, 48, 45], "minor": [false, false, false, true], "lead": 1, "drums": "soft", "seed": 17},
}


func _render_song(name: String) -> AudioStreamWAV:
	var s: Dictionary = SONGS[name]
	_rng.seed = s.seed
	var beat := 60.0 / float(s.bpm)
	var sixteenth := beat / 4.0
	var bars := 8
	var total := int(beat * 4 * bars * RATE)
	var buf := PackedFloat32Array()
	buf.resize(total)
	var cache := {}
	var roots: Array = s.roots
	var minors: Array = s.minor
	var melody_note := 72
	for bar in bars:
		var root: int = roots[bar % roots.size()]
		var minor: bool = minors[bar % minors.size()]
		var chord := [0, 3 if minor else 4, 7, 12]
		var bar_t := bar * beat * 4.0
		# Bass: root and fifth on eighths.
		for e in 8:
			var m: int = root + (7 if e % 4 == 2 else 0) - 12 + 12
			var k := "b%d" % m
			if not cache.has(k):
				cache[k] = _tone(_freq(m), sixteenth * 1.8, "tri", 0.32, 0.003, 0.6)
			_mix_into(buf, cache[k], int((bar_t + e * beat / 2.0) * RATE))
		# Arpeggio on sixteenths.
		for q in 16:
			var m2: int = root + 24 + chord[q % 4]
			var k2 := "a%d" % m2
			if not cache.has(k2):
				cache[k2] = _tone(_freq(m2), sixteenth * 0.9, "pulse", 0.07, 0.002, 1.5)
			_mix_into(buf, cache[k2], int((bar_t + q * sixteenth) * RATE))
		# Lead: chord tones on strong beats, steps between.
		var lead_level: int = s.lead
		var step_len := 2 if lead_level >= 2 else 4
		var q2 := 0
		while q2 < 16:
			var target: int = root + 36 + chord[_rng.randi() % 3]
			if q2 % 8 == 0:
				melody_note = target
			else:
				melody_note += [-2, -1, 1, 2, 0][_rng.randi() % 5]
				melody_note = clampi(melody_note, root + 31, root + 46)
			var dur := step_len * sixteenth
			if _rng.randf() < 0.25 and q2 % 4 == 0:
				dur *= 2.0
			var rest := _rng.randf() < 0.15
			if not rest:
				var k3 := "l%d:%f" % [melody_note, dur]
				if not cache.has(k3):
					cache[k3] = _tone(_freq(melody_note), dur * 0.95, "square", 0.11, 0.004, 0.7)
				_mix_into(buf, cache[k3], int((bar_t + q2 * sixteenth) * RATE))
			q2 += int(round(dur / sixteenth))
		# Drums.
		if not cache.has("kick"):
			cache["kick"] = _tone(150, 0.12, "sine", 0.6, 0.001, 1.5, -24)
			cache["snare"] = _tone(3000, 0.12, "noise", 0.28, 0.001, 1.8)
			cache["hat"] = _tone(8000, 0.03, "noise", 0.1, 0.001, 2.0)
		for q3 in 16:
			var at := int((bar_t + q3 * sixteenth) * RATE)
			match s.drums:
				"four":
					if q3 % 4 == 0: _mix_into(buf, cache["kick"], at)
					if q3 % 8 == 4: _mix_into(buf, cache["snare"], at)
					if q3 % 2 == 1: _mix_into(buf, cache["hat"], at)
				"rock":
					if q3 == 0 or q3 == 6 or q3 == 10: _mix_into(buf, cache["kick"], at)
					if q3 % 8 == 4: _mix_into(buf, cache["snare"], at)
					if q3 % 2 == 0: _mix_into(buf, cache["hat"], at)
				"drive":
					if q3 % 4 == 0 or q3 == 14: _mix_into(buf, cache["kick"], at)
					if q3 % 8 == 4: _mix_into(buf, cache["snare"], at)
					_mix_into(buf, cache["hat"], at)
				"soft":
					if q3 == 0 or q3 == 8: _mix_into(buf, cache["kick"], at)
					if q3 == 12: _mix_into(buf, cache["snare"], at)
					if q3 % 4 == 2: _mix_into(buf, cache["hat"], at)
	return _to_wav(buf, true)


func play_music(name: String) -> void:
	if name == music_name and music.playing:
		return
	if not SONGS.has(name):
		stop_music()
		return
	if not _songs.has(name):
		_songs[name] = _render_song(name)
	music_name = name
	music_bpm = float(SONGS[name].bpm)
	music.stream = _songs[name]
	_loop_len = 60.0 / music_bpm * 4.0 * 8.0
	_loops = 0
	_last_pos = 0.0
	music.pitch_scale = 1.0
	music.play()


func stop_music() -> void:
	music.stop()
	music_name = ""


## Renders the remaining music loops one per frame, so later screen changes don't stall.
var _prewarm: Array = []


func prewarm() -> void:
	for s in SONGS:
		if not _songs.has(s) and not _prewarm.has(s):
			_prewarm.append(s)


func _process(_d: float) -> void:
	if not _prewarm.is_empty():
		var s: String = _prewarm.pop_front()
		if not _songs.has(s):
			_songs[s] = _render_song(s)
	if music.playing:
		var p := music.get_playback_position()
		if p + 0.5 < _last_pos:
			_loops += 1
		_last_pos = p


## Song time in seconds, read from the audio clock (Godot's audio sync method),
## counting loops, minus output latency and the player's rhythm offset.
func song_time() -> float:
	if not music.playing:
		return 0.0
	var t := music.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	var g = get_node_or_null("/root/Game")
	if g:
		t -= float(g.opts.rhythm_offset) / 1000.0
	return (_loops * _loop_len + t) / music.pitch_scale * music.pitch_scale


func beat_len() -> float:
	return 60.0 / music_bpm
