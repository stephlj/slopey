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
z = loadmat('data/SNF2h103nMATP1mMHighFPS_2015_Dec04_Spot1_115_Results.mat')
zR = z['unsmoothedRedI'].ravel()
zG = z['unsmoothedGrI'].ravel()
# Clip if necessary:
start = z['start'].ravel()
zR = zR[start[0]:sum(z['model_durations'].ravel())]
zG = zG[start[0]:sum(z['model_durations'].ravel())]
num_frames = len(zR)


### setting parameters

# set how many slopey bits are expected
# For now: get this info from the old HMM analysis
# num_slopey = 2
num_slopey = len(z['model_durations'].ravel())-1

# set number of iterations of MH
num_iterations = 5000

# set camera model parameters
T_cycle = 0.036
T_blank = 0.00175
noise_sigmasq = 0.2  # TODO adjust this one
camera_params = T_cycle, T_blank, make_gaussian_model(noise_sigmasq)

# set prior hyperparameters TODO get these from old HMM analysis?
intensity_hypers = 1., 1./3  # exponential prior with mean of alpha/beta = 3
slopey_time_hypers = 2., 4.  # gamma prior peaked near mean of alpha/beta = 1./2
flat_time_hypers = 3., 2.    # gamma prior peaked near mean of alpha/beta = 3./2
prior_params = intensity_hypers, slopey_time_hypers, flat_time_hypers

# set proposal distribution scale parameters
# (tune so proposals are acceptedl ~30% of the time)
proposal_params = (1e3, 1e3), 1e3, T_cycle


### running inference

# make a runner function TODO accept both zR and zG!
run = model1(num_slopey, prior_params, camera_params, proposal_params, zR)

# run it
samples = run(num_iterations)

# discard half of the samples as warm-up (since initialization was random)
samples = samples[num_iterations//2:]

# plot the results
plot_samples(samples, z, T_cycle)
plt.show()
