#!/usr/bin/env python3
"""Generates original, seamlessly loopable ambient sounds for LunaNest (requires numpy).

Every sound is synthesized from random noise and math by this script, so all audio is original
and released under CC0 1.0 by the project author. Each file is 20 s, 22.05 kHz, 16-bit mono and
loops without a seam: noise is built in the frequency domain, modulations use whole numbers of
cycles per loop, and events are placed with wrap-around.

Sleep-friendly design rules used throughout:
  * every transient (drop, crackle, pop) has a soft attack and band-limited spectrum;
  * a gentle per-sound low-pass removes harsh high frequencies;
  * a soft limiter rounds off rare loud peaks instead of letting them sound like clicks.

Usage: python3 tool/generate_audio.py [output_dir]
"""
import os
import sys
import wave
import zlib

import numpy as np

SR = 22050
DUR = 20
N = SR * DUR
T = np.arange(N) / SR
FREQS = np.fft.rfftfreq(N, 1 / SR)
F = np.maximum(FREQS, 1.0)
rng = np.random.default_rng(0)


def seed_for(name):
    """Each sound has its own stable random stream, so adding sounds never changes others."""
    global rng
    rng = np.random.default_rng(zlib.crc32(name.encode()))


# --------------------------------------------------------------------------- primitives
def unit(x):
    x = x - np.mean(x)
    return x / (np.std(x) + 1e-12)


def shaped(mag):
    mag = np.array(mag, dtype=float)
    mag[0] = 0.0
    phase = rng.uniform(0, 2 * np.pi, len(FREQS))
    return unit(np.fft.irfft(mag * np.exp(1j * phase), n=N))


def lp(fc, n=2):
    return 1 / np.sqrt(1 + (F / fc) ** (2 * n))


def hp(fc, n=2):
    return 1 / np.sqrt(1 + (fc / F) ** (2 * n))


def bp(lo, hi, n=2):
    return hp(lo, n) * lp(hi, n)


def cyc(n, phase=0.0):
    """Sine with exactly n cycles per loop (keeps modulation seamless)."""
    return np.sin(2 * np.pi * n * T / DUR + phase)


def smooth_env(fc, depth, floor=0.15):
    """Slow random loudness variation (positive), low-pass noise around 1."""
    m = shaped(lp(fc, 2) * hp(max(fc / 20, 0.05), 1))
    return np.clip(1 + depth * m, floor, None)


def tone(freq, harmonics=(1,), amps=None):
    """Steady hum. Frequencies snap to whole cycles per loop so the loop is seamless."""
    amps = amps or [1.0 / (i + 1) for i in range(len(harmonics))]
    out = np.zeros(N)
    for h, a in zip(harmonics, amps):
        f = round(freq * h * DUR) / DUR
        out += a * np.sin(2 * np.pi * f * T + rng.uniform(0, 2 * np.pi))
    return out


def band_noise(n, lo, hi):
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.maximum(np.fft.rfftfreq(n, 1 / SR), 1.0)
    mask = 1 / np.sqrt(1 + (f / hi) ** 4) / np.sqrt(1 + (lo / f) ** 4)
    return unit(np.fft.irfft(spec * mask, n=n))


def burst(ms, lo, hi, decay_ms, attack_ms=2.0):
    """Soft transient: band-limited noise, smooth attack, exponential decay."""
    n = int(SR * ms / 1000)
    t = np.arange(n) / SR
    b = band_noise(n, lo, hi) * np.exp(-t / (decay_ms / 1000)) * np.minimum(1.0, t / (attack_ms / 1000))
    return b / (np.max(np.abs(b)) + 1e-12)


def stamp(sig, kernel, pos, amp=1.0):
    idx = (int(pos) + np.arange(len(kernel))) % N  # wrap-around keeps loops seamless
    sig[idx] += amp * kernel


def drops(rate, kernels, sigma=0.35):
    """Dense texture of overlapping soft events (unit RMS)."""
    out = np.zeros(N)
    per = max(1, int(rate * DUR / len(kernels)))
    for k in kernels:
        amps = rng.lognormal(0, sigma, per)
        for pos, a in zip(rng.integers(0, N, per), amps):
            stamp(out, k, pos, a)
    return unit(out)


