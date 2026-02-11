from PIL import Image, ImageDraw
import argparse
import os


WIDTH, HEIGHT = 64, 64
ASSETS_SUBDIR = "textures"

ROBOT_TYPES = [
    "idle",
    "walking",
    "attack-1-ing",
    "jumping",
    "hurting",
    "spawning",
    "dying",
]

FRAMES_PER_MODE = {
    "idle": 8,
    "walking": 8,
    "attack-1-ing": 6,
    "jumping": 4,
    "hurting": 4,
    "spawning": 6,
    "dying": 6,
}

BODY_LIGHT = (120, 140, 160, 255)
BODY_DARK = (70, 85, 105, 255)
OUTLINE = (20, 25, 35, 255)
ACCENT = (60, 190, 230, 255)
CORE_DIM = (30, 110, 140, 255)
CORE_BRIGHT = (90, 210, 240, 255)
DAMAGE_TINT = (180, 110, 110, 255)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--type", choices=ROBOT_TYPES, required=True)
    parser.add_argument("--frame", type=int, required=True)
    return parser.parse_args()


def _normalized_frame(mode: str, frame: int) -> int:
    total = FRAMES_PER_MODE.get(mode, 1)
    if total <= 0:
        return 0
    idx = max(0, frame)
    return idx % total


def _draw_robot_base(
    draw: ImageDraw.ImageDraw,
    bob: int,
    left_arm_offset: int,
    right_arm_offset: int,
    left_leg_offset: int,
    right_leg_offset: int,
    attack_extension: int = 0,
    core_glow: bool = False,
    damage_tint: bool = False,
) -> None:
    body_fill = DAMAGE_TINT if damage_tint else BODY_LIGHT

    torso_top = 24 + bob
    torso_bottom = 46 + bob
    torso_left = 24
    torso_right = 40

    head_height = 12
    head_top = torso_top - head_height - 3
    head_bottom = torso_top - 3
    head_left = 26
    head_right = 38

    # Torso and head
    draw.rectangle([torso_left, torso_top, torso_right, torso_bottom], fill=body_fill, outline=OUTLINE)
    draw.rectangle([head_left, head_top, head_right, head_bottom], fill=body_fill, outline=OUTLINE)

    pelvis_top = torso_bottom - 2
    pelvis_bottom = torso_bottom + 2
    pelvis_left = torso_left + 2
    pelvis_right = torso_right - 2
    draw.rectangle([pelvis_left, pelvis_top, pelvis_right, pelvis_bottom], fill=body_fill, outline=OUTLINE)

    # Visor / eyes
    eye_y = head_top + 5
    draw.rectangle([head_left + 5, eye_y, head_right - 1, eye_y + 3], fill=ACCENT)

    # Chest core
    core_color = CORE_BRIGHT if core_glow else CORE_DIM
    core_cx = (torso_left + torso_right) // 2
    core_cy = torso_top + 9
    draw.ellipse(
        [core_cx - 3, core_cy - 3, core_cx + 3, core_cy + 3],
        fill=core_color,
        outline=OUTLINE,
    )

    shoulder_y = torso_top + 5
    hip_y = torso_bottom
    leg_bottom_base = torso_bottom + 16

    # Arms
    left_arm_left = torso_left - 6
    left_arm_right = torso_left - 1
    left_arm_top = shoulder_y + left_arm_offset
    left_arm_bottom = left_arm_top + 14
    draw.rectangle(
        [left_arm_left, left_arm_top, left_arm_right, left_arm_bottom],
        fill=BODY_DARK,
        outline=OUTLINE,
    )

    right_arm_left = torso_right + 1
    right_arm_right = torso_right + 6
    right_arm_top = shoulder_y + right_arm_offset
    right_arm_bottom = right_arm_top + 14
    draw.rectangle(
        [right_arm_left, right_arm_top, right_arm_right, right_arm_bottom],
        fill=BODY_DARK,
        outline=OUTLINE,
    )

    # Attack extension from right hand
    if attack_extension > 0:
        hand_y = right_arm_bottom
        draw.rectangle(
            [
                right_arm_right,
                hand_y - 1,
                right_arm_right + attack_extension,
                hand_y + 1,
            ],
            fill=ACCENT,
            outline=OUTLINE,
        )

    # Legs
    left_leg_left = 27
    left_leg_right = 31
    left_leg_top = hip_y
    left_leg_bottom = leg_bottom_base + left_leg_offset
    draw.rectangle(
        [left_leg_left, left_leg_top, left_leg_right, left_leg_bottom],
        fill=BODY_DARK,
        outline=OUTLINE,
    )

    right_leg_left = 33
    right_leg_right = 37
    right_leg_top = hip_y
    right_leg_bottom = leg_bottom_base + right_leg_offset
    draw.rectangle(
        [right_leg_left, right_leg_top, right_leg_right, right_leg_bottom],
        fill=BODY_DARK,
        outline=OUTLINE,
    )


