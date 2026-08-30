# Session Notes — 3D Snakes & Ladders (Godot 4)

> Status captured for the next session. Repo: `kapilthakare-cyberpunk/3d-snakes-ladders` (public, `main`).
> Last run: 2026-08-30 — **build green both locally and in CI.**

## Current state (as of this session)
- **Repo:** `github.com/kapilthakare-cyberpunk/3d-snakes-ladders`, branch `main`, HTTPS remote `origin`.
- **Git log (tip):** 2 commits — `539c1fe` (initial blueprint + source + CI) → `6c886b5` (ditto `--keep-parent` fix).
- **Local build:** ✅ `--headless --export-release "macOS" build/3d-snakes-ladders-macos.app` produces a valid bundle (executable `3D Snakes & Ladders`, ~170 MB, ad-hoc signed; Gatekeeper warns on first run → right-click→Open bypasses).
- **CI:** ✅ workflow `build-macos` run #33310267407 **success** (43s on `macos-14`); artifact `3d-snakes-ladders-macos` (`.app` + `.zip`) uploaded. Pushing to `main` auto-triggers it.

## What's already built & working (do NOT redo)
- `src/Board.gd`, `src/Player.gd`, `src/DiceRoll.gd` — compile-clean under Godot 4.7.2 (`@class_name`).
- `singleton/SnLData.gd` + `singleton/GameController.gd` — autoloads compile.
- `GameController` uses the **autoload-safe** pattern: untyped `var players: Array = []`, `var dice = null`, and `dice = load("res://src/DiceRoll.gd").new()` in `_ready()`. The typed version (`Array[Player]`, `DiceRoll.new()` with type inference) does **not** compile — autoloads are built before `@class_name` globals register. Keep it this way.
- `project.godot`: `[rendering] textures/vram_compression/import_etc2_astc = true` (REQUIRED for macOS arm64 export; without it Godot aborts with the ETC2 ASTC error) + `application/bundle_identifier` + `[autoload]` SnLData/GameController.

## Key gotchas / decisions (for next session)
- **Bundle identifier:** must be set in the EXPORT PRESET (`[preset.0.options] application/bundle_identifier = "com.example.snakesladders"`), NOT only in `project.godot`. If missing there → `Invalid bundle identifier: Identifier is missing.`
- **Export preset option names** (verified via `strings $GODOT`): `arch="arm64"`, `application/bundle_identifier`, `texture_format/bptc`, `texture_format/s3tc`, `codesign/enable=false` (ad-hoc), `codesign/identity=""`.
- **`ditto` zip step:** this macOS `ditto` rejects `--keep-parent`; use plain `ditto -c -k <src> <dst>.zip` (works locally + in CI).
- **Templates version is dotted** (`4.7.2.stable`), distinct from the release tag (`4.7.2-stable`). Install to `.../export_templates/4.7.2.stable`.
- `gdlint` (gdtoolkit v4.5.0 in `/tmp/gdenv`) is unreliable — its parser rejects valid `@class_name`. Validate with the real binary, not gdlint.
- `--script` validation hangs on this macOS box (renderer init). Use `--export-release` for feedback.

## Local environment (local-only, NOT in repo)
- Editor: `/tmp/godot-extract/Godot.app` (`4.7.2.stable.official.ed1daf0bf`).
- Templates: `$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable` (has `version.txt`, `macos.zip`, …).
- Scratch venv: `/tmp/gdenv` (gdtoolkit) — deprecated/unreliable, safe to delete.

## How to reproduce the build (local)
```bash
./export.sh      # or, manually:
GODOT=/tmp/godot-extract/Godot.app/Contents/MacOS/Godot
rm -rf build && mkdir -p build
"$GODOT" --headless --path . --export-release "macOS" build/3d-snakes-ladders-macos.app
ditto -c -k build/3d-snakes-ladders-macos.app 3d-snakes-ladders-macos.zip
```

## How to watch CI
```bash
gh run list --repo kapilthakare-cyberpunk/3d-snakes-ladders -L 3
gh run watch <run-id> --repo kapilthakare-cyberpunk/3d-snakes-ladders
```

---

## Remaining tasks (next session)
Priority / order:

1. **Main scene + run config.** Currently there is no `application/run/main_scene` → exporting/running yields a blank window. Add a `Main.tscn` (`Node3D` root) with a `Board` node, a `Camera3D` (top-down/angled), a `WorldEnvironment` (skybox + light), and 2–4 `Player` token instances in group `players`. Set `application/run/main_scene = "res://Main.tscn"` in `project.godot`.
2. **Placeholder 3D models.** `Board.gd` `place_snakes_and_ladders()` hard-requires `res://models/LadderModel.tscn` and `res://models/SnakeModel.tscn`; `Player.gd` references `/root/Board`. Without the ladder/snake models, `_ready()` errors at runtime. Create simple low-poly placeholders (e.g. slanted boxes for ladders, a bent cylinder for snakes) so the board populates. (Token scenes: colored `MeshInstance3D` spheres are fine.)
3. **Input map.** Bind an action named `roll_dice` (e.g. mouse-left / space / a keypress) in `project.godot` so `GameController._input` advances turns.
4. **(Optional) Visual polish / assets.** Replace placeholders with Kenney/Mixamo assets per the spec §2 pipeline; add a 100-cell textured board grid, dice model, particle FX, sounds.
5. **(Optional) Codesign/notarization.** Requires an Apple Developer cert + `codesign/identity` + notarization entitlement in CI. Ad-hoc build is fine for local/testing; for Mac App Store / wide distribution, add signing + notarize + staple. Document the manual `codesign --force --sign -` step at minimum.
6. **(Optional) Other platforms.** Spec §7 mentions iOS/Android/Linux. Add export presets + templates + `texture_format` tweaks; `android/` needs `buildTemplate`/`customPackage`. Defer until macOS is fully playable.
7. Bump versions / tag a release on GitHub when the game is playable end-to-end.

> Note: art assets (the `models/` folder) are intentionally out of scope as external resources — the code is complete and wired to them, but the game won't be visually runnable until step 2 above.