def sparks(rate, kernels, sigma=0.5):
    """Sparse individual events (NOT normalised: peaks stay near 1)."""
    out = np.zeros(N)
    per = max(1, int(round(rate * DUR / len(kernels))))
    for k in kernels:
        amps = rng.lognormal(0, sigma, per)
        amps = np.minimum(amps, 2.0) / 2.0
        for pos, a in zip(rng.integers(0, N, per), amps):
            stamp(out, k, pos, a)
    return out


def circ_bump(center, width):
    d = np.abs(T - center)
    d = np.minimum(d, DUR - d)
    return np.exp(-((d / width) ** 2))


def white():
    return shaped(np.ones_like(F) * lp(9000, 3))


def pink():
    return shaped(F ** -0.5 * hp(20) * lp(9500, 3))


def brown():
    return shaped(F ** -1.0 * hp(25) * lp(8000, 2))


def wind(lo=110, hi=1400, c1=1, c2=3, base=0.6, a1=0.3, a2=0.2):
    body = shaped(F ** -0.5 * bp(lo, hi))
    return body * (base + a1 * cyc(c1, 1.0) + a2 * cyc(c2, 2.0))


def rustle_env(rate_hz):
    m = shaped(lp(rate_hz, 2) * hp(0.4, 1))
    e = np.clip(m + 1.1, 0, None) ** 2
    return e / np.mean(e)


def thunder_rumble(peaks, lpcut=95):
    rumble = shaped(F ** -1.0 * lp(lpcut, 2) * hp(18))
    mid = shaped(F ** -0.5 * bp(60, 520))
    env = 0.05 + sum(a * circ_bump(c, w) for c, a, w in peaks)
    return rumble * env + 0.3 * mid * env ** 2


def ocean(cycles, lo_cut, hi_cut, hiss, sharp=1.8, lag=0.7):
    phase = 2 * np.pi * cycles * T / DUR
    sw = ((1 + np.sin(phase - np.pi / 2)) / 2) ** sharp
    sw_hi = np.roll(sw, int(SR * lag))
    low = shaped(F ** -1.0 * lp(lo_cut) * hp(25)) * (0.25 + 0.75 * sw)
    hi = shaped(F ** -0.5 * bp(600, hi_cut)) * (0.04 + hiss * sw_hi)
    return low + hi


# --------------------------------------------------------------------------- rain & thunder
SOFT_DROPS = lambda: [burst(30, 1400, 4200, 9), burst(24, 1800, 5000, 6), burst(40, 900, 3200, 12)]


def gentle_rain():
    return 0.7 * shaped(F ** -0.5 * bp(400, 5200)) + 0.22 * drops(45, SOFT_DROPS(), 0.35)


def heavy_rain():
    base = shaped(bp(180, 6200))
    low = shaped(F ** -0.5 * lp(280) * hp(40))
    d = drops(240, [burst(24, 1200, 5200, 6), burst(18, 1600, 6000, 4), burst(34, 700, 3500, 9)], 0.3)
    return 0.85 * base + 0.35 * low + 0.3 * d


def distant_thunder():
    return thunder_rumble([(4.5, 0.9, 1.7), (13.5, 0.7, 2.2), (16.5, 0.25, 1.0)])


def soft_drizzle():
    base = shaped(F ** -0.4 * bp(700, 4800)) * smooth_env(0.6, 0.25)
    return 0.55 * base + 0.18 * drops(22, [burst(22, 1800, 4800, 6), burst(18, 2200, 5200, 4)], 0.3)


def rain_on_window():
    base = shaped(F ** -0.5 * bp(450, 3200)) * smooth_env(0.5, 0.2)
    ticks = drops(60, [burst(14, 1100, 3000, 5), burst(10, 1500, 3600, 4)], 0.4)
    drips = sparks(1.2, [burst(60, 500, 1500, 28, 2.5)], 0.5)
    return 0.55 * base + 0.28 * ticks + 0.5 * drips


def rain_on_leaves():
    base = shaped(F ** -0.3 * bp(1200, 5500)) * smooth_env(0.7, 0.2)
    d = drops(140, [burst(16, 2000, 5200, 5), burst(12, 2500, 5500, 3.5), burst(22, 1400, 4200, 7)], 0.45)
    return 0.45 * base + 0.5 * d


def light_shower():
    return 0.8 * shaped(F ** -0.4 * bp(300, 5600)) + 0.3 * drops(110, SOFT_DROPS(), 0.35)


