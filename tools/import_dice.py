"""Build art/dice.png (32x32 cells) from James's dice artwork art/src/dice_source.png.
Run from the project root:  python tools/import_dice.py
Layout of the output (col = face, row = whose die):
  row 0 sloth: 0 attack (sloth claw), 1 defend (turtle shell), 2 xp (leaf), 3 blank
  row 1 snake: 0 attack (snake bite), 1 defend (turtle shell), 2 xp (leaf), 3 blank
"""
from collections import Counter
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "art" / "src" / "dice_source.png"
OUT = ROOT / "art" / "dice.png"
N = 32
# Die positions in the source image (x0, x1) and shared rows (y0, y1).
BOXES = {"claw": (90, 406), "shell": (478, 796), "leaf": (868, 1189), "bite": (1264, 1579)}
Y0, Y1 = 251, 572


def sample(a: np.ndarray, x0: int, x1: int) -> np.ndarray:
    """Downsample one die to NxN: each cell takes the dominant colour of its centre."""
    w, h = x1 - x0 + 1, Y1 - Y0 + 1
    out = np.zeros((N, N, 4), dtype=np.uint8)
    for j in range(N):
        for i in range(N):
            cx0 = x0 + int((i + 0.25) * w / N); cx1 = x0 + int((i + 0.75) * w / N) + 1
            cy0 = Y0 + int((j + 0.25) * h / N); cy1 = Y0 + int((j + 0.75) * h / N) + 1
            block = a[cy0:cy1, cx0:cx1].reshape(-1, 4)
            q = [tuple((p // 8 * 8).tolist()) for p in block]
            mode = Counter(q).most_common(1)[0][0]
            m = np.array([p for p, qq in zip(block, q) if qq == mode]).mean(0)
            out[j, i] = m.astype(np.uint8)
            out[j, i, 3] = 255 if out[j, i, 3] >= 128 else 0
            if out[j, i, 3] == 0:
                out[j, i] = 0
    return out


def blank_from(die: np.ndarray) -> np.ndarray:
    """Remove the icon: every non-cream pixel inside the face becomes the face colour."""
    b = die.copy()
    r, g, bl = b[..., 0].astype(int), b[..., 1].astype(int), b[..., 2].astype(int)
    creamish = (r > 170) & (g > 140) & (bl > 95) & (r - bl > 35) & (r > g + 12)
    face = Counter(tuple(p) for p in b[creamish].tolist()).most_common(1)[0][0]
    for y in range(4, N - 4):
        for x in range(4, N - 4):
            if not creamish[y, x]:
                b[y, x] = face
    return b


def main() -> None:
    a = np.array(Image.open(SRC).convert("RGBA"))
    f = {k: sample(a, *v) for k, v in BOXES.items()}
    f["blank"] = blank_from(f["leaf"])
    rows = [["claw", "shell", "leaf", "blank"], ["bite", "shell", "leaf", "blank"]]
    sheet = Image.new("RGBA", (N * 4, N * 2), (0, 0, 0, 0))
    for r, names in enumerate(rows):
        for c, name in enumerate(names):
            sheet.paste(Image.fromarray(f[name], "RGBA"), (c * N, r * N))
    sheet.save(OUT)
    print("wrote", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
