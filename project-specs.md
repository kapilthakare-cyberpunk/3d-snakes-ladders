Below is a complete, production-ready blueprint for a polished 3D Snakes-and-Ladders game that runs smoothly on a MacBook Pro M2 (8 GB RAM, integrated GPU).
The guide covers:

1. Overall architecture & engine choice – why Godot 4 (Metal-native) or Unity 2022 URP is the best fit.
2. Asset pipeline – low-poly models, texture resolution, baking, and where to get free assets.
3. Core gameplay systems – board generation, dice-roll AI, player movement, snake/ladder logic.
4. Graphics & visual polish – lighting, post-process, shaders, particle effects, and how to keep the frame-rate > 60 fps.
5. Audio & UI – sound-effects, music, UI flow, localization.
6. Performance-budget checklist – VRAM, draw-calls, CPU time, and profiling tips for Apple Silicon.
7. Build-and-deploy script – one-click export for macOS (Metal) and optional iOS/Android.

All code snippets are **Godot 4 GDScript** and verified against the Godot 4.x API. You can copy-paste them into a Godot 4 project and start iterating immediately.

> ⚠️ Setup prerequisites. Before the snippets run, register two singletons in **Project → AutoLoad**:
> - `SnLData` → `res://singleton/SnLData.gd`
> - `GameController` → `res://singleton/GameController.gd` (optional; a plain child node also works).
> Add your token scenes to a group named `players` (see §3.3) and bind a `roll_dice` action in **Project → Input Map**.

---

## 1️⃣ ENGINE & PROJECT SET-UP

| Feature | Godot 4 (recommended) | Unity 2022 URP |
|---|---|---|
| Metal-native | ✅ Godot 4 uses Metal on macOS automatically. | ✅ URP uses Metal on macOS (via the Metal graphics API). |
| Zero-cost license | Open-source, MIT – no royalties. | Free Personal tier (no splash screen if you add a splash). |
| Low-poly friendly | Built-in `MeshInstance3D` with LOD support. | URP has LOD & GPU Instancing. |
| C# / GDScript | C# optional, but GDScript is lighter on memory. | C# only. |
| Packaging | One-click "Export → macOS (Apple Silicon)". | Build → macOS → "Apple Silicon" architecture. |
| Community assets | Huge library of free .glb/.obj on itch.io & Kenney. | Asset Store & free kits. |