def forest_rain():
    base = shaped(F ** -0.5 * bp(350, 4800)) * smooth_env(0.4, 0.15)
    big = sparks(5, [burst(45, 500, 1700, 24, 2.5), burst(35, 700, 2200, 18, 2.0)], 0.5)
    canopy = shaped(F ** -0.5 * bp(120, 900)) * (0.5 + 0.3 * cyc(1, 0.7) + 0.15 * cyc(3, 1.9))
    return 0.6 * base + 0.3 * drops(70, [burst(26, 1400, 4200, 8)], 0.35) + 0.45 * big + 0.3 * canopy


def rain_soft_wind():
    return 0.7 * gentle_rain() + 0.5 * wind(100, 1000, 1, 3, 0.65, 0.2, 0.15)


def thunderstorm():
    storm = thunder_rumble([(5.0, 0.8, 1.6), (12.5, 1.0, 2.0), (17.0, 0.5, 1.1)])
    return 0.8 * heavy_rain() + 1.6 * storm


def close_thunder():
    rolls = thunder_rumble([(4.0, 1.0, 1.1), (5.6, 0.6, 1.8), (14.0, 0.9, 1.4)], lpcut=140)
    crack = np.zeros(N)
    for c in (4.0, 14.0):
        stamp(crack, burst(220, 50, 1100, 70, 4.0), c * SR, 1.0)
    return 0.35 * light_shower() + 1.5 * rolls + 1.2 * crack


# --------------------------------------------------------------------------- ocean
def ocean_waves():
    return ocean(2, 450, 4500, 0.55)


def ocean_night():
    return ocean(1, 260, 1900, 0.35)


def soft_beach_waves():
    return ocean(3, 350, 3500, 0.40, sharp=1.6)


def deep_ocean():
    return ocean(1, 150, 900, 0.15, sharp=1.4)


def tide_pool():
    water = sparks(14, [burst(40, 500, 2200, 16, 2.5), burst(30, 700, 2600, 12, 2.0)], 0.5)
    return 0.6 * ocean(4, 300, 2500, 0.30) + 0.5 * water


def rocky_shore():
    splash = sparks(5, [burst(70, 700, 3200, 32, 3.0)], 0.5)
    return ocean(2, 600, 4800, 0.80, sharp=2.6) + 0.4 * splash


def distant_surf():
    return ocean(2, 220, 1400, 0.25, sharp=1.6, lag=1.0)


def underwater_soft():
    body = shaped(F ** -1.0 * lp(380) * hp(25)) * (0.7 + 0.2 * cyc(1, 0.3) + 0.15 * cyc(3, 2.0))
    bubbles = sparks(2, [burst(130, 250, 800, 55, 8.0)], 0.5)
    return body + 0.5 * bubbles


def night_tide():
    return ocean(1, 300, 1500, 0.25) + 0.15 * wind(120, 900, 1, 2, 0.7, 0.2, 0.1)


# --------------------------------------------------------------------------- wind & nature
def soft_wind():
    return wind(110, 1400, 1, 3, 0.6, 0.3, 0.2)


def strong_wind():
    roar = shaped(F ** -1.0 * bp(40, 300))
    return wind(70, 1900, 2, 5, 0.65, 0.3, 0.25) + 0.4 * roar


def wind_in_trees():
    leaves = shaped(F ** -0.3 * bp(1500, 4800)) * rustle_env(6) * (0.3 + 0.3 * cyc(1, 1.0))
    return wind(110, 1300, 1, 3, 0.6, 0.3, 0.2) + 0.5 * leaves


def mountain_breeze():
    body = shaped(F ** -0.6 * bp(220, 2800)) * (0.55 + 0.25 * cyc(1, 0.9) + 0.15 * cyc(2, 2.2))
    return body + 0.2 * shaped(bp(1500, 4000)) * smooth_env(0.5, 0.3)


def forest_stream():
    env = smooth_env(14, 0.25, 0.2)
    body = shaped(F ** -0.5 * bp(300, 5200)) * env
    return 0.8 * body + 0.3 * drops(55, [burst(30, 800, 2800, 10), burst(22, 1200, 3600, 7)], 0.5)


def creek():
    body = shaped(F ** -0.5 * bp(400, 4800)) * smooth_env(10, 0.3, 0.25)
    return 0.8 * body + 0.3 * drops(35, [burst(34, 700, 2600, 10), burst(26, 900, 3000, 8)], 0.5)


def river_rapids():
    body = shaped(F ** -0.3 * bp(200, 6000)) * smooth_env(8, 0.35, 0.25)
    roar = shaped(F ** -0.7 * bp(50, 450))
    return 0.85 * body + 0.55 * roar + 0.2 * drops(120, [burst(28, 600, 3000, 8)], 0.4)


