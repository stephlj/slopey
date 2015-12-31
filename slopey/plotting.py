from __future__ import division
import numpy as np
import matplotlib.pyplot as plt


def plot_theta(theta, time_max=None, time_offset=0., **plot_kwargs):
    times, vals = theta
    time_max = time_max if time_max else times[-1] + 1

    def get_points(times, vals):
        times = np.array([0.] + list(times) + [time_max])
        return times - time_offset, np.repeat(vals, 2)

    xs, ys = get_points(times, vals)

    plt.plot(xs, ys, **plot_kwargs)
    plt.ylim(0., np.max(ys) + 1.)
    plt.xlim(0., time_max - time_offset)


def plot_samples(samples, z, T_cycle):
    num_frames = len(z)

    def plot_sample(theta, u, **kwargs):
        plot_theta(theta, num_frames * T_cycle, u, **kwargs)

    fig, axs = plt.subplots(2,1, figsize=(8,6))

    plt.axes(axs[0])
    plt.stem(range(1, len(z) + 1), z)
    plt.xlim(0, len(z) + 1)

    plt.axes(axs[1])
    for sampled_theta, sampled_u in samples[-1::-50]:
        plot_sample(sampled_theta, sampled_u, color='r', alpha=0.05)