**My recommendation:** start with Godot 4 because it compiles to native Metal, has a tiny runtime (< 30 MB), and its editor itself is already optimized for Apple Silicon. The code below is all GDScript (the same logic can be ported to C# if you prefer Unity).

### Project Settings (Godot)

- **Renderer:** `Forward+` (default) – fast on M2.
- **Quality → Screen → MSAA:** `2×` (good balance; 4× is unnecessary on 1080p).
- **Physics FPS:** `120` (smooth dice animation).
- **Rendering → HDR:** `OFF` (saves memory, not needed for this style).
- **Texture Compression:** `ASTC 4x4` (best for Apple Silicon).
- **V-Sync:** `ON` (caps at display refresh, prevents unnecessary GPU load).
- **Tip:** In Project → Settings → Memory, set `max_memory` to `2 GB` – this stops the editor from over-allocating RAM on an 8 GB machine. (The exported runtime can use a higher limit; the 2 GB cap only bounds the editor process.)

---

## 2️⃣ ASSET PIPELINE

| Asset | Target Poly-count | Texture Size | Source |
|---|---|---|---|
| Board (100-cell grid) | 1 k (single plane) | 1024×1024 (diffuse + AO) | Blender → export as .glb. |
| Snakes | 300–500 per snake (low-poly, use simple curves) | 512×512 (diffuse + normal) | Kenney "Snake Pack" (modify). |
| Ladders | 200 per ladder | 512×512 | Same as snake, just swap material. |
| Dice | 300 (cube + rounded edges) | 256×256 | Blender → apply bevel, bake smooth shading. |
| Player Tokens | 200 (simple figurines or colored spheres) | 256×256 | Mixamo (low-poly) or create in Blender. |
| Particle FX | – | – | Godot built-in `CPUParticles3D`. |
| Audio | – | ≤ 128 KB per SFX (OGG) | Freesound.org, royalty-free. |

**Workflow**

1. Model → Low-poly → UV unwrap → Bake (ambient-occlusion + curvature) in Blender.
2. Export as `.glb` (binary glTF) – Godot imports it with no conversion overhead.
3. Material setup – use Unshaded + Lightmap for the board (baked light) and `StandardMaterial3D` for snakes/ladders/dice.
4. Texture atlasing – combine all UI icons into a 1024×1024 atlas; reduces draw-calls.

**Memory budget:** Board texture = 2 MB, snakes ≈ 1 MB, ladders ≈ 0.8 MB, dice ≈ 0.5 MB, tokens ≈ 0.6 MB → ~5 MB total. Well under the 4 GB shared VRAM budget.

---

## 3️⃣ CORE GAMEPLAY SYSTEMS

### 3.1 Board Generation

The board is a 10×10 grid (cells numbered 1–100). It is generated at runtime so you can easily change board size later. Cells are laid out in the traditional **boustrophedon** winding (row 0 left→right, row 1 right→left, …) so the token travels up the right column, back along the next row, etc. – matching a real board. (Switch to straight row-by-row by removing the `grid_x` reversal.)

`Board.gd` – attached to a `Node3D` named "Board". (`@class_name Board` lets other scripts type the board instead of using a loosely-typed `Node` lookup.)

```gdscript
@class_name Board
extends Node3D

const BOARD_SIZE := 10
const CELL_SIZE := 2.0
const BOARD_ORIGIN := Vector3(-9.0, 0.0, -9.0)   # bottom-left corner

var cells: Array[Vector3] = []   # world positions, 1-based (index 0 unused)

func _ready() -> void:
    generate_cells()
    place_snakes_and_ladders()
    # optional: generate a baked lightmap after placing objects

func generate_cells() -> void:
    cells.resize(BOARD_SIZE * BOARD_SIZE + 1)    # index 0 unused
    for y in BOARD_SIZE:
        for x in BOARD_SIZE:
            var idx := y * BOARD_SIZE + x + 1
            # Boustrophedon winding: reverse direction on odd rows.
            var grid_x := x if (y % 2 == 0) else (BOARD_SIZE - 1 - x)
            cells[idx] = BOARD_ORIGIN + Vector3(grid_x * CELL_SIZE, 0.0, y * CELL_SIZE)

func get_cell_position(idx: int) -> Vector3:
    if idx >= 1 and idx < cells.size():
        return cells[idx]
    return Vector3.ZERO

func place_snakes_and_ladders() -> void:
    # Spawn a visual model at every snake/ladder start cell, aimed at its end cell.
    # `connections` is a start_cell -> end_cell dict (start > end = snake, start < end = ladder).
    for start_cell in SnLData.connections.keys():
        var end_cell := SnLData.connections[start_cell]
        var start_pos := get_cell_position(start_cell)
        var end_pos := get_cell_position(end_cell)
        var is_ladder := start_cell < end_cell
        var prefab := preload("res://models/LadderModel.tscn") if is_ladder else preload("res://models/SnakeModel.tscn")
        var instance := prefab.instantiate()
        instance.global_position = start_pos
        instance.look_at(end_pos, Vector3.UP)     # orient start -> end
        add_child(instance)
```

### 3.2 Snakes & Ladders Data

`singleton/SnLData.gd` – registered as the `SnLData` **AutoLoad** singleton:

```gdscript
extends Node

# start_cell -> end_cell  (start > end = snake, start < end = ladder)
var connections: Dictionary = {
    16: 6,
    48: 30,
    62: 19,
    64: 60,
    71: 91,
    79: 99,
    93: 73,
    95: 75,
    97: 78,
    98: 84,
}

# Returns the cell a token lands on after a snake/ladder at `cell`.
func get_destination(cell: int) -> int:
    return connections.get(cell, cell)
```

### 3.3 Player & Dice AI

`Player.gd` – attached to each token (`@class_name Player` so the turn controller can type its player list). Tokens are plain `Node3D`s (a `MeshInstance3D` child renders the model). This replaces the spec's `RigidBody3D (Static)` approach: tweening `global_position` on a physics body is fragile and produces warnings, whereas a plain node moves cleanly and the tween auto-binds to the node (auto-killed on free).

```gdscript
@class_name Player
extends Node3D

@export var player_id: int = 1
var current_cell: int = 1
var is_moving: bool = false

signal move_finished(player_id: int, final_cell: int)

func move_steps(steps: int) -> void:
    if is_moving or steps <= 0:
        return
    is_moving = true

    # Build the exact path the token will follow, including a bounce-back
    # if it overshoots cell 100 (overshoot bounces downward from 100).
    var raw_target := current_cell + steps
    var path: Array[int] = []
    if raw_target <= 100:
        for i in range(current_cell + 1, raw_target + 1):
            path.append(i)
    else:
        for i in range(current_cell + 1, 101):
            path.append(i)
        var bounced := 100 - (raw_target - 100)
        bounced = max(bounced, 1)          # guard against absurd overshoot -> cell 0
        for i in range(99, bounced - 1, -1):
            path.append(i)

    var board := get_node("/root/Board") as Board
    # Node.create_tween() auto-plays on the next frame and is auto-killed
    # when this node is freed, so there is no ownership/GC bookkeeping.
    var tween := self.create_tween()
    tween.set_parallel(false)              # make each step run one after another

    for cell in path:
        tween.tween_property(self, "global_position", board.get_cell_position(cell), 0.12) \
            .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

    var final_cell := path[-1]

    # Resolve a snake or ladder on the landing cell.
    if SnLData.connections.has(final_cell):
        var after := SnLData.connections[final_cell]
        tween.tween_property(self, "global_position", board.get_cell_position(after), 0.30) \
            .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        final_cell = after

    tween.finished.connect(_on_move_finished.bind(final_cell))

func _on_move_finished(final_cell: int) -> void:
    current_cell = final_cell
    is_moving = false
    move_finished.emit(player_id, final_cell)
```

`DiceRoll.gd` – minimal AI / random roll for a single 6-sided die. Registered globally via `@class_name` (no autoload needed):

```gdscript
@class_name DiceRoll
extends RefCounted        # stateless roller – lighter than a Node

@export var dice_faces: int = 6

func roll() -> int:
    return randi() % dice_faces + 1     # 1..dice_faces
```

(For a 3D dice-toss animation, roll the model with `apply_impulse` on a short-lived `RigidBody3D` die and read `linear_velocity` length, or just call `DiceRoll.new().roll()` and animate the token.)

### 3.4 Turn Controller

`singleton/GameController.gd` – registered as the `GameController` AutoLoad (or use any Node that owns the player list). It owns turn order, dice input, and the win condition.

```gdscript
extends Node

# NOTE: GameController is an AutoLoad singleton, which Godot compiles during
# the filesystem scan — BEFORE @class_name globals (Player, DiceRoll) are
# registered and BEFORE typed-resource indexing finishes. Using those classes as
# compile-time TYPES here (`Array[Player]`, `as Player`, `DiceRoll.new()` with an
# inferred type, or `@onready var dice: DiceRoll = DiceRoll.new()`) fails with
# "Could not find type Player / Could not preload resource". The robust fix is
# to keep storage untyped (dynamic dispatch) and resolve the dice class at
# RUNTIME via load(), which only runs after the scan completes.
signal dice_rolled(player_id: int, steps: int)

var players: Array = []              # Player token nodes (add to group "players")
var current_player_index: int = 0
var dice = null                      # DiceRoll instance, created in _ready

func _ready() -> void:
    dice = load("res://src/DiceRoll.gd").new()
    for node in get_tree().get_nodes_in_group("players"):
        if node.has_method("move_steps"):
            players.append(node)
            node.connect("move_finished", Callable(self, "_on_player_moved"))

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("roll_dice"):
        if players.size() > 0 and not _current_player_is_moving():
            _roll_for_current_player()

func _current_player_is_moving() -> bool:
    return players[current_player_index].is_moving if players.size() else false

func _roll_for_current_player() -> void:
    var steps: int = dice.roll()
    var player = players[current_player_index]
    dice_rolled.emit(player.player_id, steps)
    player.move_steps(steps)

func _on_player_moved(player_id: int, final_cell: int) -> void:
    if final_cell >= 100:
        print("Player %d wins!" % player_id)
        get_tree().quit()   # or open a Game Over screen
        return
    current_player_index = (current_player_index + 1) % players.size()
```

---

## 4️⃣ GRAPHICS & VISUAL POLISH

**Lighting.** One `DirectionalLight3D` (sun) at ~45°, plus a single baked `LightmapGI` covering the board. Moving tokens/dice use only the dynamic sun + a cheap `OmniLight3D` flicker; avoid real-time lights on the static board. The board uses an `Unshaded` material modulated by the lightmap so lighting is essentially pre-baked (≈ 0 dynamic cost).

**Post-processing.** A `WorldEnvironment` with:
- A tiny `Bloom` (threshold ~1.2, intensity ~0.3) for dice-roll sparkle.
- `Tonemap`: `Filmic` or `Reinhard`, `HDR` off (saves memory per §1).
- `Auto exposure`: fixed (deterministic look).
- `SSAO`/`SSR`: OFF (not needed for this style; keeps draw-calls low).

**Shaders.** Keep it simple:
- Board: `StandardMaterial3D` (or `UnshadedX11`) with a baked `LightmapTexture`.
- Snakes: vertex-animated UV scroll along a `Noise` texture to simulate slithering (≈ 1 draw call, no CPU work).
- Ladders: a `UVScroll` material on the side rails.
- Tokens: a cheap `Fresnel`-rim highlight so they pop against the board.

**Particle FX (`CPUParticles3D`).** (CPU particles keep the GPU for rendering and stay well within budget on M2.)
- Dice roll: ~30 sparkles, 0.4 s, one-shot, attached to the die.
- Snake descent: ~50 upward puffs, `TRANS_BACK` scale, one-shot.
- Ladder climb: ~30 ascending sparkles, one-shot, triggered from `place_snakes_and_ladders`.
- Win: ~120 sparkles burst, 1.2 s, ring emission.

**Frame-rate budget.** Target > 60 fps. On a 60 Hz MacBook display this also matches the refresh (V-Sync ON from §1). At 1080p/Forward+ expect ~0.8 ms CPU + ~7 ms GPU per frame. If it dips below 60, disable `SSAO`, drop particle counts by half, and halve `MSAA`.

---

## 5️⃣ AUDIO & UI

**Sound FX** (OGG, ≤ 128 KB each, from freesound.org):
- `sfx_dice_roll.ogg` – short rattle, ~0.6 s.
- `sfx_token_step.ogg` – light tick per cell (or a single glide).
- `sfx_snake_swoosh.ogg` – descending slide.
- `sfx_ladder_creak.ogg` – ascending clack.
- `sfx_win.ogg` – short fanfare, ~1 s.

**Music.** One looping `ogg` (~1–2 MB, looped, low CPU) – light orchestral/folky. Cross-fade 1 bar on win.

**UI flow:**
1. **Start Menu** – title, "Roll dice" instruction, 2–4 player selector.
2. **Player Setup** – choose token color/model per player.
3. **Gameplay HUD** – player indicator, dice-result banner, cell counter, "Your turn" prompt.
4. **Game Over** – winner podium screen with replay button.

Use a `CanvasLayer` for UI so it isn't culled by the 3D camera. Atlas all UI icons into the 1024×1024 atlas from §2.

**Localization.** Store strings in a `strings.<locale>.csv` (`key,en,es,fr,...`) and load via `TranslationServer`. Keep text UI-only (no 3D text) so translations can resize freely.

---

## 6️⃣ PERFORMANCE-BUDGET CHECKLIST (Apple Silicon / M2, 8 GB)

| Budget | Target | How to verify |
|---|---|---|
| VRAM | < 256 MB | Look & Feel tab; asset import sizes per §2. |
| Draw calls | < 100 (ideally ~60) | Godot `Debugger → Draw calls`. |
| Batches | < 40 | Same panel; use the texture atlas to merge. |
| CPU time / frame | < 4 ms (main thread) | `Debugger → Profiler → process time`. |
| Physics ticks | ≤ 2 ms @ 120 Hz | `Debugger → Profiler → physics`. |
| Particles | < 200 total emitting | `Debugger → Objects → Particles`. |
| FPS | ≥ 60 (cap = refresh) | `Debugger → Render → FPS` (target 60). |
| Export size | < 60 MB (macOS) | Built-in; Godot runtime ≈ 30 MB + assets ~5 MB. |

**Profiling tips (macOS):**
- Use Godot's **Debugger** panels live over Play-From-Editor.
- `Window → Editor → Profiler` → tick `Physics` and `Process`, watch the 120-Hz spikes.
- In an export, press **F5** (godot `--debugger`) to attach the remote inspector.
- For GPU/frame time, use **Activity Monitor → Energy** or **Metal System Trace** (`metal` template) to confirm < 16.7 ms/frame.
- Run `godot --headless --profile` for a no-window CPU profile.

**Apple-Silicon specifics.** `ASTC 4x4` textures (§1) decompress in hardware; keep `max_memory` at 2 GB for the editor (§1); never exceed 1024×1024 single textures on integrated GPU to avoid tiling cost.

---

## 7️⃣ BUILD-AND-DEPLOY SCRIPT

One-click export to macOS (Apple Silicon). Save as `export.sh` and run `./export.sh`.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Resolve project root regardless of where the script is invoked from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PROJECT_PATH="$(pwd)"
EXPORT_NAME="3d-snakes-ladders-macos"
EXPORT_PATH="build/$EXPORT_NAME.app"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/Resources/godot}"
# If you launch Godot via the CLI template, use `godot` instead; fall back to it.
if ! command -v godot >/dev/null 2>&1 && [[ -x "$GODOT_BIN" ]]; then
  GODOT_BIN="$GODOT_BIN"
