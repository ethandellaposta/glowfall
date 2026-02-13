from __future__ import annotations

import argparse
import shlex
import subprocess
from pathlib import Path


def extract_frames(movie_path: Path, out_dir: Path, fps: float | None) -> None:
    """Extract frames from a video using ffmpeg.

    Args:
        movie_path: Path to the input .mov (or any ffmpeg-supported video).
        out_dir: Directory where frames will be written.
        fps: Optional FPS override. If None, use the source FPS (all frames).
    """
    if not movie_path.exists():
        raise SystemExit(f"Input file does not exist: {movie_path}")

    out_dir.mkdir(parents=True, exist_ok=True)

    # Output pattern: frame_00001.png, frame_00002.png, ...
    output_pattern = out_dir / "frame_%05d.png"

    cmd: list[str] = [
        "ffmpeg",
        "-hide_banner",
        "-loglevel",
        "error",
        "-i",
        str(movie_path),
    ]

    # If fps is provided, use a filter to resample frames.
    if fps is not None:
        cmd += ["-vf", f"fps={fps}"]

    cmd.append(str(output_pattern))

    print("Running:", " ".join(shlex.quote(part) for part in cmd))

    try:
        subprocess.run(cmd, check=True)
    except FileNotFoundError:
        raise SystemExit(
            "ffmpeg not found. Please install it (e.g. `brew install ffmpeg` on macOS)."
        )
    except subprocess.CalledProcessError as exc:
        raise SystemExit(f"ffmpeg failed with exit code {exc.returncode}") from exc


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Extract frames from a .mov (or any video) into a directory "
            "for analysis using ffmpeg."
        )
    )
    parser.add_argument(
        "movie",
        type=Path,
        help="Path to the input .mov or other video file",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=None,
        help=(
            "Directory to write frames into. "
            "Defaults to <movie_stem>_frames next to the input file."
        ),
    )
    parser.add_argument(
        "--fps",
        type=float,
        default=None,
        help=(
            "Optional FPS override (e.g. 12 or 24). "
            "If omitted, uses source FPS and outputs every frame."
        ),
    )

    args = parser.parse_args(argv)

    movie_path: Path = args.movie.resolve()
    if args.out_dir is not None:
        out_dir = args.out_dir.resolve()
    else:
        # e.g. /path/to/clip.mov -> /path/to/clip_frames
        out_dir = movie_path.with_name(movie_path.stem + "_frames")

    extract_frames(movie_path, out_dir, args.fps)


if __name__ == "__main__":  # pragma: no cover
    main()
