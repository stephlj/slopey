from __future__ import division
import numpy as np
import numpy.random as npr
from scipy.special import gammaln
from itertools import cycle, chain
from functools import partial
from operator import itemgetter


def make_camera_model(camera_params):
    T_cycle, T_blank, noise_model = camera_params
    noise_loglike, noise_sample = noise_model

    def loglike(z, theta):
        x, u, ch2_transform_params = theta
        assert z.ndim == 2 and z.shape[1] == 2
        num_frames = z.shape[0]
        F = make_integrated_x(x)
        y = noiseless_measurements(F, u, num_frames)
        y_2ch = add_second_channel(y, x, ch2_transform_params)
        return noise_loglike(y_2ch, z)

    def sample(theta, num_frames):
        x, u, ch2_transform_params = theta
        F = make_integrated_x(x)
        y = noiseless_measurements(F, u, num_frames)
        y_2ch = add_second_channel(y, x, ch2_transform_params)
        return noise_sample(y_2ch)

    def noiseless_measurements(F, u, num_frames):
        starts = u + np.arange(0., num_frames * T_cycle, T_cycle)
        stops = starts + T_cycle - T_blank
        return (F(stops) - F(starts)) / (T_cycle - T_blank)  # each box has unit area

    def add_second_channel(y1, x, ch2_transform_params):
        a, b = ch2_transform_params
        a, b = a, T_cycle * b  # make parameterization invariant to T_cycle

        def flip(y):
            times, vals = x
            return np.max(vals) - y

        y2 = a * flip(y1) + b
        return np.hstack((y1[:,None], y2[:,None]))

    return loglike, sample


### internals below here!

def make_integrated_x(x):
    times, vals = x
    indicator_funcs = make_indicator_funcs(times)
    value_funcs = make_value_funcs(times, vals)
    return make_piecewise(indicator_funcs, value_funcs)


def make_piecewise(indicator_funcs, value_funcs):
    pairs = zip(indicator_funcs, value_funcs)
    def piecewise_function(x):
        return np.concatenate([f(x[ind(x)]) for ind, f in pairs])
    return piecewise_function


def make_indicator_funcs(times):
    make_interval_indicator = lambda a, b: lambda x: (a <= x) & (x < b)
    times = [-np.inf] + list(times) + [np.inf]
    return map(make_interval_indicator, times[:-1], times[1:])


def make_value_funcs(times, vals):
    def get_points(times, vals):
        times = [-np.inf] + list(times) + [np.inf]
        return zip(times, np.repeat(vals, 2))

    def make_integral_piece(slope, intercept):
        f = lambda x: slope/2. * x**2 + intercept * x
        make_offset_f = lambda x0, y0: lambda x: f(x - x0) + y0
        return make_offset_f

    def compose_pieces(times, funcs):
        make_step = lambda F, t0: lambda G_prev: F(t0, G_prev(t0))
        steps = map(make_step, funcs[1:], times)

        composed_funcs = [funcs[0](0., 0.)]
        for step in steps:
            composed_funcs.append(step(composed_funcs[-1]))

        return composed_funcs

    x, y = itemgetter(0), itemgetter(1)
    slope = lambda pt1, pt2: (y(pt2) - y(pt1)) / (x(pt2) - x(pt1))
    intercept = lambda pt1, pt2: y(pt1)

    points = get_points(times, vals)
    slopes = map(slope, points[:-1], points[1:])
    intercepts = map(intercept, points[:-1], points[1:])
    unoffset_funcs = map(make_integral_piece, slopes, intercepts)

    return compose_pieces(times, unoffset_funcs)
