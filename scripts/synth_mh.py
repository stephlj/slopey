from __future__ import division
import numpy as np
import numpy.random as npr
import matplotlib.pyplot as plt

from slopey.samplers import run_mh
from slopey.priors import make_prior, make_proposal, plot_theta
from slopey.camera_model import make_camera_model
from slopey.noise_models import make_gaussian_model

npr.seed(0)


# set up some experiment hypers
num_frames = 45
T_cycle = 0.1
T_blank = 0.01
noise_sigmasq = 1e-1

# set up synthetic trace and frame offset
times = np.array([1., 1.5])
vals = np.array([5., 1.])
theta = times, vals

u = 0.01 * T_cycle
x = theta, u

# instantiate camera model
camera_loglike, camera_sample = \
    make_camera_model(T_cycle, T_blank, make_gaussian_model(noise_sigmasq))

# generate frame data
z = camera_sample(theta, u, num_frames)

# set up prior
log_prior_density, _ = make_prior((3., 1.), (6., 2.), (12., 2.))

# define joint distribution
def log_p(x):
    theta, u = x
    return camera_loglike(z, theta, u) + log_prior_density(theta)

# set up proposal distribution
proposal_distn = make_proposal((1e3, 1e3), 1e3, T_cycle)

# make a callback to print things
accepts = []
callback = lambda alpha, theta, accept: accepts.append(accept)

# run mh starting from the truth
samples = run_mh(x, log_p, proposal_distn, 5000, callback)

sampled_thetas = [theta for theta, u in samples]
print np.mean(accepts)

# plot the results
fig, axs = plt.subplots(2,1, figsize=(8,6))

plt.axes(axs[0])
plt.stem(range(1, len(z) + 1), z)
plt.xlim(0, len(z) + 1)

plt.axes(axs[1])
for sampled_theta in sampled_thetas[-1::-50]:
    plot_theta(sampled_theta, num_frames * T_cycle, u, alpha=0.05, color='r')

plt.savefig('plots/inference.png')

plt.show()
