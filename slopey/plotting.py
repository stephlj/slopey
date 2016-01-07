from __future__ import division
import numpy as np
import matplotlib.pyplot as plt

# TODO these plots might be off by one cycle


def plot_trace(x, time_max=None, time_offset=0.,
               mark_changepoints=True, **plot_kwargs):
    times, vals = x
    time_max = time_max if time_max else times[-1] + 1

    def get_points(times, vals):
        times = np.array([0.] + list(times) + [time_max])
        return times - time_offset, np.repeat(vals, 2)

    xs, ys = get_points(times, vals)

    # plot x line
    plt.plot(xs, ys, **plot_kwargs)

    # plot starts and stops with x's
    if mark_changepoints:
        plt.plot(xs[1:-1:2], ys[1:-1:2], 'bx', alpha=0.1)
        plt.plot(xs[2::2], ys[2::2], 'yx', alpha=0.1)

    # set axis limits
    plt.ylim(0., np.max(ys) + 1.)
    plt.xlim(0., time_max - time_offset)


def plot_samples(samples, z, T_cycle):
    num_frames = len(z)
    zR, zG = z.T

    def plot_sample(sample, **kwargs):
        x, u, ch2_transform = sample
        time_max = T_cycle * num_frames

        def flip_to_ch2(x):
            times, vals = x
            return times, np.max(vals) - vals + np.min(vals)

        def transform_to_measured_ch2(x):
            a, b = ch2_transform
            times, vals = flip_to_ch2(x)
            return times, a * vals + b

        plot_trace(x, time_max, u, color='r', **kwargs)
        plot_trace(flip_to_ch2(x), time_max, u, color='g', linestyle=':', **kwargs)
        plot_trace(transform_to_measured_ch2(x), time_max, u, color='g', **kwargs)

    def plot_frames(seq, colorstr):
        ns = range(1, len(seq) + 1)
        plt.plot(ns, seq, colorstr + 'o', markersize=3)

    fig, axs = plt.subplots(2,1, figsize=(8,6))

    plt.axes(axs[0])
    plot_frames(zR, 'r')
    plot_frames(zG, 'g')
    plt.xlim(0, num_frames + 1)
    frames_ylim = plt.ylim()

    plt.axes(axs[1])
    for sample in samples[-1::-50]:
        plot_sample(sample, alpha=0.05)
    plt.ylim(frames_ylim)
