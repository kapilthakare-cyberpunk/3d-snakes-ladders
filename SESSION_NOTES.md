# Session Notes — 3D Snakes & Ladders (Godot 4)

> Status captured for the session. Repo: `kapilthakare-cyberpunk/3d-snakes-ladders` (public, `main`).
> Last run: 2026-08-30 — **Game fully built, playable, and build green locally + in CI.**

## Current state (as of this session)
- **Repo:** `github.com/kapilthakare-cyberpunk/3d-snakes-ladders`, branch `main`, HTTPS remote `origin`.
- **Game Features:**
  - Complete 10x10 3D Board with 100 numbered tiles (`Label3D`), checkered tiles, start/finish highlights, and perimeter framing.
  - Procedural 3D Snakes & Ladders (`LadderModel.gd` and `SnakeModel.gd`) dynamically spanned and oriented between connect cells.
  - 3D Player Tokens (P1 Ruby Red, P2 Cyan Azure) with parabolic hopping tween animations, ladder climb / snake slide animations, and multi-player cell offset logic.
  - 3D Animated Dice (`Dice3D.gd` & `scenes/Dice3D.tscn`) that spins and lands with accurate face orientation matching rolled number.
  - Complete CanvasLayer HUD (`GameUI.gd` & `scenes/GameUI.tscn`) with turn tracking, position badges, interactive Roll Button (<kbd>Space</kbd> key / click), live event ticker, and Victory modal with Play Again flow.
  - AutoLoad state machine in `singleton/GameController.gd` with turn rotation, bounce-back rule from Cell 100, and game stats tracking.
- **Local build:** ✅ `./export.sh` produces `build/3d-snakes-ladders-macos.app` and `3d-snakes-ladders-macos.zip` (~57 MB zip, ~170 MB .app) with 0 errors.

## Architecture
- `Main.tscn` — Root scene instantiating Board, Player1, Player2, Dice3D, GameUI, Camera3D, DirectionalLight3D, and WorldEnvironment.
- `singleton/GameController.gd` — Turn manager, dice coordinator, game lifecycle.
- `singleton/SnLData.gd` — Connections dictionary and lookup helpers.
- `src/Board.gd` — Boustrophedon cell calculation, visual grid generation, and snake/ladder spawner.
- `src/Player.gd` — Token movement, hop tweens, bounce-back overshoot, and snake/ladder transitions.
- `src/Dice3D.gd` — 3D dice physics and tumbling animation.
- `src/GameUI.gd` — UI controller for TopBar, BottomPanel, and VictoryModal.