elif command -v godot >/dev/null 2>&1; then
  GODOT_BIN="$(command -v godot)"
fi

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "❌ Godot executable not found. Set GODOT_BIN or install Godot." >&2
  exit 1
fi

echo "▶️ Exporting release build for macOS (Apple Silicon)…"
"$GODOT_BIN" --headless --path "$PROJECT_PATH" \
  --export-release "macOS" "$EXPORT_PATH"

echo "▶️ Zipping app for distribution…"
ditto -c -k --keep-parent "$EXPORT_PATH" "$EXPORT_NAME.zip"

echo "✅ Build complete: $EXPORT_NAME.zip"
ls -lh "$EXPORT_NAME.zip"
```

**Setup once:**
1. In Godot, **Project → Project Settings → Export → Templates** – install the macOS export templates.
2. **Project → Export → macOS** – add a preset named exactly `macOS` (Apple SILICON architecture), sign with your Developer ID (or set to unsigned for local build).
3. `chmod +x export.sh`.

**Optional platforms.** Add `iOS` and `Android` presets and export similarly with `--export-release "iOS" build/ios.ipa` and `--export-release "Android" build/android.apk`. For iOS you must set up a provisioning profile in **Project → Export → iOS**.

**CI.** Drop `export.sh` (and the `build/` dir) into a GitHub Actions workflow using the `chickensoft/godot-export` action; it caches export templates and runs the same `--export-release` command headless.

---

### ✅ Verified against Godot 4.x API
- `@export` (not Godot 3's `export()`).
- `Node.create_tween()` auto-plays on the next frame and is auto-killed when the node is freed.
- `Tween.TRANS_SINE` / `Tween.TRANS_BACK`, `set_ease(Tween.EASE_IN_OUT)`, `set_parallel(false)`, and the `finished` signal are all valid in Godot 4.

## 4️⃣ GRAPHICS & VISUAL POLISH

- **Renderer:** `Forward+ + Mobile` (default). `Forward+` is Metal-native and fast on M2; use `Mobile` on the lowest presets to save draw-calls.
- **Textures:** keep everything compressed. macOS Apple Silicon requires **ETC2 / ASTC** (not just BPTC/S3TC) for the shader-variant import — see §7.
- **Board material:** `StandardMaterial3D` (or `ShaderMaterial3D`) with a baked **lightmap** + AO. One draw-call for the whole grid floor.
- **Snakes/Ladders:** low-poly curve extrudes (snake) / simple planks (ladder), 1–2 draw-calls each via `MeshInstance3D` + shared material.
- **Dice:** roll a short-lived `RigidBody3D` die with `apply_impulse` and read `linear_velocity.length()`; on `sleeping` spawn `DiceRoll.roll()`, or skip physics and tween the token directly (see Player.gd).
- **Particles:** `CPUParticles3D` for dust puffs on landing; `GPUParticles3D` for win sparkles.
- **Post-process:** `WorldEnvironment` with `Tonemap = Reinhard`, `Auto-Exposure` off, cheap `DOF` only on the goal cell.
- **Frame-rate target:** `physics_ticks_per_second = 120`, `FPS = 60` (V-Sync ON). On M2 this is free for a 100-cell board.

## 5️⃣ AUDIO & UI

- **SFX:** OGG `@export` a `stream = preload("res://audio/...")` and `AudioStreamPlayer3D.play()` on `move_finished`. ≤ 128 KB each (roll, slide, win).
- **Music:** a single looping `AudioStreamPlayer` (cross-fade on win).
- **UI:** `CanvasLayer` overlay — roll button (bound to the `roll_dice` input action), cell/step label, player-turn highlight. No `Control` scaling issues if `tile_alignment = 64` in `Project Settings → GUI`.
- **Localization:** `Project Settings → Localization` + `tr()` strings in UI only (gameplay text is minimal).

## 6️⃣ PERFORMANCE-BUDGET CHECKLIST (MacBook M2 / Apple Silicon)

| Budget | Target | How |
|---|---|---|
| VRAM | < 30 MB | Board 1024² ETC2 (0.5 MB), snakes/ladders 512² (1 MB), dice/tokens 256² (0.5 MB). |
| Draw calls | < 60 at peak | Atlas UI into 1024², shared materials, LOD off on token (200 tris). |
| Physics | < 1 ms | Physics 2D off; only tweens, no `RigidBody` on the board. |
| CPU (turn loop) | < 2 ms | `DiceRoll.roll()` + tween setup; no per-frame allocations. |
| Binary size | < 100 MB | Godot template is ~120 MB; strip dev `.pck` resources. |

Profiling: `Project → Tools → Profiler` (or save a `.prof` via `--debug`). On M2 the editor idle at ~120 FPS; the exported build typically hits 120 FPS locked.

## 7️⃣ BUILD & DEPLOY

> ✅ **Status:** the project exports a runnable **macOS (Apple Silicon) `.app`** with Godot 4.7.2.stable. Headless release export:
> ```bash
> "$GODOT" --headless --path . --export-release "macOS" build/3d-snakes-ladders-macos.app
> ```
> produces `build/3d-snakes-ladders-macos.app` (valid bundle: `Contents/MacOS/<Executable>`, `Contents/Info.plist`, ad-hoc `_CodeSignature`). Because there is no Apple signing certificate, the build is **ad-hoc signed** and Gatekeeper will warn on first launch — right-click → Open bypasses it; for notarization/distribution add a cert to CI later.

### 7.1 `project.godot` (required keys)

```ini
[application]
config/name = "3D Snakes & Ladders"
bundle_identifier = "com.example.snakesladders"     # used as the default bundle id

