#!/usr/bin/env python3
"""Create an identifier-free synthetic DICOM image for isolated runtime tests."""

import struct
import sys
from pathlib import Path


def element(group: int, number: int, vr: bytes, value: bytes) -> bytes:
    if len(value) % 2:
        value += b"\0" if vr == b"UI" else b" "
    tag = struct.pack("<HH", group, number)
    if vr in {b"OB", b"OW", b"OF", b"SQ", b"UT", b"UN"}:
        return tag + vr + b"\0\0" + struct.pack("<I", len(value)) + value
    return tag + vr + struct.pack("<H", len(value)) + value


def ui(value: str) -> bytes:
    return value.encode("ascii") + b"\0"


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: create_synthetic_dicom.py OUTPUT")

    sop_class = "1.2.840.10008.5.1.4.1.1.7"
    sop_instance = "2.25.100000000000000000000000000000000001"
    study_instance = "2.25.100000000000000000000000000000000002"
    series_instance = "2.25.100000000000000000000000000000000003"

    meta_body = b"".join(
        [
            element(0x0002, 0x0001, b"OB", b"\0\1"),
            element(0x0002, 0x0002, b"UI", ui(sop_class)),
            element(0x0002, 0x0003, b"UI", ui(sop_instance)),
            element(0x0002, 0x0010, b"UI", ui("1.2.840.10008.1.2.1")),
            element(0x0002, 0x0012, b"UI", ui("2.25.100000000000000000000000000000000004")),
        ]
    )
    meta = element(0x0002, 0x0000, b"UL", struct.pack("<I", len(meta_body))) + meta_body

    pixels = bytes((row + column) % 256 for row in range(64) for column in range(64))
    dataset = b"".join(
        [
            element(0x0008, 0x0008, b"CS", b"DERIVED\\SECONDARY"),
            element(0x0008, 0x0016, b"UI", ui(sop_class)),
            element(0x0008, 0x0018, b"UI", ui(sop_instance)),
            element(0x0008, 0x0060, b"CS", b"OT"),
            element(0x0010, 0x0010, b"PN", b""),
            element(0x0010, 0x0020, b"LO", b""),
            element(0x0020, 0x000D, b"UI", ui(study_instance)),
            element(0x0020, 0x000E, b"UI", ui(series_instance)),
            element(0x0020, 0x0011, b"IS", b"1"),
            element(0x0020, 0x0013, b"IS", b"1"),
            element(0x0028, 0x0002, b"US", struct.pack("<H", 1)),
            element(0x0028, 0x0004, b"CS", b"MONOCHROME2"),
            element(0x0028, 0x0010, b"US", struct.pack("<H", 64)),
            element(0x0028, 0x0011, b"US", struct.pack("<H", 64)),
            element(0x0028, 0x0100, b"US", struct.pack("<H", 8)),
            element(0x0028, 0x0101, b"US", struct.pack("<H", 8)),
            element(0x0028, 0x0102, b"US", struct.pack("<H", 7)),
            element(0x0028, 0x0103, b"US", struct.pack("<H", 0)),
            element(0x7FE0, 0x0010, b"OB", pixels),
        ]
    )

    Path(sys.argv[1]).write_bytes(b"\0" * 128 + b"DICM" + meta + dataset)


if __name__ == "__main__":
    main()
