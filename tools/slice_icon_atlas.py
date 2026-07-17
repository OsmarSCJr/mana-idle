#!/usr/bin/env python3
"""Recorta um atlas regular com alpha em ícones PNG prontos para o Godot."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--names", required=True, help="Nomes separados por vírgula")
    parser.add_argument("--size", required=True, type=int)
    parser.add_argument("--rows", type=int, default=2)
    parser.add_argument("--cols", type=int, default=2)
    parser.add_argument("--margin", type=float, default=0.035)
    parser.add_argument("--cell-inset", type=float, default=0.0)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    names = [name.strip() for name in args.names.split(",") if name.strip()]
    if len(names) != args.rows * args.cols:
        raise SystemExit("A quantidade de nomes deve corresponder a rows × cols.")

    image = Image.open(args.input).convert("RGBA")
    width, height = image.size
    args.output_dir.mkdir(parents=True, exist_ok=True)

    for index, name in enumerate(names):
        row, col = divmod(index, args.cols)
        left = round(col * width / args.cols)
        top = round(row * height / args.rows)
        right = round((col + 1) * width / args.cols)
        bottom = round((row + 1) * height / args.rows)
        inset = round(min(right - left, bottom - top) * args.cell_inset)
        left += inset
        top += inset
        right -= inset
        bottom -= inset
        cell = image.crop((left, top, right, bottom))

        bbox = cell.getchannel("A").getbbox()
        if bbox is None:
            raise SystemExit(f"Quadrante vazio para {name}.")
        subject = cell.crop(bbox)

        target_margin = max(2, round(args.size * args.margin))
        available = args.size - target_margin * 2
        scale = min(available / subject.width, available / subject.height)
        resized = subject.resize(
            (max(1, round(subject.width * scale)), max(1, round(subject.height * scale))),
            Image.Resampling.LANCZOS,
        )
        canvas = Image.new("RGBA", (args.size, args.size), (0, 0, 0, 0))
        canvas.alpha_composite(
            resized,
            ((args.size - resized.width) // 2, (args.size - resized.height) // 2),
        )
        canvas.save(args.output_dir / f"{name}.png", optimize=True)


if __name__ == "__main__":
    main()
