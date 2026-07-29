#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = ["opencv-python-headless", "numpy"]
# ///

import argparse
import json
import os
import sys

os.environ["OPENCV_LOG_LEVEL"] = "SILENT"
import cv2
import numpy as np


def center_crop(img, target_w, target_h):
    h, w = img.shape[:2]
    if w == target_w and h == target_h:
        return img
    x1 = max(0, (w - target_w) // 2)
    y1 = max(0, (h - target_h) // 2)
    return img[y1 : y1 + target_h, x1 : x1 + target_w]


def find_least_busy_region(
    image_path,
    region_width=300,
    region_height=200,
    screen_width=None,
    screen_height=None,
    stride=10,
    screen_mode="fill",
    horizontal_padding=50,
    vertical_padding=50,
    busiest=False,
):
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        raise FileNotFoundError(f"Image not found: {image_path}")
    orig_h, orig_w = img.shape

    if screen_width is not None and screen_height is not None:
        scale_w = screen_width / orig_w
        scale_h = screen_height / orig_h
        scale = (
            max(scale_w, scale_h) if screen_mode == "fill" else min(scale_w, scale_h)
        )
        new_w, new_h = int(orig_w * scale), int(orig_h * scale)
        img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_LANCZOS4)
        img = center_crop(img, screen_width, screen_height)

    arr = img.astype(np.float64)
    h, w = arr.shape
    stride = max(1, int(stride))

    horizontal_padding = max(0, min(horizontal_padding, (w - 1) // 2))
    vertical_padding = max(0, min(vertical_padding, (h - 1) // 2))
    max_region_w = w - 2 * horizontal_padding
    max_region_h = h - 2 * vertical_padding
    if max_region_w <= 0 or max_region_h <= 0:
        raise ValueError("Image too small for the specified padding.")

    region_width = min(region_width, max_region_w)
    region_height = min(region_height, max_region_h)

    integral = cv2.integral(arr, sdepth=cv2.CV_64F)[1:, 1:]
    integral_sq = cv2.integral(arr**2, sdepth=cv2.CV_64F)[1:, 1:]

    def region_sum(ii, x1, y1, x2, y2):
        total = ii[y2, x2]
        if x1 > 0:
            total -= ii[y2, x1 - 1]
        if y1 > 0:
            total -= ii[y1 - 1, x2]
        if x1 > 0 and y1 > 0:
            total += ii[y1 - 1, x1 - 1]
        return total

    min_var = None
    max_var = None
    min_coords = (horizontal_padding, vertical_padding)
    max_coords = (horizontal_padding, vertical_padding)

    area = region_width * region_height
    x_start = horizontal_padding
    y_start = vertical_padding
    x_end = w - region_width - horizontal_padding + 1
    y_end = h - region_height - vertical_padding + 1

    for y in range(y_start, max(y_start, y_end) + 1, stride):
        for x in range(x_start, max(x_start, x_end) + 1, stride):
            x2, y2 = x + region_width - 1, y + region_height - 1
            if x2 >= w or y2 >= h:
                continue
            s = region_sum(integral, x, y, x2, y2)
            s2 = region_sum(integral_sq, x, y, x2, y2)
            mean = s / area
            var = (s2 / area) - (mean**2)
            if min_var is None or var < min_var:
                min_var = var
                min_coords = (x, y)
            if max_var is None or var > max_var:
                max_var = var
                max_coords = (x, y)

    return max_coords if busiest else min_coords


def get_dominant_color(image_path, x, y, w, h):
    img = cv2.imread(image_path)
    if img is None:
        return [128, 128, 128]
    region = img[y : y + h, x : x + w]
    if region.size == 0:
        return [128, 128, 128]
    region = region.reshape((-1, 3))
    mean = np.mean(region, axis=0)
    return [int(x) for x in reversed(mean)]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("image_path")
    parser.add_argument("--screen-width", type=int, default=1920)
    parser.add_argument("--screen-height", type=int, default=1080)
    parser.add_argument("--width", type=int, default=300, help="Widget width")
    parser.add_argument("--height", type=int, default=200, help="Widget height")
    parser.add_argument("--stride", type=int, default=10)
    parser.add_argument("--busiest", action="store_true")
    args = parser.parse_args()

    coords = find_least_busy_region(
        args.image_path,
        region_width=args.width,
        region_height=args.height,
        screen_width=args.screen_width,
        screen_height=args.screen_height,
        stride=args.stride,
        busiest=args.busiest,
    )

    center_x = coords[0] + args.width // 2
    center_y = coords[1] + args.height // 2
    dominant = get_dominant_color(
        args.image_path, coords[0], coords[1], args.width, args.height
    )

    print(
        json.dumps(
            {
                "center_x": center_x,
                "center_y": center_y,
                "dominant_color": dominant,
            }
        )
    )


if __name__ == "__main__":
    main()
