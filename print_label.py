#!/usr/bin/env python3
"""
Print to Brother QL-800 with DK-2251 (62mm red/black continuous roll).
Usage: python print_label.py image.png
"""

import sys

from brother_ql.backends.helpers import send
from brother_ql.conversion import convert
from brother_ql.raster import BrotherQLRaster

import PIL.Image

if not hasattr(PIL.Image, "ANTIALIAS"):
    PIL.Image.ANTIALIAS = PIL.Image.LANCZOS

PRINTER_URI = "usb://0x04f9:0x209b"
MODEL = "QL-800"
LABEL_TYPE = "62red"


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
        blocking=False,
    )
    print("Done.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python print_label.py <image_path>")
        sys.exit(1)
    print_image(sys.argv[1])
