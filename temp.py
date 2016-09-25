from __future__ import division
import numpy as np

# TODO handle u (subtract from times?)

times = [0.51, 0.81, 1.1, 1.2]
vals =  [2., 1., 1., 0.5]
T_cycle = 0.1
T_blank = 0.01

K = len(times)
T = 25

def integrate_affine(slope, x0, y0, a, b):
    y_intercept = y0 - slope * x0
    return 0.5 * slope * (b**2 - a**2)  + y_intercept * (b - a)

out = np.zeros(T)

# always start on flat
slopey = 0
slope = 0.

k = 0
t = 0
time, val = times[k], vals[k]

while t < T:
    while t < T and (k >= K or (t+1)*T_cycle < times[k]):
        out[t] = integrate_affine(
            slope, time, val, t*T_cycle, (t+1)*T_cycle - T_blank)
        t += 1

    if t < T:
        start = t*T_cycle
        while k < K and times[k] < (t+1)*T_cycle:
            out[t] += integrate_affine(slope, time, val, start, times[k])
            start = times[k]
            k += 1
            slopey ^= 1
            slope = (vals[k-1] - vals[k]) / (times[k-1] - times[k]) \
                if slopey else 0.
        time, val = times[k-1], vals[k-1]
        out[t] += integrate_affine(
            slope, time, val, start, (t+1)*T_cycle - T_blank)
        t += 1
