from __future__ import division
import numpy as np
import numpy.random as npr
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
from scipy.io import loadmat

from slopey.noise_models import make_gaussian_model
from slopey.models import model1
from slopey.plotting import plot_samples, make_animation_callback

npr.seed(0)  # reproducible


### load data
datadict = loadmat('data/SNF2h103nMATP1mMHighFPS_2015_Dec04_Spot1_115_Results')
zR = np.squeeze(datadict['unsmoothedRedI'])
zG = np.squeeze(datadict['unsmoothedGrI'])
start = np.squeeze(datadict['start']);
end = sum(np.squeeze(datadict['model_durations']));
# z = np.hstack((zR[:,None], zG[:,None]))[start:end]
z = np.hstack((zR[:,None], zG[:,None]))[250:end]


### setting parameters

# set how many slopey bits are expected
# For now: get this info from the old HMM analysis
# num_slopey = 2
num_slopey = len(datadict['model_durations'].ravel())-1

# set number of iterations of MH
num_iterations = 20000

# set camera model parameters. T_cycle is the total time frame-to-frame, so it includes T_blank
T_cycle = 0.036
# T_cycle = 0.1356
T_blank = 0.00175
# T_blank = 0.0356
noise_sigmasq = 0.2
camera_params = T_cycle, T_blank, make_gaussian_model(noise_sigmasq)

# set prior hyperparameters
intensity_hypers = 1., 3  # exponential prior with mean of alpha/beta = 3

slopey_time_hypers = 1., 3.
flat_time_hypers = 1., 1./5.

trace_params = intensity_hypers, slopey_time_hypers, flat_time_hypers

ch2_transform_a_hypers = 3., 3.
ch2_transform_b_hypers = 1., 5.
ch2_transform_hypers = ch2_transform_a_hypers, ch2_transform_b_hypers

prior_params = trace_params, ch2_transform_hypers

# set proposal distribution scale parameters
# (tune so proposals are acceptedl ~30% of the time)
proposal_params = (1e3, 1e3), 1e3, 1e3


### running inference

# make a runner function
run = model1(num_slopey, prior_params, camera_params, proposal_params, z, animate=False)

# run it
samples = run(num_iterations)


# plot the results, discarding half of the samples as warm-up
# (since initialization was random)
plot_samples(samples, z, T_cycle, warmup=num_iterations//2)
plt.show()
