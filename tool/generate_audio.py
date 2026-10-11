#!/usr/bin/env python3
"""Generates original, seamlessly loopable ambient sounds for LunaNest.

All sounds are synthesized from random noise and math by this script, so they
are original works released under CC0 1.0 by the project author. Every signal is
built in the frequency domain / with circular convolution, so each 20 s file
loops without a seam.

Usage: python3 tool/generate_audio.py [output_dir]   (requires numpy)
"""
import os
import sys
import wave

import numpy as np

SR = 22050
DUR = 20
N = SR * DUR
T = np.arange(N) / SR
FREQS = np.fft.rfftfreq(N, 1 / SR)
F = np.maximum(FREQS, 1.0)
rng = np.random.default_rng(20240607)


def shaped(mag):
    mag = np.array(mag, dtype=float)
    mag[0] = 0.0
    phase = rng.uniform(0, 2 * np.pi, len(FREQS))
    x = np.fft.irfft(mag * np.exp(1j * phase), n=N)
    return unit(x)


def unit(x):
    x = x - np.mean(x)
    return x / (np.std(x) + 1e-12)


def lp(fc, n=2):
    return 1 / np.sqrt(1 + (F / fc) ** (2 * n))


def hp(fc, n=2):
    return 1 / np.sqrt(1 + (fc / F) ** (2 * n))


def bp(lo, hi, n=2):
    return hp(lo, n) * lp(hi, n)


def white():
    return shaped(np.ones_like(F) * lp(10000, 3))


def pink():
    return shaped(1 / np.sqrt(F) * hp(20) * lp(10000, 3))


def brown():
    return shaped(1 / F * hp(25) * lp(9000, 2))


def burst(ms, lo, hi, decay_ms):
    n = int(SR * ms / 1000)
    t = np.arange(n) / SR
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / SR)
    spec *= (f >= lo) & (f <= hi)
    b = np.fft.irfft(spec, n=n) * np.exp(-t / (decay_ms / 1000))
    return b / (np.max(np.abs(b)) + 1e-12)


def drops(rate, kernels, amp_sigma=0.5):
    out = np.zeros(N)
    per = max(1, int(rate * DUR / len(kernels)))
    for k in kernels:
        idx = rng.integers(0, N, per)
        amps = rng.lognormal(0, amp_sigma, per)
        imp = np.zeros(N)
        np.add.at(imp, idx, amps)
        kk = np.zeros(N)
        kk[: len(k)] = k
        out += np.fft.irfft(np.fft.rfft(imp) * np.fft.rfft(kk), n=N)
    return unit(out)


def circ_bump(center, width):
    d = np.abs(T - center)
    d = np.minimum(d, DUR - d)
    return np.exp(-((d / width) ** 2))


def gentle_rain():
    base = shaped(1 / np.sqrt(F) * bp(500, 7000))
    d = drops(60, [burst(25, 2000, 6000, 5), burst(18, 3000, 8000, 3), burst(35, 1200, 4000, 8)])
    return 0.6 * base + 0.35 * d


def heavy_rain():
    base = shaped(bp(250, 9000))
    low = shaped(1 / np.sqrt(F) * lp(300) * hp(40))
    d = drops(380, [burst(20, 1500, 8000, 4), burst(15, 2500, 9000, 2.5), burst(30, 800, 4000, 7)], 0.4)
    return 0.8 * base + 0.35 * low + 0.45 * d


def distant_thunder():
    rumble = shaped(1 / F * lp(95, 2) * hp(18))
    mid = shaped(1 / np.sqrt(F) * bp(70, 500))
    env = 0.06 + 0.9 * circ_bump(4.5, 1.7) + 0.7 * circ_bump(13.5, 2.2) + 0.25 * circ_bump(16.5, 1.0)
    return rumble * env + 0.35 * mid * env ** 2


