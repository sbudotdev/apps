#!/usr/bin/env python3
"""Sbu Seasons: crea i suoni dell'app con sola sintesi (libreria standard).

Uso: python3 Tools/make_sounds.py [cartella di uscita], da Apps/SbuSeasons (default SbuSeasons/Sounds).
I nomi sono quelli che SoundBoard.play(_:) cerca nel bundle.
Suoni brevi: mono 16 bit 44,1 kHz, sotto 1 s e 100 KB.
Sottofondi in loop: mono 16 bit 22,05 kHz, 16 s, giunta senza stacco.
"""
import math
import os
import random
import struct
import sys
import wave

SR = 44100
LOOP_SR = 22050
TAU = 2 * math.pi


# ---------- mattoni ----------

def silence(sec, sr=SR):
    return [0.0] * int(sec * sr)


def noise(n, rng):
    return [rng.uniform(-1, 1) for _ in range(n)]


def brown(n, rng):
    out, y = [], 0.0
    for _ in range(n):
        y = (y + rng.uniform(-1, 1) * 0.02) * 0.998
        out.append(y)
    return normalize(out, 1.0)


def lowpass(x, cutoff, sr=SR):
    a = 1 - math.exp(-TAU * cutoff / sr)
    y, out = 0.0, []
    for s in x:
        y += a * (s - y)
        out.append(y)
    return out


def highpass(x, cutoff, sr=SR):
    lp = lowpass(x, cutoff, sr)
    return [s - l for s, l in zip(x, lp)]


def bandpass(x, center, q=1.0, sr=SR):
    """Biquad RBJ; `center` è un numero o una funzione del tempo (s)."""
    f = center if callable(center) else (lambda t: center)
    out, x1, x2, y1, y2 = [], 0.0, 0.0, 0.0, 0.0
    b0 = b2 = a1 = a2 = 0.0
    for i, s in enumerate(x):
        if i % 32 == 0:
            w = TAU * min(f(i / sr), sr * 0.45) / sr
            alpha = math.sin(w) / (2 * q)
            a0 = 1 + alpha
            b0, b2 = alpha / a0, -alpha / a0
            a1, a2 = -2 * math.cos(w) / a0, (1 - alpha) / a0
        y = b0 * s + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, s, y1, y
        out.append(y)
    return out


def env(n, attack, decay, sr=SR, curve=4.0):
    """Attacco lineare, coda esponenziale fino a ~0 alla fine."""
    a = max(1, int(attack * sr))
    out = []
    for i in range(n):
        if i < a:
            out.append(i / a)
        else:
            t = (i - a) / max(1, n - a)
            out.append(math.exp(-curve * t / max(decay, 1e-3)) * (1 - t))
    return out


def mul(x, e):
    return [a * b for a, b in zip(x, e)]


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, s in enumerate(t):
            out[i] += s
    return out


def place(track, clip, at, sr=SR):
    start = int(at * sr)
    for i, s in enumerate(clip):
        if start + i < len(track):
            track[start + i] += s
    return track


def tone(freq, sec, partials=((1, 1.0),), decay=0.3, attack=0.004, sr=SR):
    n = int(sec * sr)
    out = [0.0] * n
    for ratio, amp in partials:
        f = freq * ratio
        if f >= sr / 2:
            continue
        d = decay / (ratio ** 0.5)
        for i in range(n):
            t = i / sr
            out[i] += amp * math.sin(TAU * f * t) * math.exp(-t / d)
    a = int(attack * sr)
    for i in range(min(a, n)):
        out[i] *= i / a
    return out


def fade(x, fin=0.005, fout=0.02, sr=SR):
    x = list(x)
    a, b = int(fin * sr), int(fout * sr)
    for i in range(min(a, len(x))):
        x[i] *= i / a
    for i in range(min(b, len(x))):
        x[-1 - i] *= i / b
    return x


def normalize(x, peak=0.8):
    m = max(abs(s) for s in x) or 1.0
    return [s * peak / m for s in x]


def note(name):
    names = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    return 440 * 2 ** ((names[name[0]] + 12 * (int(name[-1]) + 1) - 69) / 12)


GLASS = ((1, 1.0), (2.76, 0.35), (5.40, 0.15), (8.93, 0.06))
BELL = ((1, 1.0), (2.0, 0.4), (3.0, 0.2), (4.2, 0.1))


