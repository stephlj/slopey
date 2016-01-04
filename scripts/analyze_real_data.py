from __future__ import division
import numpy as np
import numpy.random as npr
import matplotlib.pyplot as plt
from scipy.io import loadmat

from slopey.noise_models import make_gaussian_model
from slopey.models import model1
from slopey.plotting import plot_samples

npr.seed(0)  # reproducible


### load data
datadict = loadmat('data/SNF2h103nMATP1mMHighFPS_2015_Dec04_Spot1_187_Results.mat')
zR = np.squeeze(datadict['unsmoothedRedI'])
zG = np.squeeze(datadict['unsmoothedGrI'])
z = np.hstack((zR[:,None], zG[:,None]))


### setting parameters

# set how many slopey bits are expected
# For now: get this info from the old HMM analysis
num_slopey = 1
# num_slopey = len(datadict['model_durations'].ravel())-1

# set number of iterations of MH
num_iterations = 5000

# set camera model parameters
T_cycle = 0.036
T_blank = 0.00175
noise_sigmasq = 0.2
camera_params = T_cycle, T_blank, make_gaussian_model(noise_sigmasq)

# set prior hyperparameters
intensity_hypers = 1., 1./3  # exponential prior with mean of alpha/beta = 3

slopey_time_hypers = 2., 4.  # gamma prior peaked near mean of alpha/beta = 1./2
flat_time_hypers = 3., 2.    # gamma prior peaked near mean of alpha/beta = 3./2

theta_params = intensity_hypers, slopey_time_hypers, flat_time_hypers

ch2_transform_a_hypers = 5., 5.
ch2_transform_b_hypers = 1., 20.
ch2_transform_hypers = ch2_transform_a_hypers, ch2_transform_b_hypers

prior_params = theta_params, ch2_transform_hypers

# set proposal distribution scale parameters
# (tune so proposals are acceptedl ~30% of the time)
proposal_params = (1e3, 1e3), 1e3, 1e3


### running inference

# make a runner function
run = model1(num_slopey, prior_params, camera_params, proposal_params, z)

# run it
samples = run(num_iterations)

# discard half of the samples as warm-up (since initialization was random)
samples = samples[num_iterations//2:]

# plot the results
plot_samples(samples, z, T_cycle)
plt.show()