def ocean(period, lo_cut, hi_cut, hiss):
    phase = 2 * np.pi * T / period
    sw = ((1 + np.sin(phase - np.pi / 2)) / 2) ** 1.8
    sw_hi = np.roll(sw, int(SR * 0.7))
    low = shaped(1 / F * lp(lo_cut) * hp(25)) * (0.25 + 0.75 * sw)
    hi = shaped(1 / np.sqrt(F) * bp(700, hi_cut)) * (0.04 + hiss * sw_hi)
    return low + hi


def soft_wind():
    body = shaped(1 / np.sqrt(F) * bp(110, 1400))
    env = 0.6 + 0.3 * np.sin(2 * np.pi * T / 20 + 1.0) + 0.2 * np.sin(2 * np.pi * 3 * T / 20 + 2.0)
    return body * env


def fireplace():
    bed = shaped(1 / F * lp(450) * hp(30)) * 0.5
    crackle = drops(14, [burst(40, 800, 6000, 10), burst(25, 1200, 7000, 6)], 0.9)
    pops = drops(2.5, [burst(8, 1500, 9000, 2.0)], 0.8)
    return bed + 0.6 * crackle + 0.5 * pops


def crickets():
    sig = np.zeros(N)
    for freq, reps, off, amp in [(4300, 40, 0.0, 1.0), (4800, 37, 0.13, 0.8), (5200, 33, 0.31, 0.6)]:
        period = DUR / reps
        for k in range(reps):
            a = amp * rng.uniform(0.85, 1.0)
            for p in range(4):
                start = k * period + off + p * 0.040
                n = int(SR * 0.022)
                tt = np.arange(n) / SR
                pulse = np.sin(2 * np.pi * freq * tt) * np.hanning(n) * a
                idx = (int(start * SR) + np.arange(n)) % N
                sig[idx] += pulse
    bed = shaped(1 / np.sqrt(F) * bp(200, 3000))
    return unit(sig) * 0.9 + 0.12 * bed


def forest_stream():
    mod = shaped(lp(14) * hp(1.5))
    env = np.clip(0.75 + 0.25 * mod, 0.2, None)
    body = shaped(1 / np.sqrt(F) * bp(300, 6500)) * env
    bubbles = drops(55, [burst(30, 800, 3000, 10), burst(22, 1200, 4000, 7)], 0.6)
    return 0.8 * body + 0.3 * bubbles


SOUNDS = {
    "white_noise": white,
    "pink_noise": pink,
    "brown_noise": brown,
    "gentle_rain": gentle_rain,
    "heavy_rain": heavy_rain,
    "distant_thunder": distant_thunder,
    "ocean_waves": lambda: ocean(10, 450, 4500, 0.55),
    "ocean_night": lambda: ocean(20, 260, 1900, 0.35),
    "soft_wind": soft_wind,
    "forest_stream": forest_stream,
    "night_crickets": crickets,
    "fireplace": fireplace,
}


def finalize(x, target_rms=0.16, peak=0.92):
    x = x - np.mean(x)
    k = 3.0 * np.sqrt(np.mean(x ** 2)) + 1e-12
    x = k * np.tanh(x / k)  # soft-limit rare loud transients (crackles, drops)
    x = x * (target_rms / (np.sqrt(np.mean(x ** 2)) + 1e-12))
    m = np.max(np.abs(x))
    if m > peak:
        x *= peak / m
    return x


def write_wav(path, x):
    pcm = np.clip(x * 32767, -32768, 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
    os.makedirs(out, exist_ok=True)
    for name, fn in SOUNDS.items():
        x = finalize(fn())
        seam = abs(x[0] - x[-1]) / (np.std(np.diff(x)) + 1e-12)
        path = os.path.join(out, name + ".wav")
        write_wav(path, x)
        print(f"{name:16s} {os.path.getsize(path)/1e6:5.2f} MB  rms={np.sqrt(np.mean(x**2)):.3f}  "
              f"peak={np.max(np.abs(x)):.2f}  seam_ratio={seam:.2f}")


if __name__ == "__main__":
    main()
