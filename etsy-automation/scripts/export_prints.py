#!/usr/bin/env python3
"""
export_prints.py — Resize a source PNG into all standard Etsy print sizes.

Usage:
  python3 export_prints.py --slug moody-desert-sun
  python3 export_prints.py --slug moody-desert-sun --workspace /path/to/workspace
  python3 export_prints.py --slug moody-desert-sun --families 2:3,4:5 --fit pad
"""

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path

try:
    from PIL import Image
    # Support both Pillow 9+ (Resampling enum) and older versions
    LANCZOS = getattr(Image, "Resampling", Image).LANCZOS
except ImportError:
    print("ERROR: Pillow is not installed. Run: pip3 install --user Pillow")
    sys.exit(1)


# ---------------------------------------------------------------------------
# Print size definitions — all at 300 DPI
# ISO sizes derived from mm: pixels = round(mm / 25.4 * 300)
# ---------------------------------------------------------------------------
PRINT_SIZES = {
    "2:3": [
        ("4x6",   1200, 1800),
        ("8x12",  2400, 3600),
        ("12x18", 3600, 5400),
        ("16x24", 4800, 7200),
        ("20x30", 6000, 9000),
        ("24x36", 7200, 10800),
    ],
    "3:4": [
        ("6x8",   1800, 2400),
        ("9x12",  2700, 3600),
        ("12x16", 3600, 4800),
        ("15x20", 4500, 6000),
        ("18x24", 5400, 7200),
    ],
    "4:5": [
        ("8x10",  2400, 3000),
        ("11x14", 3300, 4200),
        ("16x20", 4800, 6000),
    ],
    "ISO": [
        ("A5", round(148 / 25.4 * 300), round(210 / 25.4 * 300)),   # 1748x2480
        ("A4", round(210 / 25.4 * 300), round(297 / 25.4 * 300)),   # 2480x3508
        ("A3", round(297 / 25.4 * 300), round(420 / 25.4 * 300)),   # 3508x4961
        ("A2", round(420 / 25.4 * 300), round(594 / 25.4 * 300)),   # 4961x7016
        ("A1", round(594 / 25.4 * 300), round(841 / 25.4 * 300)),   # 7016x9933
    ],
    "Square": [
        ("8x8",   2400, 2400),
        ("10x10", 3000, 3000),
        ("12x12", 3600, 3600),
        ("16x16", 4800, 4800),
    ],
}

ALL_FAMILIES = list(PRINT_SIZES.keys())


