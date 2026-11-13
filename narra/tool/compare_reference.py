"""Compare a golden render with a reference screenshot.

Usage: python3 -I tool/compare_reference.py REFERENCE.webp GOLDEN.png OUT_PREFIX [--top 168]

The reference is cropped below the browser chrome (--top) so both images share
the same device-pixel grid. Writes OUT_PREFIX-side.png (side by side) and
OUT_PREFIX-overlay.png (reference in red, render in cyan; matching dark pixels
appear black), and prints the mean absolute difference.
"""
import sys
from PIL import Image, ImageChops, ImageOps

args = [a for a in sys.argv[1:] if not a.startswith("--")]
top = 168
if "--top" in sys.argv:
    top = int(sys.argv[sys.argv.index("--top") + 1])
    args = [a for a in args if a != str(top)]
ref_path, golden_path, out = args[:3]

golden = Image.open(golden_path).convert("RGB")
ref = Image.open(ref_path).convert("RGB")
ref = ref.crop((0, top, ref.width, top + golden.height)).resize(golden.size)

side = Image.new("RGB", (golden.width * 2 + 20, golden.height), "white")
side.paste(ref, (0, 0))
side.paste(golden, (golden.width + 20, 0))
side.save(f"{out}-side.png")

r = ImageOps.grayscale(ref)
g = ImageOps.grayscale(golden)
overlay = Image.merge("RGB", (g, r, r))  # reference-only ink -> red, render-only ink -> cyan
overlay.save(f"{out}-overlay.png")

diff = ImageChops.difference(ref, golden).convert("L")
hist = diff.histogram()
mean = sum(i * c for i, c in enumerate(hist)) / (golden.width * golden.height)
print(f"mean abs diff: {mean:.2f} / 255")
