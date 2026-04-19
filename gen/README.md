# gen/

This folder contains **generated and scratch assets** used during development.

Current organization:

- `_captures/`: source video captures (`.mov`)
- `_frames/`: extracted frame directories (`*_frames/`)
- `_scratch/`: scratch images / experiments
- `_tools/`: helper scripts used to generate assets

## Used by the game at runtime (do not move/rename)

These files are referenced directly via `res://gen/...` paths in scenes/scripts:

- `sky-layer.png`
- `city-skyline-layer-1.png`
- `city-skyline-layer-2.png`
- `robot-idle.png`
- `robot-walking.png`
- `robot-jumping.png`
- `robot-attack-1-ing.png`
- `scuttle-moving.png`
- `scuttle-attack-1.png`

If you rename or move these, you must update:

- `scenes/CityParallax.tscn`
- `scripts/Player.gd`
- `scripts/Enemy.gd`

## Safe to reorganize / delete (not referenced by the game)

The following items are development artifacts and can be moved into subfolders or deleted if you don’t need them:

- `_captures/*.mov` source captures
- `_frames/*_frames/` extracted frame directories
- `walking_loop_25-35_fps18.gif`
- `Main.png` (tileset/sprite sheet exploration)
- `image.png` (scratch image)
- helper scripts:
  - `_tools/extract_mov_frames.py`
  - `_tools/preview_sprite_loop.py`
  - `_tools/slice_robot_sheet.py`

Note: Godot creates `*.png.import` files next to imported textures. If you move a PNG, move its matching `.import` file too (or let Godot re-import).

## How to regenerate

### Extract frames from a video

From the repository root:

```bash
python gen/_tools/extract_mov_frames.py path/to/video.mov --out-dir gen/_frames/<name>_frames --fps 12
```

### Slice robot sprite sheets

From the repository root:

```bash
python gen/_tools/slice_robot_sheet.py path/to/sheet.png --mode walking --cols 10 --frames 36
```

(Outputs go to `assets/robot/`.)
