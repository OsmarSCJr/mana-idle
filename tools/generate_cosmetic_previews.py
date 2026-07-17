from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "icons" / "cosmetics"
SIZE = 256
NAVY = (8, 18, 52, 255)
GOLD = (245, 177, 38, 255)


BACKGROUNDS = {
    "fundo_aurora": ("#1a1030", "#432818", "#ff9a55"),
    "fundo_belem": ("#050b1f", "#0d1b3f", "#d8ebff"),
    "fundo_mar": ("#02131c", "#0a3d4f", "#bffbf2"),
    "fundo_vitral": ("#160a24", "#3b1136", "#ffd0f0"),
    "fundo_jerusalem": ("#1d1503", "#4f3a06", "#fff1a8"),
}

STAR_TINTS = {
    "estrela_cometa": "#cce6ff",
    "estrela_serafim": "#ff9940",
    "estrela_alva": "#fffff2",
}

TITLES = {
    "titulo_peregrino": "PEREGRINO",
    "titulo_semeador": "SEMEADOR",
    "titulo_guardiao": "GUARDIÃO DA ARCA",
    "titulo_escriba": "ESCRIBA FIEL",
    "titulo_profeta": "VOZ NO DESERTO",
    "titulo_vencedor": "MAIS QUE VENCEDOR",
}


def gradient(top: str, bottom: str) -> Image.Image:
    a, b = ImageColor(top), ImageColor(bottom)
    image = Image.new("RGBA", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    for y in range(SIZE):
        t = y / (SIZE - 1)
        c = tuple(round(a[i] * (1 - t) + b[i] * t) for i in range(3)) + (255,)
        draw.line((0, y, SIZE, y), fill=c)
    return image


def ImageColor(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def frame(image: Image.Image) -> None:
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((5, 5, 250, 250), radius=38, outline=(25, 52, 94, 255), width=10)
    draw.rounded_rectangle((13, 13, 242, 242), radius=30, outline=GOLD, width=4)


def make_backgrounds() -> None:
    for name, (top, bottom, star) in BACKGROUNDS.items():
        image = gradient(top, bottom)
        draw = ImageDraw.Draw(image)
        star_rgb = ImageColor(star)
        for x, y, r in ((48, 52, 3), (193, 43, 2), (78, 185, 2), (211, 164, 4), (137, 101, 2)):
            draw.ellipse((x-r, y-r, x+r, y+r), fill=star_rgb + (230,))
        draw.polygon(((128, 57), (136, 114), (196, 128), (136, 141), (128, 202), (119, 141), (60, 128), (119, 114)), fill=star_rgb + (230,))
        frame(image)
        image.save(OUT / f"{name}.png", optimize=True)


def make_stars() -> None:
    source = Image.open(OUT.parent / "special" / "nova_star.png").convert("RGBA")
    alpha = source.getchannel("A")
    luminance = ImageOps.grayscale(source)
    for name, color in STAR_TINTS.items():
        image = gradient("#07122f", "#142c52")
        tint = Image.new("RGBA", source.size, ImageColor(color) + (255,))
        tinted = Image.blend(source, tint, 0.42)
        tinted.putalpha(alpha.point(lambda p: p))
        image.alpha_composite(tinted)
        frame(image)
        image.save(OUT / f"{name}.png", optimize=True)


def make_titles() -> None:
    font_path = ROOT / "assets" / "fonts" / "NotoSerif-Variable.ttf"
    for name, title in TITLES.items():
        image = gradient("#0a1734", "#172d50")
        draw = ImageDraw.Draw(image)
        draw.ellipse((79, 38, 177, 136), fill=(18, 39, 73, 255), outline=GOLD, width=5)
        draw.polygon(((128, 53), (139, 91), (176, 102), (139, 113), (128, 151), (117, 113), (80, 102), (117, 91)), fill=(255, 220, 112, 255))
        size = 25
        while size > 13:
            font = ImageFont.truetype(str(font_path), size)
            if font.getlength(title) <= 210:
                break
            size -= 1
        box = draw.textbbox((0, 0), title, font=font)
        draw.rounded_rectangle((20, 171, 236, 222), radius=14, fill=(6, 15, 39, 235), outline=GOLD, width=2)
        draw.text(((SIZE - (box[2] - box[0])) / 2, 181), title, font=font, fill=(255, 236, 180, 255))
        frame(image)
        image.save(OUT / f"{name}.png", optimize=True)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    make_backgrounds()
    make_stars()
    make_titles()


if __name__ == "__main__":
    main()
