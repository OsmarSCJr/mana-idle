from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
TARGETS = {
    "assets/ui/knowledge_olive_tree.png": 768,
    "assets/icons/avatar/avatar_pilgrim.png": 512,
    "assets/icons/knowledge/knowledge_communion.png": 512,
    "assets/icons/knowledge/knowledge_mission.png": 512,
    "assets/icons/knowledge/knowledge_roots.png": 512,
    "assets/icons/knowledge/knowledge_word.png": 512,
    "assets/icons/knowledge/knowledge_work.png": 512,
    "assets/icons/ui/ui_daily_blessing.png": 512,
    "assets/icons/ui/ui_open_bible.png": 512,
}


def main() -> None:
    for relative, longest_side in TARGETS.items():
        path = ROOT / relative
        image = Image.open(path).convert("RGBA")
        scale = min(1.0, longest_side / max(image.size))
        if scale < 1.0:
            image = image.resize(
                (round(image.width * scale), round(image.height * scale)),
                Image.Resampling.LANCZOS,
            )
        image.save(path, optimize=True)
        print(f"{relative}: {image.width}x{image.height}")


if __name__ == "__main__":
    main()
