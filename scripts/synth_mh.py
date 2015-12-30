from __future__ import division
import numpy as np
import numpy.random as npr

from slopey.samplers import run_mh
from slopey.priors import make_prior, make_proposal, plot_theta
from slopey.camera_model import make_camera_model
from slopey.noise_models import make_gaussian_model


# set up synthetic trace and frame offset
times = np.array([1., 1.5])
vals = np.array([5., 1.])
theta = times, vals

u = npr.uniform()
x = theta, u

# instantiate camera model
camera_loglike, camera_sample = \
    make_camera_model(0.1, 0.01, make_gaussian_model(0.01))

# generate frame data
z = camera_sample(theta, u, 45)

# set up prior
log_prior_density, _ = make_prior((3., 1.), (6., 2.), (12., 2.))

# define joint distribution
def log_p(x):
    theta, u = x
    return camera_loglike(z, theta, u) + log_prior_density(theta)

# set up proposal distribution
proposal_distn = make_proposal((1e4, 1e4), 1e3)

# run mh starting from the truth
samples = run_mh(x, log_p, proposal_distn, 10)