# ---------- suoni ----------

def snow_step(seed):
    rng = random.Random(seed)
    dur = 0.22 + 0.05 * (seed % 3)
    n = int(dur * SR)
    out = [0.0] * n
    for _crystal in range(140 + 30 * (seed % 3)):
        at = rng.betavariate(2, 3) * dur * 0.9
        g = int(rng.uniform(0.002, 0.006) * SR)
        grain = mul(noise(g, rng), env(g, 0.0005, 0.3))
        place(out, [s * rng.uniform(0.3, 1) for s in grain], at)
    out = bandpass(out, 1800 + 500 * (seed % 3), q=0.7)
    body = mul(lowpass(noise(n, rng), 300), env(n, 0.01, 0.25))
    return fade(normalize(mix(out, [s * 0.5 for s in body]), 0.7))


def snowball_throw():
    rng = random.Random(10)
    n = int(0.38 * SR)
    sweep = lambda t: 350 + 1400 * math.sin(math.pi * min(t / 0.38, 1)) ** 2
    w = bandpass(noise(n, rng), sweep, q=1.6)
    bell = [math.sin(math.pi * i / n) ** 2 for i in range(n)]
    return fade(normalize(mul(w, bell), 0.6))


def snowball_hit():
    rng = random.Random(11)
    n = int(0.32 * SR)
    thud = mul(lowpass(noise(n, rng), 180), env(n, 0.002, 0.12))
    thud = mix(thud, mul(tone(85, 0.32, decay=0.06), [0.4] * n))
    crunch = snow_step(4)[: n]
    return fade(normalize(mix(normalize(thud, 1.0), [s * 0.45 for s in crunch]), 0.8))


def snowman_done():
    out = silence(0.9)
    for k, nm in enumerate(["C5", "E5", "G5", "C6"]):
        place(out, [s * (0.7 + 0.1 * k) for s in tone(note(nm), 0.9 - 0.1 * k, BELL, decay=0.25)], 0.1 * k)
    return fade(normalize(out, 0.7), fout=0.08)


def snowglobe_shake():
    rng = random.Random(12)
    out = silence(0.9)
    for shake in range(3):
        g = int(0.12 * SR)
        sh = mul(highpass(noise(g, rng), 4000), env(g, 0.02, 0.35))
        place(out, [s * 0.5 for s in sh], 0.03 + 0.15 * shake)
    for _sparkle in range(14):
        f = rng.uniform(2600, 5200)
        place(out, [s * 0.25 for s in tone(f, 0.25, decay=0.05)], rng.uniform(0.05, 0.7))
    return fade(normalize(out, 0.6), fout=0.1)


def snowplow():
    rng = random.Random(13)
    n = int(0.95 * SR)
    motor = [0.0] * n
    for i in range(n):
        t = i / SR
        f = 55 + 4 * math.sin(TAU * 3 * t)
        motor[i] = sum(math.sin(TAU * f * h * t) / h for h in range(1, 7))
    motor = lowpass(motor, 400)
    scrape = bandpass(noise(n, rng), 2200, q=0.6)
    sw = [min(1, i / (0.15 * SR)) * min(1, (n - i) / (0.25 * SR)) for i in range(n)]
    return fade(normalize(mul(mix(normalize(motor, 1), [s * 0.5 for s in normalize(scrape, 1)]), sw), 0.6))


def sled():
    rng = random.Random(14)
    n = int(0.9 * SR)
    hiss = bandpass(noise(n, rng), lambda t: 2600 - 900 * t, q=0.8)
    rumble = lowpass(noise(n, rng), 120)
    sw = [math.sin(math.pi * i / n) ** 1.5 for i in range(n)]
    return fade(normalize(mul(mix(normalize(hiss, 1), [s * 0.4 for s in normalize(rumble, 1)]), sw), 0.6))


def cablecar_latch():
    rng = random.Random(15)
    out = silence(0.55)
    metal = ((1, 1.0), (2.58, 0.6), (4.25, 0.4), (6.1, 0.2))
    for at, f, g in ((0.0, 520, 0.7), (0.13, 610, 1.0)):
        click = mul(highpass(noise(int(0.01 * SR), rng), 1500), env(int(0.01 * SR), 0.0005, 0.2))
        place(out, [s * g for s in click], at)
        place(out, [s * g * 0.5 for s in tone(f, 0.4, metal, decay=0.07, attack=0.001)], at)
    clunk = mul(lowpass(noise(int(0.2 * SR), rng), 150), env(int(0.2 * SR), 0.002, 0.15))
    place(out, normalize(clunk, 0.6), 0.13)
    return fade(normalize(out, 0.75), fout=0.05)


