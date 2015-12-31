from __future__ import division
import numpy as np
import numpy.random as npr
import matplotlib.pyplot as plt

from slopey.samplers import run_mh
from slopey.priors import make_prior, make_proposal
from slopey.camera_model import make_camera_model
from slopey.noise_models import make_gaussian_model
from slopey.plotting import plot_theta

npr.seed(0)


# set up some experiment hypers
T_cycle = 0.03
T_blank = 0.001
noise_sigmasq = 1e-1

# set up synthetic trace and frame offset
times = np.array([1.5, 1.8])
vals = np.array([3., 1.])
theta = times, vals

u = 0.01 * T_cycle
x = theta, u

# instantiate camera model
camera_loglike, camera_sample = \
    make_camera_model(T_cycle, T_blank, make_gaussian_model(noise_sigmasq))

# generate frame data
num_frames = int(np.ceil((times[-1] + 1) / T_cycle))
z = camera_sample(theta, u, num_frames)
np.savetxt('data/example_frames.txt', z)

# set up prior
log_prior_density, _ = make_prior((1., 1./3), (6., 2.), (12., 2.))

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

print np.mean(accepts)

# plot the results
def plot_sample(theta, u, **kwargs):
    plot_theta(theta, num_frames * T_cycle, u, **kwargs)

fig, axs = plt.subplots(2,1, figsize=(8,6))

plt.axes(axs[0])
plt.stem(range(1, len(z) + 1), z)
plt.xlim(0, len(z) + 1)

plt.axes(axs[1])
for sampled_theta, sampled_u in samples[-1::-50]:
    plot_sample(sampled_theta, sampled_u, color='r', alpha=0.05)
plot_sample(theta, u, color='k', linestyle='--')

plt.savefig('plots/inference.png')
plt.show()
