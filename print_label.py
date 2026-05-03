#!/usr/bin/env python3
"""
Print to Brother QL-800 with DK-2251 (62mm red/black continuous roll).
Usage: python print_label.py image-or-document [...]
"""

import os
import sys
import tempfile
from pathlib import Path

from brother_ql.backends.helpers import send
from brother_ql.conversion import convert
from brother_ql.raster import BrotherQLRaster

import PIL.Image

if not hasattr(PIL.Image, "ANTIALIAS"):
    PIL.Image.ANTIALIAS = PIL.Image.LANCZOS

PRINTER_URI = "usb://0x04f9:0x209b"
MODEL = "QL-800"
LABEL_TYPE = "62red"
PDF_DPI = 300


def print_image(image_path: str, threshold: int = 70):
    qlr = BrotherQLRaster(MODEL)
    qlr.exception_on_warning = True

    instructions = convert(
        qlr=qlr,
        images=[image_path],
        label=LABEL_TYPE,
        rotate="auto",
        threshold=threshold,
        dither=False,
        compress=False,
        red=True,
        cut_now=True,
    )

    send(
        instructions=instructions,
        printer_identifier=PRINTER_URI,
        backend_identifier="pyusb",
        blocking=True,
    )
    print(f"Printed: {image_path}")


def render_pdf_pages(pdf_path: str, output_dir: str) -> list[str]:
    try:
        import fitz
    except ImportError as exc:
        raise RuntimeError(
            "PyMuPDF is required for PDF jobs. Run make deploy to install requirements."
        ) from exc

    pages = []
    document = fitz.open(pdf_path)
    try:
        scale = PDF_DPI / 72
        matrix = fitz.Matrix(scale, scale)
        for page_index in range(document.page_count):
            page = document.load_page(page_index)
            pixmap = page.get_pixmap(matrix=matrix, alpha=False)
            output_path = os.path.join(output_dir, f"page_{page_index + 1:04d}.png")
            pixmap.save(output_path)
            pages.append(output_path)
    finally:
        document.close()

    return pages


def print_path(input_path: str):
    suffix = Path(input_path).suffix.lower()
    if suffix == ".pdf":
        with tempfile.TemporaryDirectory(prefix="ql800_pages_") as temp_dir:
            pages = render_pdf_pages(input_path, temp_dir)
            print(f"Rendered {len(pages)} page(s): {input_path}")
            for page in pages:
                print_image(page)
        return

    print_image(input_path)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python print_label.py <image-or-document> [...]")
        sys.exit(1)

    for path in sys.argv[1:]:
        print_path(path)
