from __future__ import division
import numpy as np
import numpy.random as npr
import matplotlib.pyplot as plt

from slopey.noise_models import make_gaussian_model
from slopey.models import model1
from slopey.priors import plot_theta  # TODO move plotting code elsewhere

npr.seed(0)  # reproducible


### load data
z = np.loadtxt('data/example_frames.txt')
num_frames = len(z)


### setting parameters

# set how many slopey bits are expected
num_slopey = 1

# set number of iterations of MH
num_iterations = 5000

# set camera model parameters
T_cycle = 0.036
T_blank = 0.003
noise_sigmasq = 0.2  # TODO adjust this one
camera_params = T_cycle, T_blank, make_gaussian_model(noise_sigmasq)

# set prior hyperparameters TODO adjust these
intensity_hypers = 1., 1./3  # exponential prior with mean of alpha/beta = 3
slopey_time_hypers = 2., 4.  # gamma prior peaked near mean of alpha/beta = 1./2
flat_time_hypers = 3., 2.    # gamma prior peaked near mean of alpha/beta = 3./2
prior_params = intensity_hypers, slopey_time_hypers, flat_time_hypers

# set proposal distribution scale parameters
# (tune so proposals are acceptedl ~30% of the time)
proposal_params = (1e3, 1e3), 1e3, T_cycle


### running inference

# make a runner function
run = model1(num_slopey, prior_params, camera_params, proposal_params, z)

# run it
samples = run(num_iterations)

# discard half of the samples as warm-up (since initialization was random)
samples = samples[num_iterations//2:]


### plotting the results

def plot_sample(theta, u, **kwargs):
    plot_theta(theta, num_frames * T_cycle, u, **kwargs)

fig, axs = plt.subplots(2,1, figsize=(8,6))

plt.axes(axs[0])
plt.stem(range(1, len(z) + 1), z)
plt.xlim(0, len(z) + 1)

plt.axes(axs[1])
for sampled_theta, sampled_u in samples[-1::-50]:
    plot_sample(sampled_theta, sampled_u, color='r', alpha=0.05)

plt.show()