def center_crop(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
    """Crop img to target aspect ratio from the center, then resize."""
    src_w, src_h = img.size
    target_ratio = target_w / target_h
    src_ratio = src_w / src_h

    if abs(src_ratio - target_ratio) < 0.01:
        return img.resize((target_w, target_h), LANCZOS)

    if src_ratio > target_ratio:
        # Source is wider — crop sides
        new_w = int(src_h * target_ratio)
        left = (src_w - new_w) // 2
        img = img.crop((left, 0, left + new_w, src_h))
    else:
        # Source is taller — crop top/bottom
        new_h = int(src_w / target_ratio)
        top = (src_h - new_h) // 2
        img = img.crop((0, top, src_w, top + new_h))

    return img.resize((target_w, target_h), LANCZOS)


def pad_fit(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
    """Fit img within target dimensions with white padding."""
    img.thumbnail((target_w, target_h), LANCZOS)
    padded = Image.new("RGB", (target_w, target_h), (255, 255, 255))
    offset_x = (target_w - img.width) // 2
    offset_y = (target_h - img.height) // 2
    padded.paste(img, (offset_x, offset_y))
    return padded


def export_prints(slug: str, workspace: Path, families: list[str],
                  fit: str, fmt: str, dpi: int, allow_upscale: bool) -> None:
    input_path = workspace / "04_generated_art" / f"{slug}.png"
    if not input_path.exists():
        print(f"ERROR: Source image not found: {input_path}")
        print(f"  Drop the Midjourney PNG at that path and retry.")
        sys.exit(2)

    out_dir = workspace / "06_print_exports" / slug
    out_dir.mkdir(parents=True, exist_ok=True)

    img = Image.open(input_path)
    if img.mode != "RGB":
        img = img.convert("RGB")

    src_w, src_h = img.size
    print(f"Source: {src_w}x{src_h}px  mode={img.mode}  file={input_path.name}")

    exported_files = []
    skipped = []

    for family in families:
        if family not in PRINT_SIZES:
            print(f"WARNING: Unknown family '{family}', skipping.")
            continue
        family_dir = out_dir / family.replace(":", "-")
        family_dir.mkdir(exist_ok=True)

        for name, tw, th in PRINT_SIZES[family]:
            if not allow_upscale and (tw > src_w or th > src_h):
                skipped.append(f"{family}/{name} ({tw}x{th}) — source too small, skipping")
                continue

            if fit == "crop":
                out_img = center_crop(img.copy(), tw, th)
            else:
                out_img = pad_fit(img.copy(), tw, th)

            filename = f"{slug}_{name}_{tw}x{th}.{fmt}"
            out_path = family_dir / filename

            save_kwargs = {"dpi": (dpi, dpi)}
            if fmt == "jpg":
                save_kwargs.update({"quality": 95, "optimize": True})
                out_img.save(out_path, "JPEG", **save_kwargs)
            else:
                out_img.save(out_path, "PNG", **save_kwargs)

            byte_size = out_path.stat().st_size
            exported_files.append({
                "family": family,
                "name": name,
                "filename": str(out_path.relative_to(out_dir)),
                "pixels": [tw, th],
                "bytes": byte_size,
            })
            print(f"  {family:7s} {name:6s}  {tw}x{th}  →  {filename}")

    manifest = {
        "slug": slug,
        "source_image": str(input_path.relative_to(workspace)),
        "source_dimensions": [src_w, src_h],
        "exported_at": datetime.now().isoformat(timespec="seconds"),
        "dpi": dpi,
        "fit_mode": fit,
        "format": fmt,
        "families": families,
        "files": exported_files,
    }
    manifest_path = out_dir / "export-manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2))

    print(f"\nExported {len(exported_files)} files to {out_dir}")
    print(f"Manifest: {manifest_path}")
    if skipped:
        print("\nSkipped (source too small):")
        for s in skipped:
            print(f"  {s}")


def main() -> None:
    default_workspace = os.environ.get(
        "ETSY_WORKSPACE",
        os.path.expanduser("~/Desktop/etsy-art-factory/workspace")
    )

    parser = argparse.ArgumentParser(description="Export Etsy print sizes from a source PNG.")
    parser.add_argument("--slug", required=True, help="Product slug (e.g. moody-desert-sun)")
    parser.add_argument("--workspace", default=default_workspace,
                        help=f"Workspace root (default: {default_workspace})")
    parser.add_argument("--input", default=None,
                        help="Override source image path (default: 04_generated_art/<slug>.png)")
    parser.add_argument("--families", default=",".join(ALL_FAMILIES),
                        help=f"Comma-separated families to export (default: all)")
    parser.add_argument("--fit", choices=["crop", "pad"], default="crop",
                        help="How to handle aspect ratio mismatch (default: crop)")
    parser.add_argument("--format", dest="fmt", choices=["jpg", "png"], default="jpg",
                        help="Output format (default: jpg)")
    parser.add_argument("--dpi", type=int, default=300, help="Output DPI (default: 300)")
    parser.add_argument("--allow-upscale", action="store_true",
                        help="Allow resizing to dimensions larger than the source")
    args = parser.parse_args()

    workspace = Path(args.workspace).expanduser().resolve()
    if not workspace.is_dir():
        print(f"ERROR: Workspace not found: {workspace}")
        sys.exit(1)

    families = [f.strip() for f in args.families.split(",") if f.strip()]

    # Override input path if specified
    if args.input:
        src = Path(args.input).expanduser().resolve()
        (workspace / "04_generated_art").mkdir(parents=True, exist_ok=True)
        # Symlink or just pass; export_prints reads from 04_generated_art by default,
        # so we patch workspace reference
        if not src.exists():
            print(f"ERROR: --input path not found: {src}")
            sys.exit(1)
        # Copy to expected location for consistent manifest logging
        import shutil
        dest = workspace / "04_generated_art" / f"{args.slug}.png"
        if not dest.exists():
            shutil.copy2(src, dest)
            print(f"Copied {src.name} → 04_generated_art/{args.slug}.png")

    export_prints(
        slug=args.slug,
        workspace=workspace,
        families=families,
        fit=args.fit,
        fmt=args.fmt,
        dpi=args.dpi,
        allow_upscale=args.allow_upscale,
    )


if __name__ == "__main__":
    main()
