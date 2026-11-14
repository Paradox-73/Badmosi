# Badmosi

A top-down pixel adventure set at IIIT-B, made for the Synergy '26 Game Dev competition (theme: **Pixelated Game**) by Team Claude laggye.

A fresher, Pix, wants to start a Pixel Club. The only free room is Room 404, which is not on any floor plan. Circular No. 404 says a new club gets a room only after its founder beats every club at its own game. So Pix takes on all thirteen clubs, then the SAC, then the Admin itself.

Every club challenge is a minigame. At any moment you can hold **F** to say `F*** IT!` (censored by a pixel mosaic): the minigame shatters into pixels and turns into a beat 'em up fight with the whole club.

- Web build: _link added on submission day_
- Video: _link added on submission day_

## Where the code is

| Folder | What it holds |
|---|---|
| `scripts/autoload/` | `Px` (palette, sprites drawn from text, pixel font helpers), `Game` (run state, options, input map, saving), `Audio` (chiptune synth and beat clock), `Fx` (hitstop, shake, comic words, pixel bursts, telegraphs) |
| `scripts/fight/` | Pix, the five enemy archetypes, club heads with eight shared attack pieces, the Admin's phases, the fight manager and attack tokens |
| `scripts/minigames/` | The base minigame (key card, penalties, timer, cursor) and one script per club game |
| `scripts/club_room.gd` | One scene for every club: challenge, minigame, F-it switch, fight, results, membership card, 8-Bit headline |
| `scripts/world/` | The room loader (text files) and the campus hub |
| `scripts/ui/` | HUD, menus, pause, options, dialogue, name cards, result cards, credits |
| `scripts/story/` | Opening and ending |
| `scripts/data/clubs.gd` | Every club's data: names, looks, palette, attacks, lines, headlines |
| `levels/*.txt` | Club rooms, one character per tile (24 x 12) |
| `data/` | Quiz questions and DebSoc speech lines |
| `shaders/` | Mosaic transition, sprite flash and Downscale, club palette |
| `tools/` | Content checks, rule tests and the font builder |

## How to play

Walk around campus and into a building door to see its clubs. Pick a club, hear the challenge, and play its game. Win to get its membership card. Beat all thirteen clubs to open the SAC, and beat the SAC to reach the Admin.

College life is the rule set:
- **Attendance** is your health. Every minigame mistake and every hit costs some. At 0% you are **DETAINED**.
- A **Proxy** is an extra life: a friend marks you present.
- **Pixels (px)** are money. Spend them at the Bhaskara canteen, open till 2 AM.
- Each new club card is a **SEM UP**: more fight damage, smaller Attendance losses.
- Every 3 cards unlock a new fight special.

### Controls

| Action | Keys | Gamepad |
|---|---|---|
| Move | W A S D or arrow keys | Left stick or d-pad |
| Attack (3-hit combo), confirm | J, Z or Enter | X / Square |
| Dodge, back | K or X | A / Cross |
| Special | L or C | Y / Triangle |
| Switch special | I or V | Right bumper |
| Flip the table | Hold F for 1 second | Hold Back |
| Pause | Esc | Start |
| Fullscreen | F11 | |

Each minigame shows its own keys on a key card before it starts.

### The clubs

| Club | Game | Pixel twist |
|---|---|---|
| Impulse, the dance club | Dance-off: repeat COUNT EIGHT's arrow phrases on the beat | Arrows burst into pixels on a PERFECT |
| Symphony, the music club | Piano tiles: each correct press plays the next note of Ode to Joy | Tiles shatter on a wrong note |
| Quiz Society | Six questions, then a picture round | Pictures start as 4 x 4 blocks and sharpen |
| Pioneers, the maths club | Maths sprint, then make 404 from six numbers | Large pixel digits |
| 8-Bit, the student magazine | Proofread the cover | Find single wrong pixels |
| ECLIPSE, the astronomy club | Telescope hunt in a dark sky | Single-pixel stars |
| Food Committee | 2 AM rush: build canteen trays | Pixel patience bars |
| Chhayachitra, the photography club | Golden hour: shoot when the focus is sharp | Focus is a pulsing mosaic |
| Film Division | Boom operator | Pixel frame edge |
| Zense, the developers' club | Bug squash, but green crawlers are features | Pixel-font code |
| Vinci, the art club | Paint a pixel painting from memory | The whole game is pixel art |
| DebSoc, the debating society | Point of order: object only to fallacies | Pixel audience meter |
| Parvaaz, the theatre club | Stage fright: dodge the spotlights | Dithered pixel spotlights |
| The SAC | House rules that change every 10 seconds | Pixel rule banners |
| The Admin | Form 404: a quick round of each club's game, then a stamp | The Admin upscales itself into giant pixels |

**Club select** on the main menu opens any club, the SAC or the Admin straight away, with either the minigame or the fight first. The pause menu has assists (invincible, double damage, skip club) with no penalty.

## Running and building

The project uses **Godot 4.7.2** (standard build, not .NET) with the Compatibility renderer.

1. Install Godot 4.7.2 from https://godotengine.org/download/archive/4.7.2-stable/ and its export templates.
2. Open `project.godot` in Godot, then press F5 to play.

Command line:

```
godot --path .
godot --headless --path . --export-release "Web" build/web/index.html
godot --headless --path . --export-release "Windows Desktop" build/win/Badmosi.exe
```

The web build is exported without thread support, so it runs on any static host such as itch.io or GitHub Pages.

### Checks

```
godot --headless --path . --script res://tools/check_scripts.gd
godot --headless --path . --script res://tools/check_levels.gd
godot --headless --path . --script res://tools/check_content.gd
godot --headless --path . --script res://tools/run_tests.gd
godot --headless --path . --script res://tools/ui_smoke.gd
```

These check that every script compiles, that the room files are valid, that the quiz, debate lines and club data are complete, that the game rules hold, and that the hub boards, canteen and pause menu work.

Arguments after `--` open a screen directly, for testing and frame captures: `--screen=<name>`, `--club=<id>`, `--fight` and `--autoplay`.

```
godot --path . --write-movie out/frames.png --fixed-fps 30 --quit-after 200 -- --screen=club --club=impulse --autoplay
```

## Pixel rules

- The game renders at 384 x 216 and scales up by whole numbers only (stretch mode `viewport`, scale mode `integer`), so every game pixel is a sharp square block: 4 x 4 in the default window, 5 x 5 at 1080p.
- Nearest-neighbour filtering everywhere, and pixel snapping on.
- One pixel size for sprites, tiles, UI, text and particles. The font is a 5 x 7 bitmap font built by `tools/make_font.py`.

## Credits

See [CREDITS.md](CREDITS.md). Every sprite, tile, font glyph, sound and music loop in the game was made by the team. Ode to Joy (Beethoven) is in the public domain.

All characters are invented. The Admin is a faceless office, not a person. No real student, faculty or staff member appears in the game.

## License

Code: MIT, see [LICENSE](LICENSE).