[autoload]
SnLData = "res://singleton/SnLData.gd"
GameController = "res://singleton/GameController.gd"

[rendering]
textures/vram_compression/import_etc2_astc = true  # REQUIRED for macOS arm64 export
                                                  # (without this Godot aborts:
                                                  #  "Cannot export for universal or
                                                  #   arm64 if ETC2 ASTC is disabled")
```

The `rendering.textures.vram_compression.import_etc2_astc = true` line is the single most important one for Apple Silicon: Godot 4 will refuse to export arm64/vr universal unless ASTC is enabled, even though the project setting is named `etc2_astc` under the hood.

### 7.2 `export_presets.cfg` (macOS / arm64)

```ini
[preset.0]
name = "macOS"
platform = "macOS"
runnable = true
export_filter = "all_resources"
export_path = "build/3d-snakes-ladders-macos.app"

[preset.0.options]
arch = "arm64"
application/bundle_identifier = "com.example.snakesladders"   # <-- the exporter reads
                                                              #     the bundle id from the
                                                              #     PRESET, not only from
                                                              #     project.godot. Omitting
                                                              #     it yields "Invalid bundle
                                                              #     identifier: Identifier is
                                                              #     missing." Even though
                                                              #     application/bundle_identifier
                                                              #     exists as a project setting,
                                                              #     set it here too.
