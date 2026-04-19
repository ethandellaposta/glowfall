"""Generate a crouch-walking spritesheet for the robot.

Top half from crouch frame 9 (the hold pose), bottom half from crouching
frames 8-11 which have bent legs in slightly different positions.
Cycling through them creates a shuffling crouch-walk.
"""

from __future__ import annotations
from pathlib import Path
from PIL import Image

GEN_DIR = Path(__file__).resolve().parents[1]
CROUCH_SHEET = GEN_DIR / "robot-crouching.png"
OUTPUT_SHEET = GEN_DIR / "robot-crouch-walking.png"

CROUCH_COLS = 4
CROUCH_ROWS = 4

OUT_COLS = 4

# Where to split: ratio from top
SPLIT_RATIO = 0.55

# Crouch frame used for the upper body (the hold pose)
TOP_FRAME = 9

# Crouch frames used for the lower body (bent-leg variations).
# Cycle through these to create the walk shuffle.
LEG_FRAMES = [8, 9, 10, 11, 10, 9, 8, 11]


def extract_frame(img: Image.Image, cols: int, rows: int, idx: int) -> Image.Image:
    w, h = img.size
    fw, fh = w // cols, h // rows
    r, c = idx // cols, idx % cols
    return img.crop((c * fw, r * fh, (c + 1) * fw, (r + 1) * fh))


def main() -> None:
    crouch_img = Image.open(CROUCH_SHEET).convert("RGBA")

    cfw = crouch_img.size[0] // CROUCH_COLS
    cfh = crouch_img.size[1] // CROUCH_ROWS

    out_fw, out_fh = cfw, cfh
    split_y = int(out_fh * SPLIT_RATIO)

    # Upper body from the hold frame
    top_frame = extract_frame(crouch_img, CROUCH_COLS, CROUCH_ROWS, TOP_FRAME)
    top_half = top_frame.crop((0, 0, out_fw, split_y))

    # Build each output frame: same top, different legs
    output_frames: list[Image.Image] = []
    for leg_idx in LEG_FRAMES:
        leg_frame = extract_frame(crouch_img, CROUCH_COLS, CROUCH_ROWS, leg_idx)
        bot_half = leg_frame.crop((0, split_y, out_fw, out_fh))

        frame = Image.new("RGBA", (out_fw, out_fh), (0, 0, 0, 0))
        frame.paste(top_half, (0, 0), top_half)
        frame.paste(bot_half, (0, split_y), bot_half)
        output_frames.append(frame)

    # Assemble spritesheet
    num_frames = len(output_frames)
    out_rows = (num_frames + OUT_COLS - 1) // OUT_COLS
    sheet_w = out_fw * OUT_COLS
    sheet_h = out_fh * out_rows
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
    for i, f in enumerate(output_frames):
        r = i // OUT_COLS
        c = i % OUT_COLS
        sheet.paste(f, (c * out_fw, r * out_fh))

    sheet.save(OUTPUT_SHEET)
    print(f"Saved {OUTPUT_SHEET} ({sheet_w}x{sheet_h}, {num_frames} frames, {OUT_COLS} cols)")


if __name__ == "__main__":
    main()
