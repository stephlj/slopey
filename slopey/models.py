from __future__ import division
import numpy as np
import numpy.random as npr

from priors import make_prior, make_proposal
from camera_model import make_camera_model
from samplers import run_mh
from plotting import make_animation_callback

def ensure_2d(z):
    z = np.squeeze(z)
    assert z.ndim == 2 and z.shape[1] == 2
    return z

def model1(num_slopey, prior_params, camera_params, proposal_params, z, animate=False):
    z = ensure_2d(z)
    T_cycle, _, _ = camera_params

    # build the model densities, a prior and a likelihood
    log_prior_density, prior_sample = make_prior(prior_params)
    camera_loglike, _ = make_camera_model(camera_params)

    # define the joint distribution as the prior times the likelihood
    def log_p(theta):
        return camera_loglike(z, theta) + log_prior_density(theta)

    # set up inference
    proposal_distn = make_proposal(proposal_params, T_cycle)

    # make a callback to print how often proposals are accepted
    accepts = []
    if animate:
        animation_callback = make_animation_callback(z, T_cycle)
        def callback(alpha, theta, accept):
            accepts.append(accept)
            animation_callback(alpha, theta, accept)
    else:
        def callback(alpha, theta, accept):
            accepts.append(accept)

    # make an initial guess by sampling from the prior
    theta_init = prior_sample(num_slopey, T_cycle)

    # make a runner function
    samples = [theta_init]
    def run(num_iter):
        new_samples = run_mh(samples[-1], log_p, proposal_distn, num_iter, callback)
        samples.extend(new_samples)
        print 'accept proportion: %0.3f' % np.mean(accepts)
        return samples

    return run