def _draw_idle(draw: ImageDraw.ImageDraw, frame: int) -> None:
    idle_bob = [0, 1, 2, 1, 0, -1, -2, -1]
    idle_arms = [0, 1, 1, 0, 0, -1, -1, 0]
    idx = frame % len(idle_bob)
    _draw_robot_base(
        draw,
        bob=idle_bob[idx],
        left_arm_offset=idle_arms[idx],
        right_arm_offset=-idle_arms[idx],
        left_leg_offset=0,
        right_leg_offset=0,
    )


def _draw_walking(draw: ImageDraw.ImageDraw, frame: int) -> None:
    stride = [4, 2, 0, -2, -4, -2, 0, 2]
    bob_pattern = [0, -1, -2, -1, 0, 1, 2, 1]
    idx = frame % len(stride)
    left_leg = stride[idx]
    right_leg = -stride[idx]
    left_arm = -stride[idx] // 2
    right_arm = stride[idx] // 2
    _draw_robot_base(
        draw,
        bob=bob_pattern[idx],
        left_arm_offset=left_arm,
        right_arm_offset=right_arm,
        left_leg_offset=left_leg,
        right_leg_offset=right_leg,
    )


def _draw_attack(draw: ImageDraw.ImageDraw, frame: int) -> None:
    ext = [0, 3, 6, 9, 6, 3]
    idx = frame % len(ext)
    attack_ext = ext[idx]
    arm_lift = [0, -1, -3, -4, -2, -1][idx]
    bob_pattern = [-1, -2, -3, -1, 0, 0]
    _draw_robot_base(
        draw,
        bob=bob_pattern[idx],
        left_arm_offset=0,
        right_arm_offset=arm_lift,
        left_leg_offset=0,
        right_leg_offset=0,
        attack_extension=attack_ext,
        core_glow=True,
    )


def _draw_jumping(draw: ImageDraw.ImageDraw, frame: int) -> None:
    bob = [0, -4, -7, -5]
    leg = [-1, -3, -4, -3]
    arm = [-1, -2, -3, -2]
    idx = frame % len(bob)
    _draw_robot_base(
        draw,
        bob=bob[idx],
        left_arm_offset=arm[idx],
        right_arm_offset=arm[idx],
        left_leg_offset=leg[idx],
        right_leg_offset=leg[idx],
        core_glow=False,
    )


def _draw_hurting(draw: ImageDraw.ImageDraw, frame: int) -> None:
    sway = [0, 1, -1, 2]
    idx = frame % len(sway)
    _draw_robot_base(
        draw,
        bob=sway[idx],
        left_arm_offset=2,
        right_arm_offset=-2,
        left_leg_offset=1,
        right_leg_offset=-1,
        damage_tint=True,
    )


def _draw_spawning(draw: ImageDraw.ImageDraw, frame: int) -> None:
    bob = [4, 2, 0, -1, -2, -1]
    arms = [3, 2, 1, 0, -1, -1]
    idx = frame % len(bob)
    _draw_robot_base(
        draw,
        bob=bob[idx],
        left_arm_offset=arms[idx],
        right_arm_offset=arms[idx],
        left_leg_offset=0,
        right_leg_offset=0,
        core_glow=True,
    )


def _draw_dying(draw: ImageDraw.ImageDraw, frame: int) -> None:
    slump = [0, 1, 3, 5, 7, 9]
    idx = frame % len(slump)
    _draw_robot_base(
        draw,
        bob=slump[idx],
        left_arm_offset=3,
        right_arm_offset=3,
        left_leg_offset=2,
        right_leg_offset=2,
        damage_tint=True,
    )


def create_robot_image(mode: str, frame: int) -> Image.Image:
    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    f = _normalized_frame(mode, frame)

    if mode == "idle":
        _draw_idle(draw, f)
    elif mode == "walking":
        _draw_walking(draw, f)
    elif mode == "attack-1-ing":
        _draw_attack(draw, f)
    elif mode == "jumping":
        _draw_jumping(draw, f)
    elif mode == "hurting":
        _draw_hurting(draw, f)
    elif mode == "spawning":
        _draw_spawning(draw, f)
    elif mode == "dying":
        _draw_dying(draw, f)
    else:
        _draw_idle(draw, f)

    return img


def output_path(mode: str, frame: int) -> str:
    return f"assets/{ASSETS_SUBDIR}/robot_{mode}_{frame:02d}.png"


def main() -> None:
    args = parse_args()
    img = create_robot_image(args.type, args.frame)
    path = output_path(args.type, args.frame)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f"Saved {path}")


if __name__ == "__main__":
    main()
