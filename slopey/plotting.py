from __future__ import division
import matplotlib.pyplot as plt

from priors import plot_theta


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
