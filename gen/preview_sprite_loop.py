from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageChops



@dataclass(frozen=True)
class FrameRange:
    start: int
    end_exclusive: int

    @property
    def length(self) -> int:
        return max(0, self.end_exclusive - self.start)


def _load_frames(dir_path: Path, pattern: str, frame_range: FrameRange) -> list[Image.Image]:
    frames: list[Image.Image] = []
    for i in range(frame_range.start, frame_range.end_exclusive):
        p = dir_path / (pattern % i)
        if not p.exists():
            raise SystemExit(f"Missing frame: {p}")
        frames.append(Image.open(p).convert("RGBA"))
    if not frames:
        raise SystemExit("No frames loaded")
    return frames


def _alpha_masked_mse(a: Image.Image, b: Image.Image) -> float:
    if a.size != b.size:
        b = b.resize(a.size, Image.NEAREST)

    diff = ImageChops.difference(a, b)
    diff_rgb = diff.convert("RGB")
    a_alpha = a.getchannel("A")
    b_alpha = b.getchannel("A")
    alpha = ImageChops.multiply(a_alpha, b_alpha)

    rgb = diff_rgb.tobytes()
    mask = alpha.tobytes()

    total = 0
    count = 0
    for j in range(0, len(rgb), 3):
        m = mask[j // 3]
        if m == 0:
            continue
        r = rgb[j]
        g = rgb[j + 1]
        bl = rgb[j + 2]
        total += r * r + g * g + bl * bl
        count += 3

    if count == 0:
        return 0.0
    return float(total) / float(count)


def _iter_candidate_ranges(
    start: int,
    end_exclusive: int,
    min_len: int,
    max_len: int,
) -> Iterable[FrameRange]:
    for s in range(start, end_exclusive):
        for ln in range(min_len, max_len + 1):
            e = s + ln
            if e > end_exclusive:
                continue
            yield FrameRange(s, e)


def find_best_loop(
    dir_path: Path,
    pattern: str,
    search_start: int,
    search_end_exclusive: int,
    min_len: int,
    max_len: int,
) -> tuple[FrameRange, float]:
    best_range = FrameRange(search_start, min(search_end_exclusive, search_start + min_len))
    best_score: float | None = None

    for fr in _iter_candidate_ranges(search_start, search_end_exclusive, min_len, max_len):
        frames = _load_frames(dir_path, pattern, fr)
        score = _alpha_masked_mse(frames[0], frames[-1])
        if best_score is None or score < best_score:
            best_score = score
            best_range = fr

    if best_score is None:
        raise SystemExit("No candidate ranges")
    return best_range, best_score


def export_gif(frames: list[Image.Image], out_path: Path, fps: float) -> None:
    duration_ms = int(round(1000.0 / max(0.1, fps)))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(
        out_path,
        save_all=True,
        append_images=frames[1:],
        optimize=False,
        duration=duration_ms,
        loop=0,
        disposal=2,
        transparency=0,
    )


def preview_tk(frames: list[Image.Image], fps: float, scale: int) -> None:
    try:
        import tkinter as tk
        from PIL import ImageTk
    except Exception as exc:  # pragma: no cover
        raise SystemExit(
            "tkinter is not available in this Python. Run without preview (--no-preview) or install a Python build with Tk support."
        ) from exc

    delay_ms = int(round(1000.0 / max(0.1, fps)))

    root = tk.Tk()
    root.title("Sprite Loop Preview")

    idx = 0

    def to_photo(img: Image.Image) -> ImageTk.PhotoImage:
        if scale != 1:
            img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
        return ImageTk.PhotoImage(img)

    photos = [to_photo(im) for im in frames]

    lbl = tk.Label(root, image=photos[0])
    lbl.pack()

    def tick() -> None:
        nonlocal idx
        idx = (idx + 1) % len(photos)
        lbl.configure(image=photos[idx])
        root.after(delay_ms, tick)

    root.after(delay_ms, tick)
    root.mainloop()


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--dir",
        type=Path,
        default=Path(__file__).parents[1] / "assets" / "robot",
    )
    parser.add_argument("--pattern", type=str, default="robot_walking_%02d.png")
    parser.add_argument("--start", type=int, default=0)
    parser.add_argument("--end", type=int, default=36)
    parser.add_argument("--fps", type=float, default=24.0)
    parser.add_argument("--scale", type=int, default=6)
    parser.add_argument("--gif", type=Path, default=None)
    parser.add_argument("--no-preview", action="store_true")

    parser.add_argument("--find-best", action="store_true")
    parser.add_argument("--search-start", type=int, default=0)
    parser.add_argument("--search-end", type=int, default=36)
    parser.add_argument("--min-len", type=int, default=6)
    parser.add_argument("--max-len", type=int, default=12)

    args = parser.parse_args(argv)

    dir_path: Path = args.dir

    if args.find_best:
        best_range, best_score = find_best_loop(
            dir_path=dir_path,
            pattern=args.pattern,
            search_start=args.search_start,
            search_end_exclusive=args.search_end,
            min_len=args.min_len,
            max_len=args.max_len,
        )
        print(
            f"Best range: start={best_range.start} end_exclusive={best_range.end_exclusive} "
            f"len={best_range.length} seam_score={best_score:.2f}"
        )
        frame_range = best_range
    else:
        frame_range = FrameRange(args.start, args.end)

    frames = _load_frames(dir_path, args.pattern, frame_range)

    if args.gif is not None:
        export_gif(frames, args.gif, args.fps)
        print(f"Wrote GIF: {args.gif}")

    if not args.no_preview:
        preview_tk(frames, fps=args.fps, scale=args.scale)


if __name__ == "__main__":
    main()