def night_crickets():
    sig = np.zeros(N)
    for freq, reps, off, amp in [(3600, 40, 0.0, 1.0), (4000, 37, 0.13, 0.8), (4400, 33, 0.31, 0.6)]:
        period = DUR / reps
        for k in range(reps):
            a = amp * rng.uniform(0.85, 1.0)
            for p in range(4):
                n = int(SR * 0.026)
                pulse = np.sin(2 * np.pi * freq * np.arange(n) / SR) * np.hanning(n) * a
                stamp(sig, pulse, (k * period + off + p * 0.040) * SR)
    bed = shaped(F ** -0.5 * bp(200, 2800))
    return unit(sig) * 0.7 + 0.14 * bed


def frogs_night():
    sig = np.zeros(N)
    for f0, reps, off, amp in [(330, 11, 0.7, 1.0), (410, 7, 2.1, 0.8), (270, 13, 0.2, 0.7)]:
        period = DUR / reps
        for k in range(reps):
            start = k * period + off + rng.uniform(-0.15, 0.15)
            pulses = int(rng.integers(5, 9))
            rate = 16 + rng.uniform(-2, 2)
            for p in range(pulses):
                n = int(SR * 0.034)
                fr = f0 * (1.0 - 0.04 * p / pulses)
                pulse = np.sin(2 * np.pi * fr * np.arange(n) / SR) * np.hanning(n) * amp
                stamp(sig, pulse, (start + p / rate) * SR, 0.8 + 0.2 * np.sin(np.pi * p / pulses))
    return unit(sig) * 0.75 + 0.3 * shaped(F ** -0.7 * bp(80, 1200)) * smooth_env(0.4, 0.2)


def _chirp(f1, f2, ms):
    n = int(SR * ms / 1000)
    t = np.linspace(0, 1, n)
    f = f1 + (f2 - f1) * t ** 1.2
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.hanning(n)


def birds_dusk():
    sig = np.zeros(N)
    for b in range(4):
        base = rng.uniform(2200, 3400)
        for _ in range(int(rng.integers(9, 14))):
            start = rng.uniform(0, DUR)
            for j in range(int(rng.integers(2, 5))):
                f1 = base * rng.uniform(0.9, 1.15)
                c = _chirp(f1, f1 * rng.uniform(0.85, 1.3), rng.uniform(60, 120))
                stamp(sig, c, (start + j * 0.13) * SR, rng.uniform(0.4, 1.0) * (0.5 + 0.1 * b))
    return 0.9 * sig + 0.3 * shaped(F ** -0.6 * bp(250, 2400)) * smooth_env(0.5, 0.3)


def bamboo_forest():
    air = shaped(F ** -0.5 * bp(250, 3200)) * (0.55 + 0.25 * cyc(1, 0.4) + 0.15 * cyc(4, 1.1))
    sig = np.zeros(N)
    for _ in range(10):
        n = int(SR * 0.25)
        t = np.arange(n) / SR
        k = np.sin(2 * np.pi * rng.uniform(420, 820) * t) * np.exp(-t / rng.uniform(0.055, 0.11)) * np.minimum(1, t / 0.003)
        stamp(sig, k, rng.uniform(0, DUR) * SR, rng.uniform(0.3, 1.0))
    return 0.8 * air + 0.35 * sig


def leaves_rustling():
    return shaped(F ** -0.3 * bp(1300, 5200)) * rustle_env(7) * (0.6 + 0.4 * cyc(1, 0.5))


# --------------------------------------------------------------------------- noise
def soft_fan():
    body = shaped(F ** -0.8 * bp(80, 2800)) * (1 + 0.06 * np.sin(2 * np.pi * 600 * T / DUR))
    return body + 0.4 * tone(95, (1, 2, 3)) * 0.15


def air_conditioner():
    return shaped(F ** -0.7 * bp(60, 3200)) * smooth_env(0.3, 0.08) + 0.25 * tone(120, (1, 2, 3), (1, 0.5, 0.25)) * 0.3


def soft_hiss():
    return shaped(F ** -0.8 * bp(1800, 6500))


def deep_rumble():
    return shaped(F ** -1.2 * bp(20, 180)) * smooth_env(0.2, 0.2)


def violet_noise():
    return shaped(F ** 0.3 * bp(900, 5500))


