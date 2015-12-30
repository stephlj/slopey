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
    make_camera_model(0.1, 0.01, make_gaussian_model(sigmasq=0.01))

samples = [camera_sample(theta, npr.uniform() * 0.1, 45) for _ in xrange(3)]

colors = ['b', 'g', 'r']
plt.figure(figsize=(8,6))
for color, sample in zip(colors, samples):
    plt.stem(sample, 'k-', markerfmt=color + 'o')
plt.xlabel('frame number')
plt.savefig('plots/synth_frames.png')

plt.figure(figsize=(8,6))
plot_theta(theta, 45*1./10)
plt.xlabel('time (sec)')
plt.savefig('plots/synth_trace.png')


plt.show()
