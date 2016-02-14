from __future__ import division
import numpy as np
import matplotlib.pyplot as plt

from camera_model import flip, red_to_green

# TODO these plots might be off by one cycle

# http://stackoverflow.com/a/20007730
ordinal = lambda n: "%d%s" % (n,"tsnrhtdd"[(n/10%10!=1)*(n%10<4)*n%10::4])


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


def plot_frames(seq, colorstr):
    ns = range(1, len(seq) + 1)
    plt.plot(ns, seq, colorstr + 'o', markersize=3)

    plt.xlabel('frame number')
    plt.ylabel('measured intensity')


def plot_samples(samples, z, T_cycle, warmup=None, use_every_k_samples=50):
    num_frames = len(z)
    warmup = warmup if warmup is not None else len(samples) // 2
    zR, zG = z.T
    samples = samples[warmup:]

    def plot_trace_sample(sample, **kwargs):
        x, u, ch2_transform = sample
        time_max = T_cycle * num_frames

        plot_trace(x, time_max, u, color='r', **kwargs)
        plot_trace(flip(x), time_max, u, color='g', **kwargs)
        plot_trace(red_to_green(x, ch2_transform), time_max, u, color='lightgreen', **kwargs)

        plt.xlabel('time (sec)')
        plt.ylabel('inferred latent intensity')

    def plot_duration_samples(samples):
        from scipy.stats import gaussian_kde

        def get_slopey_durations(sample):
            x, u, ch2_transform = sample
            times, vals = x
            return np.diff(times)[::2]

        t = np.linspace(0, 4, 250)
        sampled_durations = np.array([get_slopey_durations(sample) for sample in samples])
        num_slopey = sampled_durations.shape[1]

        for slopey_idx, durations in enumerate(sampled_durations.T):
            plt.plot(t, gaussian_kde(durations)(t)/num_slopey, label=ordinal(slopey_idx+1))
        plt.plot(t, gaussian_kde(sampled_durations.ravel())(t), ':', label='overall')

        plt.legend(loc='best')
        plt.xlabel('inferred slopey bit durations (seconds)')
        plt.ylabel('probability density')

    fig, axs = plt.subplots(3,1, figsize=(8,9))

    plt.axes(axs[0])
    plot_frames(zR, 'r')
    plot_frames(zG, 'g')
    plt.xlim(0, num_frames + 1)
    frames_ylim = plt.ylim()

    plt.axes(axs[1])
    for sample in samples[-1::-use_every_k_samples]:
        plot_trace_sample(sample, alpha=0.05)
    plt.ylim(frames_ylim)

    plt.axes(axs[2])
    plot_duration_samples(samples)


def make_animation_callback(z, T_cycle):
    num_frames = len(z)
    zR, zG = z.T
    time_max = T_cycle * num_frames

    fig, axs = plt.subplots(2, 1, figsize=(8,6))

    plt.axes(axs[0])
    plot_frames(zG, 'g')
    plot_frames(zR, 'r')
    frames_ylim = plt.ylim()

    plt.axes(axs[1])
    redline, = plt.plot([], 'r')
    greenline, = plt.plot([], 'g')
    plt.xlim(0, time_max)
    plt.ylim(frames_ylim)

    ax = axs[1]
    ax.autoscale(False)
    plt.ion()
    plt.show()

    background = fig.canvas.copy_from_bbox(ax.bbox)

    def update_trace(theta):
        (times, vals), u, (a, b) = theta
        xs = np.array([0.] + list(times) + [time_max]) - u
        red_ys = np.repeat(vals, 2)
        green_ys = a*(np.max(vals) - red_ys) + b

        redline.set_data(xs, red_ys)
        greenline.set_data(xs, green_ys)
        ax.draw_artist(redline)
        ax.draw_artist(greenline)

    def callback(alpha, theta, accept):
        fig.canvas.restore_region(background)
        update_trace(theta)
        fig.canvas.blit(ax.bbox)

    return callback