def cabin_noise():
    return 0.9 * shaped(F ** -1.0 * bp(30, 400)) + 0.35 * shaped(F ** -0.5 * bp(200, 1800)) + 0.04 * tone(62, (1, 2))


# --------------------------------------------------------------------------- cozy
def _room():
    return shaped(F ** -0.8 * lp(900) * hp(40)) * smooth_env(0.2, 0.05)


def fireplace():
    bed = shaped(F ** -1.0 * lp(420) * hp(30)) * 0.30
    crackle = sparks(11, [burst(46, 500, 3200, 14, 2.5), burst(30, 700, 3800, 9, 2.0)], 0.7)
    pops = sparks(1.8, [burst(14, 700, 3500, 4, 1.5)], 0.6)
    return bed + 1.1 * crackle + 0.7 * pops


def soft_crackling_fire():
    bed = shaped(F ** -1.0 * lp(380) * hp(30)) * 0.30
    crackle = sparks(7, [burst(55, 400, 2600, 18, 3.0), burst(38, 500, 3000, 12, 2.5)], 0.6)
    return bed + 0.9 * crackle + 0.4 * sparks(0.8, [burst(16, 600, 3000, 5, 1.5)], 0.5)


def campfire():
    roar = shaped(F ** -0.9 * bp(70, 1100)) * smooth_env(1.5, 0.2, 0.2)
    crackle = sparks(15, [burst(50, 500, 3000, 15, 2.5), burst(32, 700, 3400, 10, 2.0)], 0.7)
    pops = sparks(2.5, [burst(18, 600, 3200, 5, 1.5)], 0.6)
    return 0.4 * roar + 1.0 * crackle + 0.7 * pops


def soft_room_tone():
    return _room() + 0.2 * brown()


def clock_tick_soft():
    sig = np.zeros(N)
    for k in range(DUR):  # one soft tick per second, alternating pitch
        f = 900 if k % 2 == 0 else 700
        n = int(SR * 0.12)
        t = np.arange(n) / SR
        tick = np.sin(2 * np.pi * f * t) * np.exp(-t / 0.014) * np.minimum(1, t / 0.0015) * 0.8
        nz = burst(25, 800, 3000, 8, 1.2) * 0.35
        tick[: len(nz)] += nz
        stamp(sig, tick, k * SR)
    return sig + 0.12 * _room()


def page_turning_ambient():
    sig = np.zeros(N)
    for start in (2.5, 9.0, 15.5):
        n = int(SR * 0.9)
        t = np.linspace(0, 1, n)
        env = sum(a * np.exp(-((t - c) / 0.12) ** 2) for a, c in ((0.6, 0.25), (1.0, 0.5), (0.7, 0.75)))
        stamp(sig, band_noise(n, 1200, 4800) * env * 0.5, start * SR)
    return sig + 0.2 * _room()


def warm_indoor_hum():
    return 0.6 * tone(100, (1, 2, 3), (1, 0.45, 0.2)) + 0.5 * shaped(F ** -1.0 * lp(300) * hp(30)) + 0.15 * _room()


def blanket_rustle():
    return shaped(F ** -0.5 * bp(250, 2600)) * rustle_env(4) * 0.9 + 0.25 * _room()