def ornament(nm):
    return fade(normalize(tone(note(nm), 0.7, GLASS, decay=0.22, attack=0.001), 0.6), fout=0.05)


def sleigh_bells():
    rng = random.Random(16)
    out = silence(0.95)
    for beat in range(8):
        at = 0.02 + beat * 0.11 + rng.uniform(-0.01, 0.01)
        for _ in range(3):
            f = rng.uniform(2400, 4200)
            place(out, [s * rng.uniform(0.2, 0.4) for s in tone(f, 0.18, ((1, 1), (1.5, 0.4), (2.4, 0.2)), decay=0.05, attack=0.001)], at + rng.uniform(0, 0.015))
        sh = mul(highpass(noise(int(0.04 * SR), rng), 5000), env(int(0.04 * SR), 0.001, 0.2))
        place(out, [s * 0.15 for s in sh], at)
    return fade(normalize(out, 0.6), fout=0.12)


def gift_open():
    rng = random.Random(17)
    out = silence(0.9)
    n = int(0.42 * SR)
    am = [abs(math.sin(TAU * 18 * i / SR + rng.uniform(0, 0.3))) ** 3 for i in range(n)]
    paper = mul(mul(bandpass(noise(n, rng), 3000, q=0.5), am), env(n, 0.01, 0.6))
    place(out, normalize(paper, 0.6), 0.0)
    for k, nm in enumerate(["G5", "C6", "E6"]):
        place(out, [s * 0.35 for s in tone(note(nm), 0.45, BELL, decay=0.15)], 0.4 + 0.07 * k)
    return fade(normalize(out, 0.7), fout=0.08)


def gingerbread_run():
    rng = random.Random(18)
    out = silence(0.8)
    at, gap = 0.0, 0.085
    for step in range(7):
        f = 700 + 60 * (step % 2) + 20 * step
        place(out, [s * 0.5 for s in tone(f, 0.05, ((1, 1), (2, 0.3)), decay=0.012, attack=0.001)], at)
        at += gap
        gap *= 0.88
    n = int(0.3 * SR)
    ph, whistle = 0.0, []
    for i in range(n):  # fischietto che sale: se l'è svignata
        t = i / n
        ph += TAU * (900 + 1300 * t * t) / SR
        whistle.append(math.sin(ph) * math.sin(math.pi * t) * 0.35)
    place(out, whistle, at + 0.02)
    return fade(normalize(out, 0.65), fout=0.05)


def fireplace():
    rng = random.Random(19)
    n = int(0.95 * SR)
    bed = lowpass(brown(n, rng), 600)
    out = [s * 0.35 for s in bed]
    for _crackle in range(26):
        g = int(rng.uniform(0.002, 0.008) * SR)
        pop = bandpass(mul(noise(g, rng), env(g, 0.0003, 0.2)), rng.uniform(1500, 5000), q=1.5)
        place(out, [s * rng.uniform(0.6, 2.2) for s in pop], rng.uniform(0.02, 0.9))
    sw = [min(1, i / (0.1 * SR)) * min(1, (n - i) / (0.2 * SR)) for i in range(n)]
    return fade(normalize(mul(out, sw), 0.6))


def lantern():
    rng = random.Random(20)
    n = int(0.65 * SR)
    whoosh = mul(lowpass(noise(n, rng), 500), env(n, 0.06, 0.35))
    glow = mul(tone(note("A3"), 0.65, ((1, 1), (2, 0.3), (3, 0.1)), decay=0.5, attack=0.08), [0.25] * n)
    tick = [s * 0.3 for s in tone(note("E6"), 0.3, GLASS, decay=0.1, attack=0.001)]
    out = mix(normalize(whoosh, 0.7), glow)
    place(out, tick, 0.05)
    return fade(normalize(out, 0.6), fout=0.1)


