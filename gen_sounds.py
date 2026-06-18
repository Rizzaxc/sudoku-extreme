"""Generate 5 short WAV sound effects for the Sudoku app."""
import math, struct, wave, os

RATE = 44100

def write_wav(path, frames):
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)

def tone(freq, duration, volume=0.6, fade_ms=20):
    n = int(RATE * duration)
    fade = int(RATE * fade_ms / 1000)
    samples = []
    for i in range(n):
        t = i / RATE
        v = math.sin(2 * math.pi * freq * t)
        # fade in/out
        env = 1.0
        if i < fade:
            env = i / fade
        elif i > n - fade:
            env = (n - i) / fade
        samples.append(int(v * env * volume * 32767))
    return struct.pack(f'<{n}h', *samples)

def silence(duration):
    n = int(RATE * duration)
    return struct.pack(f'<{n}h', *([0] * n))

out = 'assets/sounds'

# place.wav — crisp 880 Hz tick (90 ms)
write_wav(f'{out}/place.wav', tone(880, 0.09, volume=0.55))

# pencil.wav — softer 660 Hz tick (70 ms)
write_wav(f'{out}/pencil.wav', tone(660, 0.07, volume=0.35))

# erase.wav — descending 440→220 Hz sweep (90 ms)
n = int(RATE * 0.09)
fade = int(RATE * 0.015)
samples = []
for i in range(n):
    t = i / RATE
    freq = 440 * (1 - 0.5 * i / n)   # 440 → 220
    v = math.sin(2 * math.pi * freq * t)
    env = 1.0
    if i < fade: env = i / fade
    elif i > n - fade: env = (n - i) / fade
    samples.append(int(v * env * 0.45 * 32767))
write_wav(f'{out}/erase.wav', struct.pack(f'<{n}h', *samples))

# win.wav — ascending C4-E4-G4-C5 arpeggio (130 ms each note)
win = b''
for freq in [261.63, 329.63, 392.00, 523.25]:
    win += tone(freq, 0.13, volume=0.55, fade_ms=15)
write_wav(f'{out}/win.wav', win)

# lose.wav — descending A3-E3 with longer duration
lose = b''
for freq, dur in [(220, 0.22), (164.81, 0.30)]:
    lose += tone(freq, dur, volume=0.50, fade_ms=25)
write_wav(f'{out}/lose.wav', lose)

def gong_samples(freq, duration, volume=0.6):
    n = int(RATE * duration)
    partials = [
        (freq,        1.00),
        (freq * 2.76, 0.35),
        (freq * 5.40, 0.18),
        (freq * 8.93, 0.08),
    ]
    decay = 6.0 / duration
    out_s = []
    for i in range(n):
        t = i / RATE
        env = math.exp(-decay * t)
        attack = min(1.0, t / 0.003)
        v = sum(amp * math.sin(2 * math.pi * p * t) for p, amp in partials)
        out_s.append(v * env * attack * volume)
    return out_s

# start.wav — double gong "ting ting" at 560 Hz, 110 ms inter-onset interval.
# Silence-between-notes doesn't work: the gong's slow decay masks any gap <150 ms.
# Instead the two gongs overlap; the second hit starts when the first has decayed
# to ~30% amplitude so its full-strength attack is clearly heard as a separate event.
g1 = gong_samples(560, 0.55)
g2 = gong_samples(560, 0.55)
offset = int(RATE * 0.110)
total = len(g1) + offset
combined = [0.0] * total
for i, s in enumerate(g1):
    combined[i] += s
for i, s in enumerate(g2):
    combined[i + offset] += s
peak = max(abs(s) for s in combined)
scale = 0.95 / peak
write_wav(f'{out}/start.wav',
          struct.pack(f'<{len(combined)}h',
                      *[max(-32767, min(32767, int(s * scale * 32767))) for s in combined]))

# mistake.wav — detuned double-buzz (180 Hz + 195 Hz, 180 ms)
n = int(RATE * 0.18)
fade = int(RATE * 0.012)
samples = []
for i in range(n):
    t = i / RATE
    v = math.sin(2 * math.pi * 180 * t) + math.sin(2 * math.pi * 195 * t)
    env = 1.0
    if i < fade: env = i / fade
    elif i > n - fade: env = (n - i) / fade
    samples.append(int(v * env * 0.30 * 32767))
write_wav(f'{out}/mistake.wav', struct.pack(f'<{n}h', *samples))

for f in ['place','pencil','erase','win','lose','mistake','start']:
    size = os.path.getsize(f'{out}/{f}.wav')
    print(f'{f}.wav  {size} bytes')
