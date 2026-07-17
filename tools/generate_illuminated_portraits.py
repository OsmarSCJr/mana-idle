from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "icons" / "profetas"
OUT = SOURCE / "iluminados"
PORTRAITS = (
    "p01_gabriel.png",
    "p02_adao.png",
    "p03_noe.png",
    "p04_nemrod.png",
)


def illuminate(source: Path) -> Image.Image:
    size = 96
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    for angle in range(0, 360, 30):
        import math
        radians = math.radians(angle)
        start = (48 + math.cos(radians) * 34, 48 + math.sin(radians) * 34)
        end = (48 + math.cos(radians) * 45, 48 + math.sin(radians) * 45)
        draw.line((start, end), fill=(255, 211, 91, 210), width=2)
    draw.ellipse((12, 12, 84, 84), fill=(255, 193, 48, 130))
    blurred = glow.filter(ImageFilter.GaussianBlur(5))
    canvas.alpha_composite(blurred)
    canvas.alpha_composite(glow)
    portrait = Image.open(source).convert("RGBA").resize((84, 84), Image.Resampling.LANCZOS)
    canvas.alpha_composite(portrait, (6, 6))
    rim = ImageDraw.Draw(canvas)
    rim.ellipse((5, 5, 91, 91), outline=(255, 230, 145, 255), width=2)
    return canvas


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name in PORTRAITS:
        illuminate(SOURCE / name).save(OUT / name.replace(".png", "_iluminado.png"), optimize=True)


if __name__ == "__main__":
    main()
