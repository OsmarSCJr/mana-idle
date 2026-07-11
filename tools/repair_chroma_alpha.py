#!/usr/bin/env python3
"""Restaura opacidade interna sem reintroduzir o fundo chroma conectado."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--helper", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--distance", type=float, default=180.0)
    parser.add_argument("--feather", type=float, default=0.65)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    source = np.asarray(Image.open(args.source).convert("RGB"), dtype=np.int16)
    helper_image = Image.open(args.helper).convert("RGBA")
    helper = np.asarray(helper_image, dtype=np.uint8).copy()

    border = np.concatenate(
        [source[0], source[-1], source[:, 0], source[:, -1]], axis=0
    )
    key = np.median(border, axis=0)
    distance = np.sqrt(np.sum((source.astype(np.float32) - key) ** 2, axis=2))
    candidate = distance <= args.distance

    seed = np.zeros(candidate.shape, dtype=bool)
    seed[0] = candidate[0]
    seed[-1] = candidate[-1]
    seed[:, 0] = candidate[:, 0]
    seed[:, -1] = candidate[:, -1]
    connected_background = ndimage.binary_propagation(seed, mask=candidate)
    subject = (~connected_background).astype(np.uint8) * 255
    subject_alpha = np.asarray(
        Image.fromarray(subject, mode="L").filter(ImageFilter.GaussianBlur(args.feather)),
        dtype=np.uint8,
    )

    # O helper fornece despill e uma borda suave; a máscara conectada apenas
    # recupera áreas internas que compartilham matiz com o chroma.
    original_alpha = helper[:, :, 3].copy()
    restore_rgb = (subject == 255) & (subject_alpha > original_alpha)
    helper[restore_rgb, :3] = source.astype(np.uint8)[restore_rgb]
    helper[:, :, 3] = np.maximum(original_alpha, subject_alpha)
    helper[helper[:, :, 3] == 0, :3] = 0
    args.out.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(helper, mode="RGBA").save(args.out, optimize=True)

    opaque = int(np.count_nonzero(helper[:, :, 3] == 255))
    transparent = int(np.count_nonzero(helper[:, :, 3] == 0))
    print(f"Wrote {args.out} (key={tuple(int(v) for v in key)}, opaque={opaque}, transparent={transparent})")


if __name__ == "__main__":
    main()
