#!/usr/bin/env python3
"""Synthesize placeholder key sounds for Sbu Keys: filtered noise plus a short body resonance.

shortcut: synthetic clicks until Matteo records a real mechanical keyboard; drop the recordings in
Apps/SbuKeys/SbuKeys/Sounds with the same names and stop running this script.

Usage: python3 Tools/make_key_sounds.py
Writes Apps/SbuKeys/SbuKeys/Sounds/<switch>-<key>-<down|up>.caf, 16-bit PCM, 44.1 kHz, mono.
Seeded, so the output is the same on every run. Needs macOS `afconvert`.
"""
import math
import random
import struct
import subprocess
import tempfile
import wave
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Apps" / "SbuKeys" / "SbuKeys" / "Sounds"
RATE = 44_100

# Switch: (noise brightness 0-1, body Hz, extra click peak for clicky switches).
SWITCHES = {"linear": (0.35, 210.0, 0.0), "tactile": (0.5, 260.0, 0.0), "clicky": (0.7, 300.0, 0.6)}
# Key: (length s, body Hz factor, loudness).
KEYS = {"key": (0.045, 1.0, 0.8), "space": (0.07, 0.6, 1.0), "enter": (0.06, 0.75, 0.95)}


def render(brightness: float, body: float, click: float, length: float, loud: float, seed: int) -> bytes:
    rng = random.Random(seed)
    frames = bytearray()
    low = 0.0
    for i in range(int((length + 0.02) * RATE)):
        t = i / RATE
        white = rng.uniform(-1, 1)
        low += (white - low) * (1 - brightness) * 0.9  # one-pole low-pass: darker switches keep less hiss
        noise = brightness * white + (1 - brightness) * low
        hit = noise * math.exp(-t / (length * 0.25))
        resonance = 0.6 * math.sin(2 * math.pi * body * t) * math.exp(-t / (length * 0.5))
        snap = click * math.sin(2 * math.pi * 4_200 * t) * math.exp(-t / 0.004)
        sample = loud * 0.7 * (hit + resonance + snap) * min(t / 0.0005, 1.0)
        frames += struct.pack("<h", int(max(-1.0, min(1.0, sample)) * 32_767))
    return bytes(frames)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as scratch:
        for s, (brightness, body, click) in SWITCHES.items():
            for k, (length, factor, loud) in KEYS.items():
                for phase in ("down", "up"):
                    # The release is shorter, quieter and has no click.
                    up = phase == "up"
                    data = render(brightness, body * factor * (1.3 if up else 1.0), 0.0 if up else click,
                                  length * (0.6 if up else 1.0), loud * (0.45 if up else 1.0),
                                  seed=zlib.crc32(f"{s}-{k}-{phase}".encode()))
                    name = f"{s}-{k}-{phase}"
                    wav = Path(scratch) / f"{name}.wav"
                    with wave.open(str(wav), "wb") as file:
                        file.setnchannels(1)
                        file.setsampwidth(2)
                        file.setframerate(RATE)
                        file.writeframes(data)
                    caf = OUT / f"{name}.caf"
                    subprocess.run(["afconvert", "-f", "caff", "-d", "LEI16", str(wav), str(caf)], check=True)
                    print(f"wrote {caf.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
