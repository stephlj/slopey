from __future__ import division
import numpy as np

def integrate_affine(slope, x0, y0, a, b):
    y_intercept = y0 - slope * x0
    return 0.5 * slope * (b**2 - a**2)  + y_intercept * (b - a)

def noiseless_measurements(x, u, num_frames, T_cycle, T_blank):
    times, vals = map(np.array, x)
    times = times - u
    K = times.shape[0]
    out = np.zeros(num_frames)

    # always start on flat
    slopey, slope = 0, 0.
    k, t = 0, 0
    time, val = times[0], vals[0]
    while t < num_frames:
        while t < num_frames and (k >= K or (t+1)*T_cycle < times[k]):
            out[t] = integrate_affine(
                slope, time, val, t*T_cycle, (t+1)*T_cycle - T_blank)
            t += 1

        # if t == 204:
        #     import ipdb; ipdb.set_trace()
        if t < num_frames:
            start = t*T_cycle
            cycle_end = (t+1)*T_cycle
            shutter_close = cycle_end - T_blank
            while k < K and times[k] < cycle_end:
                if start < shutter_close:
                    out[t] += integrate_affine(
                        slope, time, val, start, min(times[k], shutter_close))
                start = times[k]
                k += 1
                slopey ^= 1
                slope = (vals[k-1] - vals[k]) / (times[k-1] - times[k]) \
                    if slopey else 0.
            time, val = times[k-1], vals[k-1]
            if start < shutter_close:
                out[t] += integrate_affine(slope, time, val, start, shutter_close)
            t += 1

    return out / (T_cycle - T_blank)


if __name__ == '__main__':
    import matplotlib.pyplot as plt

    times = [0.51, 0.81, 1.1, 1.2]
    vals =  [2., 1., 1., 0.5]
    x = (times, vals)
    T_cycle = 0.1
    T_blank = 0.01
    u = T_cycle / 3.
    num_frames = 25

    plt.plot(noiseless_measurements(x, u, num_frames, T_cycle, T_blank))
    plt.show()
