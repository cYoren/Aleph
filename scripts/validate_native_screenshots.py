#!/usr/bin/env python3
"""Reject native captures that are blank, black, or unchanged from Home Screen."""
from __future__ import annotations

import argparse
import json
import math
import struct
import sys
import zlib
from pathlib import Path


def decode_png(path: Path):
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"not a PNG: {path}")
    pos = 8
    width: int | None = None
    height: int | None = None
    depth: int | None = None
    color_type: int | None = None
    compressed = bytearray()
    while pos < len(data):
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        kind = data[pos + 4 : pos + 8]
        chunk = data[pos + 8 : pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            width, height, depth, color_type, compression, filtering, interlace = struct.unpack(">IIBBBBB", chunk)
            if depth != 8 or interlace != 0 or compression != 0 or filtering != 0:
                raise ValueError(f"unsupported PNG encoding: {path}")
        elif kind == b"IDAT":
            compressed.extend(chunk)
        elif kind == b"IEND":
            break
    if width is None or height is None:
        raise ValueError(f"missing PNG header: {path}")
    if color_type is None:
        raise ValueError(f"missing PNG color type: {path}")
    channels = {0: 1, 2: 3, 4: 2, 6: 4}.get(color_type)
    if channels is None:
        raise ValueError(f"unsupported PNG color type {color_type}: {path}")
    row_bytes = width * channels
    raw = zlib.decompress(bytes(compressed))
    if len(raw) != height * (row_bytes + 1):
        raise ValueError(f"unexpected PNG payload size: {path}")
    previous = bytearray(row_bytes)
    samples = []
    stride = max(1, min(width, height) // 256)
    offset = 0
    for y in range(height):
        filter_type = raw[offset]
        current = bytearray(raw[offset + 1 : offset + 1 + row_bytes])
        offset += row_bytes + 1
        for i in range(row_bytes):
            left = current[i - channels] if i >= channels else 0
            up = previous[i]
            up_left = previous[i - channels] if i >= channels else 0
            if filter_type == 1:
                current[i] = (current[i] + left) & 255
            elif filter_type == 2:
                current[i] = (current[i] + up) & 255
            elif filter_type == 3:
                current[i] = (current[i] + ((left + up) // 2)) & 255
            elif filter_type == 4:
                estimate = left + up - up_left
                pa, pb, pc = abs(estimate - left), abs(estimate - up), abs(estimate - up_left)
                predictor = left if pa <= pb and pa <= pc else up if pb <= pc else up_left
                current[i] = (current[i] + predictor) & 255
            elif filter_type != 0:
                raise ValueError(f"unsupported PNG filter {filter_type}: {path}")
        if y % stride == 0:
            for x in range(0, width, stride):
                i = x * channels
                if color_type == 0:
                    lum = current[i]
                elif color_type == 2:
                    lum = 0.2126 * current[i] + 0.7152 * current[i + 1] + 0.0722 * current[i + 2]
                elif color_type == 4:
                    lum = current[i] * (current[i + 1] / 255)
                else:
                    alpha = current[i + 3] / 255
                    lum = (0.2126 * current[i] + 0.7152 * current[i + 1] + 0.0722 * current[i + 2]) * alpha
                samples.append(lum)
        previous = current
    return width, height, samples


def stats(samples):
    mean = sum(samples) / len(samples)
    variance = sum((value - mean) ** 2 for value in samples) / len(samples)
    return {"mean": mean, "stdev": math.sqrt(variance), "active_fraction": sum(value > 10 for value in samples) / len(samples)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("image", type=Path)
    parser.add_argument("--baseline", type=Path)
    args = parser.parse_args()
    width, height, samples = decode_png(args.image)
    result = {"image": str(args.image), "width": width, "height": height, **stats(samples)}
    failures = []
    if result["mean"] <= 5 or result["stdev"] <= 3:
        failures.append("black-or-uniform")
    if result["active_fraction"] < 0.01:
        failures.append("mostly-empty")
    if args.baseline:
        base_width, base_height, base_samples = decode_png(args.baseline)
        if (width, height) != (base_width, base_height):
            failures.append("baseline-dimension-mismatch")
        else:
            difference = sum(abs(a - b) for a, b in zip(samples, base_samples)) / len(samples)
            result["baseline_mean_abs_difference"] = difference
            if difference < 2:
                failures.append("unchanged-from-baseline")
    result["passed"] = not failures
    result["failures"] = failures
    print(json.dumps(result, indent=2))
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