def thunder_far():
    rng = random.Random(21)
    n = int(0.98 * SR)
    r = lowpass(lowpass(brown(n, rng), 140), 140)
    am = lowpass([abs(rng.gauss(0, 1)) for _ in range(n)], 6)
    e = [min(1, i / (0.12 * SR)) * math.exp(-2.2 * i / n) * (1 - i / n) for i in range(n)]
    return fade(normalize(mul(mul(r, normalize(am, 1)), e), 0.8), fin=0.02, fout=0.1)


# ---------- loop ----------

LOOP_SEC, XFADE = 16, 2.0


def seamless(make):
    """Genera LOOP+XFADE secondi e sfuma la coda nell'inizio: la giunta non si sente."""
    total = make(int((LOOP_SEC + XFADE) * LOOP_SR))
    n, x = int(LOOP_SEC * LOOP_SR), int(XFADE * LOOP_SR)
    out = total[:n]
    for i in range(x):
        a = math.sin(0.5 * math.pi * i / x) ** 2  # equal-power-ish su rumore scorrelato
        out[i] = total[n + i] * (1 - a) ** 0.5 + total[i] * a ** 0.5
    return normalize(out, 0.5)


def wind(n):
    rng = random.Random(30)
    src = noise(n, rng)
    center = lambda t: 380 + 220 * math.sin(TAU * t / 8) + 120 * math.sin(TAU * t / 3.2 + 1)
    w = bandpass(src, center, q=2.2, sr=LOOP_SR)
    gust = [0.55 + 0.3 * math.sin(TAU * i / LOOP_SR / 8) + 0.15 * math.sin(TAU * i / LOOP_SR / 2.7) for i in range(n)]
    low = lowpass(brown(n, rng), 200, sr=LOOP_SR)
    return mix(mul(normalize(w, 1), gust), [s * 0.3 for s in low])


def rain(n):
    rng = random.Random(31)
    bed = lowpass(highpass(noise(n, rng), 400, sr=LOOP_SR), 5000, sr=LOOP_SR)
    out = [s * 0.25 for s in bed]
    for _drop in range(int(n / LOOP_SR * 40)):
        g = int(0.006 * LOOP_SR)
        d = bandpass(mul(noise(g, rng), env(g, 0.0005, 0.2, sr=LOOP_SR)), rng.uniform(1800, 4500), q=2, sr=LOOP_SR)
        place(out, [s * rng.uniform(0.3, 1.0) for s in d], rng.uniform(0, n / LOOP_SR - 0.01), sr=LOOP_SR)
    return out


# ---------- scrittura e controlli ----------

def write(path, x, sr):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in x))


SHORT = {
    "passo-neve-1": lambda: snow_step(1),
    "passo-neve-2": lambda: snow_step(2),
    "passo-neve-3": lambda: snow_step(3),
    "palla-di-neve-lancio": snowball_throw,
    "palla-di-neve-colpo": snowball_hit,
    "pupazzo": snowman_done,
    "palla-di-vetro": snowglobe_shake,
    "spazzaneve": snowplow,
    "slittino": sled,
    "funivia": cablecar_latch,
    "pallina-1": lambda: ornament("G5"),
    "pallina-2": lambda: ornament("B5"),
    "pallina-3": lambda: ornament("D6"),
    "babbo-natale": sleigh_bells,
    "regalo": gift_open,
    "omino": gingerbread_run,
    "camino": fireplace,
    "lanterna": lantern,
    "tuono": thunder_far,
}
LOOPS = {"vento": wind, "pioggia": rain}


def main(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    for name, make in SHORT.items():
        x = make()
        p = os.path.join(out_dir, name + ".wav")
        write(p, x, SR)
        assert len(x) / SR < 1.0, name
        assert os.path.getsize(p) < 100_000, name
        assert max(abs(s) for s in x) > 0.1, name  # non muto
    for name, make in LOOPS.items():
        x = seamless(make)
        p = os.path.join(out_dir, name + ".wav")
        write(p, x, LOOP_SR)
        assert 10 <= len(x) / LOOP_SR <= 20, name
        # giunta: l'ultimo campione e il primo sono vicini quanto due campioni consecutivi
        steps = sorted(abs(x[i + 1] - x[i]) for i in range(len(x) - 1))
        assert abs(x[0] - x[-1]) <= steps[int(len(steps) * 0.999)], name
    print(f"{len(SHORT)} suoni brevi e {len(LOOPS)} loop in {out_dir}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "SbuSeasons", "Sounds"))