# --------------------------------------------------------------------------- registry
# name: (function, final low-pass Hz, soft-limiter sigmas, target RMS)
SOUNDS = {
    # rain & thunder
    "gentle_rain": (gentle_rain, 6500, 3.0, 0.16),
    "heavy_rain": (heavy_rain, 7000, 3.0, 0.16),
    "distant_thunder": (distant_thunder, 1500, 7.0, 0.14),
    "soft_drizzle": (soft_drizzle, 5500, 3.0, 0.12),
    "rain_on_window": (rain_on_window, 4500, 4.0, 0.15),
    "rain_on_leaves": (rain_on_leaves, 6000, 3.0, 0.15),
    "light_shower": (light_shower, 6500, 3.0, 0.15),
    "forest_rain": (forest_rain, 5500, 3.5, 0.15),
    "rain_soft_wind": (rain_soft_wind, 6000, 3.0, 0.15),
    "thunderstorm": (thunderstorm, 6500, 6.0, 0.16),
    "close_thunder": (close_thunder, 4000, 8.0, 0.15),
    # ocean
    "ocean_waves": (ocean_waves, 5500, 3.0, 0.16),
    "ocean_night": (ocean_night, 3000, 3.0, 0.16),
    "soft_beach_waves": (soft_beach_waves, 4500, 3.0, 0.15),
    "deep_ocean": (deep_ocean, 1800, 3.0, 0.17),
    "tide_pool": (tide_pool, 3800, 4.0, 0.13),
    "rocky_shore": (rocky_shore, 5500, 3.5, 0.16),
    "distant_surf": (distant_surf, 2200, 3.0, 0.15),
    "underwater_soft": (underwater_soft, 1500, 5.0, 0.15),
    "night_tide": (night_tide, 2600, 3.0, 0.15),
    # wind & nature
    "soft_wind": (soft_wind, 2500, 3.0, 0.15),
    "strong_wind": (strong_wind, 3000, 3.0, 0.17),
    "wind_in_trees": (wind_in_trees, 5500, 3.0, 0.15),
    "mountain_breeze": (mountain_breeze, 4000, 3.0, 0.13),
    "forest_stream": (forest_stream, 5500, 3.0, 0.15),
    "creek": (creek, 5200, 3.0, 0.14),
    "river_rapids": (river_rapids, 6500, 3.0, 0.17),
    "night_crickets": (night_crickets, 5200, 4.0, 0.14),
    "frogs_night": (frogs_night, 3500, 4.0, 0.14),
    "birds_dusk": (birds_dusk, 5200, 5.0, 0.12),
    "bamboo_forest": (bamboo_forest, 4200, 4.0, 0.13),
    "leaves_rustling": (leaves_rustling, 5500, 3.0, 0.13),
    # noise
    "white_noise": (white, 9000, 3.5, 0.16),
    "pink_noise": (pink, 9500, 3.5, 0.16),
    "brown_noise": (brown, 8000, 3.5, 0.16),
    "soft_fan": (soft_fan, 3500, 3.0, 0.15),
    "air_conditioner": (air_conditioner, 3500, 3.0, 0.15),
    "soft_hiss": (soft_hiss, 6000, 3.0, 0.12),
    "deep_rumble": (deep_rumble, 400, 3.0, 0.18),
    "violet_noise": (violet_noise, 5500, 3.0, 0.10),
    "cabin_noise": (cabin_noise, 2200, 3.0, 0.16),
    # cozy
    "fireplace": (fireplace, 4500, 4.5, 0.15),
    "soft_crackling_fire": (soft_crackling_fire, 4000, 4.5, 0.13),
    "campfire": (campfire, 4500, 4.5, 0.15),
    "soft_room_tone": (soft_room_tone, 1200, 3.0, 0.12),
    "clock_tick_soft": (clock_tick_soft, 3500, 12.0, 0.08),
    "page_turning_ambient": (page_turning_ambient, 4500, 8.0, 0.08),
    "warm_indoor_hum": (warm_indoor_hum, 1500, 3.0, 0.14),
    "blanket_rustle": (blanket_rustle, 3500, 3.0, 0.11),
}


def finalize(x, fc, limit_sigmas, target_rms, peak=0.9):
    x = np.fft.irfft(np.fft.rfft(x - np.mean(x)) * lp(fc, 3), n=N)  # periodic -> still seamless
    k = limit_sigmas * np.sqrt(np.mean(x ** 2)) + 1e-12
    x = k * np.tanh(x / k)  # soft-limit rare loud transients
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
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
    os.makedirs(out, exist_ok=True)
    total = 0
    print(f"{'sound':22s} {'MB':>5s} {'rms':>6s} {'peak':>5s} {'crest':>5s} {'>5kHz%':>7s} {'seam':>5s}")
    for name, (fn, fc, lim, rms) in SOUNDS.items():
        seed_for(name)
        x = finalize(fn(), fc, lim, rms)
        spec = np.abs(np.fft.rfft(x)) ** 2
        hf = 100 * spec[FREQS > 5000].sum() / spec.sum()
        seam = abs(x[0] - x[-1]) / (np.std(np.diff(x)) + 1e-12)
        path = os.path.join(out, name + ".wav")
        write_wav(path, x)
        size = os.path.getsize(path)
        total += size
        r = float(np.sqrt(np.mean(x ** 2)))
        p = float(np.max(np.abs(x)))
        print(f"{name:22s} {size/1e6:5.2f} {r:6.3f} {p:5.2f} {p/r:5.1f} {hf:7.2f} {seam:5.2f}")
    print(f"{len(SOUNDS)} sounds, {total/1e6:.1f} MB total")


if __name__ == "__main__":
    main()
