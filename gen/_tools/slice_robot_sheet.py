from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

# Where Player.gd expects to find textures
ASSETS_SUBDIR = "robot"
DEFAULT_TARGET_SIZE = 64  # final frame width/height in pixels (set 0 to keep original)


def slice_sheet(
    sheet_path: Path,
    mode: str,
    cols: int,
    frame_count: int,
    target_size: int = DEFAULT_TARGET_SIZE,
    normalize_size: int = 0,
) -> None:
    if cols <= 0:
        raise SystemExit("--cols must be > 0")
    if frame_count <= 0:
        raise SystemExit("--frames must be > 0")

    img = Image.open(sheet_path).convert("RGBA")
    sheet_w, sheet_h = img.size

    # Assume a uniform grid of cols across; infer frame width/height.
    frame_w = sheet_w // cols
    if frame_w <= 0:
        raise SystemExit("Computed frame width is 0; check --cols against sheet width")

    # Compute how many rows we need to cover frame_count frames.
    rows_needed = (frame_count + cols - 1) // cols
    frame_h = sheet_h // rows_needed
    if frame_h <= 0:
        raise SystemExit("Computed frame height is 0; check --cols/--frames against sheet size")

    out_dir = sheet_path.parents[1] / "assets" / ASSETS_SUBDIR
    out_dir.mkdir(parents=True, exist_ok=True)

    for i in range(frame_count):
        row = i // cols
        col = i % cols
        x0 = col * frame_w
        y0 = row * frame_h
        x1 = x0 + frame_w
        y1 = y0 + frame_h

        frame = img.crop((x0, y0, x1, y1))

        if target_size:
            # Pad to square before resizing to preserve aspect ratio
            # Use normalize_size if provided, otherwise use the frame's max dimension
            pad_dim = normalize_size if normalize_size > 0 else max(frame.width, frame.height)
            if frame.width != pad_dim or frame.height != pad_dim:
                padded = Image.new("RGBA", (pad_dim, pad_dim), (0, 0, 0, 0))
                # Center the frame in the padded image
                x_offset = (pad_dim - frame.width) // 2
                y_offset = (pad_dim - frame.height) // 2
                padded.paste(frame, (x_offset, y_offset))
                frame = padded

            if frame.width != target_size or frame.height != target_size:
                frame = frame.resize((target_size, target_size), Image.NEAREST)

        out_path = out_dir / f"robot_{mode}_{i:02d}.png"
        frame.save(out_path)
        print(f"Saved {out_path}")


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Slice a robot sprite sheet into individual frames.")
    parser.add_argument("sheet", type=Path, help="Path to the source sprite sheet PNG")
    parser.add_argument(
        "--mode",
        required=True,
        help="Animation mode name (e.g. walking, idle, attack-1-ing, jumping)",
    )
    parser.add_argument(
        "--cols",
        type=int,
        required=True,
        help="Number of columns in the sheet grid",
    )
    parser.add_argument(
        "--frames",
        type=int,
        default=10,
        help="Number of frames to export from the sheet (row-major order)",
    )
    parser.add_argument(
        "--target-size",
        type=int,
        default=DEFAULT_TARGET_SIZE,
        help="Resize each frame to this square size in pixels; set 0 to keep original size",
    )
    parser.add_argument(
        "--normalize-size",
        type=int,
        default=0,
        help="Pad all frames to this size before resizing (ensures consistent robot size across sheets)",
    )

    args = parser.parse_args(argv)

    slice_sheet(
        sheet_path=args.sheet,
        mode=args.mode,
        cols=args.cols,
        frame_count=args.frames,
        target_size=args.target_size,
        normalize_size=args.normalize_size,
    )


if __name__ == "__main__":  # pragma: no cover
    main()
