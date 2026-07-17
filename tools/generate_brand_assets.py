from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "branding"
NAVY = (8, 18, 52, 255)
NAVY_2 = (17, 43, 82, 255)
GOLD = (245, 177, 38, 255)
GOLD_LIGHT = (255, 224, 126, 255)


def emblem(size: int, transparent: bool = False, monochrome: bool = False) -> Image.Image:
    scale = size / 512
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0) if transparent else NAVY)
    draw = ImageDraw.Draw(image)
    gold = (255, 255, 255, 255) if monochrome else GOLD
    light = gold if monochrome else GOLD_LIGHT

    if not transparent:
        for inset, color in ((18, NAVY_2), (34, NAVY), (47, GOLD), (56, NAVY)):
            draw.rounded_rectangle(
                (inset * scale, inset * scale, (512 - inset) * scale, (512 - inset) * scale),
                radius=(112 - inset / 2) * scale,
                fill=color,
            )

    glow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((119 * scale, 119 * scale, 393 * scale, 393 * scale), outline=gold, width=max(2, int(22 * scale)))
    glow = glow.filter(ImageFilter.GaussianBlur(max(1, int(15 * scale))))
    if not monochrome:
        image.alpha_composite(glow)

    draw = ImageDraw.Draw(image)
    draw.ellipse((119 * scale, 119 * scale, 393 * scale, 393 * scale), outline=gold, width=max(2, int(15 * scale)))
    draw.rounded_rectangle((235 * scale, 148 * scale, 277 * scale, 364 * scale), radius=20 * scale, fill=gold)
    draw.rounded_rectangle((148 * scale, 235 * scale, 364 * scale, 277 * scale), radius=20 * scale, fill=gold)
    draw.rounded_rectangle((244 * scale, 158 * scale, 258 * scale, 352 * scale), radius=7 * scale, fill=light)
    draw.rounded_rectangle((158 * scale, 244 * scale, 352 * scale, 258 * scale), radius=7 * scale, fill=light)
    return image


def fit_font(path: Path, text: str, max_width: int, start_size: int) -> ImageFont.FreeTypeFont:
    size = start_size
    while size > 12:
        font = ImageFont.truetype(str(path), size)
        if font.getlength(text) <= max_width:
            return font
        size -= 2
    return ImageFont.truetype(str(path), 12)


def feature_graphic() -> Image.Image:
    width, height = 1024, 500
    image = Image.new("RGBA", (width, height), NAVY)
    draw = ImageDraw.Draw(image)
    for y in range(height):
        t = y / (height - 1)
        color = tuple(int(NAVY[i] * (1 - t) + NAVY_2[i] * t) for i in range(3)) + (255,)
        draw.line((0, y, width, y), fill=color)
    for x, y, r, alpha in ((75, 65, 2, 150), (155, 370, 3, 100), (472, 62, 2, 120), (905, 88, 3, 145), (846, 410, 2, 120), (560, 444, 2, 90)):
        draw.ellipse((x-r, y-r, x+r, y+r), fill=(255, 224, 126, alpha))
    draw.polygon(((775, 0), (1024, 0), (1024, 500), (620, 500)), fill=(13, 27, 62, 210))
    mark = emblem(360, transparent=True)
    image.alpha_composite(mark, (620, 70))

    serif = ROOT / "assets" / "fonts" / "NotoSerif-Variable.ttf"
    sans = ROOT / "assets" / "fonts" / "Inter-Variable.ttf"
    title = fit_font(serif, "MANÁ IDLE", 530, 88)
    subtitle = fit_font(sans, "FÉ QUE CRESCE. LEGADO QUE PERMANECE.", 520, 28)
    draw.text((70, 155), "MANÁ IDLE", font=title, fill=GOLD_LIGHT, stroke_width=1, stroke_fill=GOLD)
    draw.rounded_rectangle((72, 264, 298, 270), radius=3, fill=GOLD)
    draw.text((72, 298), "FÉ QUE CRESCE. LEGADO QUE PERMANECE.", font=subtitle, fill=(240, 241, 246, 255))
    return image


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    emblem(192).save(OUT / "android_launcher_192.png")
    emblem(432, transparent=True).save(OUT / "android_adaptive_foreground_432.png")
    Image.new("RGBA", (432, 432), NAVY).save(OUT / "android_adaptive_background_432.png")
    emblem(432, transparent=True, monochrome=True).save(OUT / "android_adaptive_monochrome_432.png")
    emblem(512).save(OUT / "play_store_icon_512.png")
    feature_graphic().save(OUT / "play_store_feature_1024x500.png")


if __name__ == "__main__":
    main()