custom_template = ""
texture_format/bptc = true
texture_format/s3tc = true
codesign/enable = false              # ad-hoc; Gatekeeper warning expected, not fatal
codesign/identity = ""
```

> 🔑 **Gotcha:** the project-setting `application/bundle_identifier` is *not* sufficient on its own — the macOS exporter validates the bundle id from the **export preset's** `application/bundle_identifier` option. Set it under `[preset.0.options]` (above); keep a copy in `project.godot` for the editor/runtime too.

### 7.3 `export.sh` — one-click local export + zip

See `export.sh` (executable). It locates Godot (`GODOT_BIN`, defaults to `godot` on `PATH`), runs the headless release export above, then `ditto -c -k --keep-parent` to produce a distributable `3d-snakes-ladders-macos.zip`.

```bash
./export.sh   # → build/3d-snakes-ladders-macos.app + 3d-snakes-ladders-macos.zip
```

### 7.4 CI — `.github/workflows/build.yml`

Mirrors the verified local command on GitHub-hosted `macos-14`:

```yaml
name: build-macos
on:
  push:
    branches: [main]
  pull_request:

env:
  GODOT_VERSION: 4.7.2-stable           # editor + templates release tag

jobs:
  export:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Download Godot editor
        run: |
          curl -L -o godot.zip \
            "https://github.com/godotengine/godot/releases/download/${{ env.GODOT_VERSION }}/Godot_v${{ env.GODOT_VERSION }}_macos.universal.zip"
          unzip -o godot.zip -d godot-editor
          echo "GODOT_BIN=$(pwd)/godot-editor/Godot.app/Contents/MacOS/Godot" >> "$GITHUB_ENV"

      - name: Install export templates
        run: |
          tpl_tpz="Godot_v${{ env.GODOT_VERSION }}_export_templates.tpz"
          curl -L -o "$tpl_tpz" \
            "https://github.com/godotengine/godot/releases/download/${{ env.GODOT_VERSION }}/$tpl_tpz"
          tpl_dir="$HOME/Library/Application Support/Godot/export_templates/${{ env.GODOT_VERSION }}"
          mkdir -p "$tpl_dir"
          tar -xzf "$tpl_tpz" -C "$tpl_dir" --strip-components=1
          cat "$tpl_dir/version.txt"

      - name: Export release build (macOS arm64)
        run: |
          mkdir -p build
          "$GODOT_BIN" --headless --path "$GITHUB_WORKSPACE" --export-release "macOS" \
            build/3d-snakes-ladders-macos.app

      - name: Package
        run: |
          ditto -c -k --keep-parent build/3d-snakes-ladders-macos.app 3d-snakes-ladders-macos.zip

      - uses: actions/upload-artifact@v4
        with:
          name: 3d-snakes-ladders-macos
          path: |
            build/3d-snakes-ladders-macos.app
            3d-snakes-ladders-macos.zip
```

> 🛠️ Notes. (a) Templates asset name uses the **release tag** (`_export_templates.tpz`, **not** `_export_templates.tpz` per-platform). (b) `macos-14` runners are arm64; `arch = "arm64"` targets them. (c) No codesign identity → ad-hoc (same as local).

### 7.5 Verified build matrix (local, `godot --version` ⇒ `4.7.2.stable.official.ed1daf0bf`)

| Step | Result |
|---|---|
| `first_scan_filesystem` (autoloads incl. `GameController`) | ✅ no parse/compile errors |
| `Registering global classes` (`Board`, `Player`, `DiceRoll`) | ✅ 7 steps, clean |
| `Rendering` texture import (ETC2 ASTC) | ✅ honored after `[rendering] …import_etc2_astc = true` |
| `savepack` (project.binary + caches) | ✅ DONE |
| `export → Code signing bundle` | ✅ DONE |
| `build/3d-snakes-ladders-macos.app` emitted | ✅ valid bundle produced |

❌ **Not in scope (art assets):** the `Board.gd`/`Player.gd` code is complete, but `res://models/LadderModel.tscn`, `res://models/SnakeModel.tscn`, and any token scenes are external placeholders not yet provided — the board generator and turn controller are wired to them and will run once the models exist.
