from __future__ import division
import numpy as np
import numpy.random as npr
import matplotlib.pyplot as plt

from slopey.camera_model import make_camera_model
from slopey.noise_models import make_gaussian_model
from slopey.priors import plot_theta

times = [1., 1.5, 3, 3.5]
vals = [5., 1., 3]
theta = times, vals

_, camera_sample = \
    make_camera_model(0.1, 0.01, 60, make_gaussian_model(sigmasq=0.01))

samples = [camera_sample(theta) for _ in xrange(3)]

colors = ['b', 'g', 'r']
for color, sample in zip(colors, samples):
    plt.stem(sample, 'k-', markerfmt=color + 'o')

plt.figure()
plot_theta(theta)

plt.show()
