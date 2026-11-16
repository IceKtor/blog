"""Процедурные звуки и музыка (WAV 22050 Гц, моно). Запуск: python audio.py"""
import os, wave, random
import numpy as np
SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'audio'); os.makedirs(OUT, exist_ok=True)

def write(name, x, vol=0.8):
    x = np.clip(x / (np.max(np.abs(x)) + 1e-9) * vol, -1, 1)
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype('<i2').tobytes())

def t(d): return np.arange(int(SR * d)) / SR
def env(n, a=0.005, r=None):
    e = np.ones(n); ai = max(1, int(a * SR)); e[:ai] = np.linspace(0, 1, ai)
    if r: e *= np.exp(-np.arange(n) / (r * SR))
    return e
def tone(f, d, kind='sine', r=0.2, a=0.005):
    tt = t(d); ph = 2 * np.pi * np.cumsum(np.full(len(tt), 1.0) * (f if np.isscalar(f) else 1)) / SR if np.isscalar(f) else 2 * np.pi * np.cumsum(f) / SR
    if kind == 'sine': w = np.sin(ph)
    elif kind == 'tri': w = 2 / np.pi * np.arcsin(np.sin(ph))
    elif kind == 'sq': w = np.sign(np.sin(ph)) * .5 + np.sin(ph) * .5
    elif kind == 'soft': w = np.sin(ph) + .3 * np.sin(2 * ph) + .1 * np.sin(3 * ph)
    return w * env(len(tt), a, r)
def noise(d, r=0.1, lp=0.5):
    n = np.random.default_rng(1).standard_normal(int(SR * d))
    y = np.zeros_like(n); k = lp
    for i in range(1, len(n)): y[i] = y[i - 1] + k * (n[i] - y[i - 1])
    return y * env(len(n), 0.002, r)
def sweep(f0, f1, d): return np.linspace(f0, f1, int(SR * d))
def cat(*xs): return np.concatenate(xs)
def mix(*xs):
    n = max(len(x) for x in xs); o = np.zeros(n)
    for x in xs: o[:len(x)] += x
    return o

def sfx():
    write('hoe', mix(noise(.18, .05, .25), tone(90, .18, 'sine', .05) * .8))
    write('water', noise(.5, .25, .6) * np.sin(np.linspace(0, np.pi, int(SR * .5))), .5)
    write('chop', mix(noise(.15, .03, .4), tone(160, .15, 'tri', .04)))
    write('pick', mix(tone(1800, .25, 'sine', .06), tone(2700, .25, 'sine', .04) * .5, noise(.06, .02, .8) * .5))
    write('harvest', tone(sweep(400, 900, .15), .15, 'sine', .12), .6)
    write('pickup', cat(tone(880, .06, 'tri', .05), tone(1320, .1, 'tri', .06)), .5)
    write('click', tone(1200, .03, 'sq', .01), .3)
    write('open', tone(sweep(300, 700, .12), .12, 'tri', .1), .4)
    write('close', tone(sweep(700, 300, .12), .12, 'tri', .1), .4)
    write('cast', noise(.35, .15, .3) * np.linspace(0, 1, int(SR * .35)), .5)
    write('splash', mix(noise(.4, .12, .5), tone(sweep(600, 200, .2), .2, 'sine', .08) * .3), .6)
    write('bite', cat(tone(1400, .08, 'sine', .05), tone(1800, .15, 'sine', .08)), .6)
    write('catch', cat(*[tone(f, .09, 'tri', .08) for f in (523, 659, 784, 1047)]), .6)
    write('fail', cat(tone(392, .15, 'tri', .1), tone(294, .3, 'tri', .2)), .5)
    write('coin', cat(tone(1568, .07, 'sq', .04), tone(2093, .2, 'sq', .1)), .35)
    write('door', mix(noise(.25, .08, .15), tone(70, .25, 'sine', .1)), .7)
    write('craft', cat(*[tone(f, .07, 'sine', .07) for f in (784, 988, 1175, 1568)]), .5)
    write('error', tone(140, .2, 'sq', .15), .35)
    write('eat', cat(noise(.07, .03, .5), np.zeros(800), noise(.07, .03, .5), np.zeros(800), noise(.08, .03, .5)), .5)
    write('step', noise(.05, .015, .2), .25)
    write('sleep', cat(*[tone(f, .35, 'soft', .3) for f in (523, 440, 392, 330)]), .5)
    write('rock_break', mix(noise(.3, .1, .35), tone(110, .3, 'tri', .1)), .8)
    write('tree_fall', mix(noise(.8, .3, .2), tone(sweep(120, 50, .8), .8, 'sine', .4)), .8)

NOTE = lambda n: 440 * 2 ** ((n - 69) / 12)
def song(name, bpm, root, prog, scale, lead_kind, seed, vol=.5):
    rng = random.Random(seed); beat = 60 / bpm; bars = len(prog) * 2; out = np.zeros(int(SR * beat * 4 * bars) + SR)
    def add(x, at):
        i = int(at * SR); out[i:i + len(x)] += x[:len(out) - i]
    for b in range(bars):
        ch = prog[b % len(prog)]; t0 = b * 4 * beat
        chord = [root + ch + iv for iv in (0, 4 if ch in (0, 5, 7) else 3, 7)]
        add(tone(NOTE(chord[0] - 24), beat * 2, 'tri', beat * 1.5) * .5, t0)
        add(tone(NOTE(chord[0] - 24), beat * 2, 'tri', beat * 1.5) * .45, t0 + 2 * beat)
        for k in range(8):  # арпеджио
            add(tone(NOTE(chord[k % 3] + 12 * (k // 3 % 2)), beat * .6, 'sine', beat * .35) * .16, t0 + k * beat / 2)
        k = 0
        while k < 8:  # мелодия
            dur = rng.choice([1, 1, 2, 2, 3])
            if rng.random() < .8:
                n = root + 12 + rng.choice(scale)
                if k == 0: n = chord[rng.randrange(3)] + 12
                add(tone(NOTE(n), beat * dur / 2 * .95, lead_kind, beat * dur * .35, .02) * .22, t0 + k * beat / 2)
            k += dur
    write(name, out[:int(SR * beat * 4 * bars)], vol)

sfx()
PENT = [0, 2, 4, 7, 9, 12]
song('music_spring', 92, 60, [0, 5, 9, 7], PENT, 'soft', 1)
song('music_summer', 104, 62, [0, 7, 9, 5], PENT, 'tri', 2)
song('music_fall', 84, 57, [0, 8, 3, 10], [0, 3, 5, 7, 10, 12], 'soft', 3)
song('music_winter', 72, 64, [0, 9, 5, 7], [0, 2, 4, 7, 11, 12], 'sine', 4)
song('music_mine', 66, 50, [0, 1, 0, 10], [0, 1, 3, 7, 8], 'sine', 5, .4)
print('ok', len(os.listdir(OUT)))
