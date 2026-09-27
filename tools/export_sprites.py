"""Render art/src/<sheet>.json -> art/<sheet>.png (1x, exact grid, transparent).
Usage (from project root):  python tools/export_sprites.py [--preview]
Needs Pillow:  pip install pillow
"""
import json, sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC, OUT = ROOT / "art" / "src", ROOT / "art"

def hex_rgba(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)

def render(path, preview=False):
    data = json.loads(path.read_text())
    t, pal = data["tile"], data["palette"]
    sprites = data["sprites"]
    cols = max(s["atlas"][0] for s in sprites) + 1
    rows = max(s["atlas"][1] for s in sprites) + 1
    img = Image.new("RGBA", (cols * t, rows * t), (0, 0, 0, 0))
    for s in sprites:
        ox, oy = s["atlas"][0] * t, s["atlas"][1] * t
        assert len(s["rows"]) == t, f"{s['name']}: needs {t} rows"
        for y, line in enumerate(s["rows"]):
            assert len(line) == t, f"{s['name']} row {y}: needs {t} chars"
            for x, ch in enumerate(line):
                if ch not in pal:
                    raise ValueError(f"{s['name']} row {y}: '{ch}' not in palette")
                if pal[ch]:
                    img.putpixel((ox + x, oy + y), hex_rgba(pal[ch]))
    out = OUT / f"{path.stem}.png"
    img.save(out)
    print("wrote", out.relative_to(ROOT))
    if preview:
        p = OUT / "src" / f"{path.stem}_preview_4x.png"
        img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(p)
        print("wrote", p.relative_to(ROOT))

if __name__ == "__main__":
    for f in sorted(SRC.glob("*.json")):
        render(f, "--preview" in sys.argv)
