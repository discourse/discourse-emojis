"""Encode a Google animated WebP as a 128px AVIF (requires Pillow 13.0.0)."""

import argparse

from PIL import Image, ImageSequence


def encode(source, target):
    frames = []
    durations = []
    with Image.open(source) as image:
        for frame in ImageSequence.Iterator(image):
            frames.append(
                frame.convert("RGBA").resize((128, 128), Image.Resampling.LANCZOS)
            )
            durations.append(image.info["duration"])

    frames[0].save(
        target,
        save_all=True,
        append_images=frames[1:],
        duration=durations,
        quality=50,
        speed=2,
        subsampling="4:4:4",
        max_threads=1,
        codec="aom",
    )

    with Image.open(target) as image:
        if image.size != (128, 128) or image.n_frames != len(frames):
            raise ValueError("Encoded animation dimensions or frame count changed")
        total_duration = 0
        for frame in ImageSequence.Iterator(image):
            frame.load()
            total_duration += image.info["duration"]
        if total_duration != sum(durations):
            raise ValueError("Encoded animation duration changed")
        if image.mode != "RGBA":
            raise ValueError("Encoded animation lost its alpha channel")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source")
    parser.add_argument("target")
    args = parser.parse_args()
    encode(args.source, args.target)
