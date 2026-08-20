#!/usr/bin/env python3
"""Create an identifier-free two-frame DICOM image for isolated overlay tests."""

import struct
import sys
import uuid
from pathlib import Path


def element(group: int, number: int, vr: bytes, value: bytes) -> bytes:
    if len(value) % 2:
        value += b"\0" if vr == b"UI" else b" "
    tag = struct.pack("<HH", group, number)
    if vr in {b"OB", b"OW", b"OF", b"SQ", b"UT", b"UN"}:
        return tag + vr + b"\0\0" + struct.pack("<I", len(value)) + value
    return tag + vr + struct.pack("<H", len(value)) + value


def ui(value: str) -> bytes:
    return value.encode("ascii")


def fresh_uid() -> str:
    """Return a standards-compliant synthetic UID without publishing fixture IDs."""
    return f"2.25.{uuid.uuid4().int}"


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: create_synthetic_multiframe_dicom.py OUTPUT")

    sop_class = "1.2.840.10008.5.1.4.1.1.7.2"
    sop_instance = fresh_uid()
    study_instance = fresh_uid()
    series_instance = fresh_uid()
    implementation_class = fresh_uid()

    meta_body = b"".join(
        [
            element(0x0002, 0x0001, b"OB", b"\0\1"),
            element(0x0002, 0x0002, b"UI", ui(sop_class)),
            element(0x0002, 0x0003, b"UI", ui(sop_instance)),
            element(0x0002, 0x0010, b"UI", ui("1.2.840.10008.1.2.1")),
            element(0x0002, 0x0012, b"UI", ui(implementation_class)),
        ]
    )
    meta = element(0x0002, 0x0000, b"UL", struct.pack("<I", len(meta_body))) + meta_body

    frame_one = bytes((row + column + 1) % 256 for row in range(64) for column in range(64))
    frame_two = bytes((row * 2 + column + 17) % 256 for row in range(64) for column in range(64))
    dataset = b"".join(
        [
            element(0x0008, 0x0008, b"CS", b"DERIVED\\SECONDARY"),
            element(0x0008, 0x0016, b"UI", ui(sop_class)),
            element(0x0008, 0x0018, b"UI", ui(sop_instance)),
            element(0x0008, 0x0060, b"CS", b"OT"),
            element(0x0008, 0x0064, b"CS", b"WSD"),
            element(0x0010, 0x0010, b"PN", b""),
            element(0x0010, 0x0020, b"LO", b""),
            element(0x0018, 0x1063, b"DS", b"1000"),
            element(0x0020, 0x000D, b"UI", ui(study_instance)),
            element(0x0020, 0x000E, b"UI", ui(series_instance)),
            element(0x0020, 0x0011, b"IS", b"1"),
            element(0x0020, 0x0013, b"IS", b"1"),
            element(0x0028, 0x0002, b"US", struct.pack("<H", 1)),
            element(0x0028, 0x0004, b"CS", b"MONOCHROME2"),
            element(0x0028, 0x0008, b"IS", b"2"),
            element(0x0028, 0x0009, b"AT", struct.pack("<HH", 0x0018, 0x1063)),
            element(0x0028, 0x0010, b"US", struct.pack("<H", 64)),
            element(0x0028, 0x0011, b"US", struct.pack("<H", 64)),
            element(0x0028, 0x0030, b"DS", b"0.5\\0.75"),
            element(0x0028, 0x0100, b"US", struct.pack("<H", 8)),
            element(0x0028, 0x0101, b"US", struct.pack("<H", 8)),
            element(0x0028, 0x0102, b"US", struct.pack("<H", 7)),
            element(0x0028, 0x0103, b"US", struct.pack("<H", 0)),
            element(0x0028, 0x0301, b"CS", b"NO"),
            element(0x2050, 0x0020, b"CS", b"IDENTITY"),
            element(0x7FE0, 0x0010, b"OB", frame_one + frame_two),
        ]
    )

    output = Path(sys.argv[1])
    try:
        with output.open("xb") as stream:
            stream.write(b"\0" * 128 + b"DICM" + meta + dataset)
    except FileExistsError:
        raise SystemExit(f"STOP: output already exists: {output}") from None


if __name__ == "__main__":
    main()
