from PIL import Image

WIDTH, HEIGHT = 64, 64

ASSETS_SUBDIR = "textures"

# Palette (RGBA) - blue‑gray rock
ROCK_DARK      = (0x1c, 0x23, 0x30, 255)
ROCK_MID       = (0x2b, 0x36, 0x48, 255)
ROCK_LIGHT     = (0x45, 0x57, 0x71, 255)
ROCK_HIGHLIGHT = (0x6a, 0x7a, 0x8e, 255)


def ground_color(x: int, y: int) -> tuple[int, int, int, int]:
    """Return the RGBA color for pixel (x, y) in a 64x64 rocky tile.

    Full tile is blue‑gray rock with granular variation.
    """
    # Base granular rock texture.
    # Use a mix of linear and xor terms to avoid obvious stripes
    # while still being fully deterministic.
    n = (x * 13 + y * 17 + (x ^ (y * 3))) & 63

    # Bias toward mid and light, with very rare highlights.
    if n < 8:
        color = ROCK_DARK        # deeper pockets
    elif n < 46:
        color = ROCK_MID         # main mass
    elif n < 62:
        color = ROCK_LIGHT       # lighter planes
    else:
        color = ROCK_HIGHLIGHT   # very sparse bright flecks

    # Occasional darker "cracks" mostly vertical-ish
    if 6 < y < HEIGHT - 4 and x % 11 == 0 and (x + y) % 4 == 0:
        color = ROCK_DARK

    # Sparse extra light pixels deeper in the rock
    if 10 < y < HEIGHT - 6 and (x + 2 * y) % 19 == 0:
        color = ROCK_LIGHT

    return color

def generate_ground_tile(path: str = f"assets/{ASSETS_SUBDIR}/ground.png") -> None:
    img = Image.new("RGBA", (WIDTH, HEIGHT))
    pixels = img.load()

    for y in range(HEIGHT):
        for x in range(WIDTH):
            pixels[x, y] = ground_color(x, y)

    img.save(path)
    print(f"Saved {path}")

if __name__ == "__main__":
    generate_ground_tile()
