from __future__ import division
import numpy as np


def make_piecewise(indicator_funcs, value_funcs):
    pairs = zip(indicator_funcs, value_funcs)
    def piecewise_function(x):
        return np.concatenate([f(x[ind(x)]) for ind, f in pairs])
    return piecewise_function


def interleave(a, b):
    out = np.empty((a.size + b.size,), dtype=a.dtype)
    out[::2] = a
    out[1::2] = b
    return out


def compose_pieces(times, funcs):
    make_step = lambda F, t0: lambda G_prev: F(t0, G_prev(t0))
    steps = map(make_step, funcs[1:], times)

    composed_funcs = [funcs[0](0., 0.)]
    for step in steps:
        composed_funcs.append(step(composed_funcs[-1]))

    return composed_funcs


def make_indicator_funcs(times):
    make_interval_indicator = lambda a, b: lambda x: (a <= x) & (x < b)
    times = [-np.inf] + list(times) + [np.inf]
    return map(make_interval_indicator, times[:-1], times[1:])
