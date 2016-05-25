from __future__ import division
import numpy as np
import numpy.random as npr
import scipy.optimize

from priors import make_prior
from proposals import make_prior_proposer
from camera_model import make_camera_model
from samplers import run_mh
from plotting import make_animation_callback
from util import ensure_2d, interleave


def fit_ch2_lstsq(data, fudge=1e-2):
    flip = lambda x: np.max(x) - x
    A = np.vstack([flip(data[:,0]), np.ones_like(data[:,0])]).T
    B = data[:,1]
    a, b = scipy.optimize.nnls(A, B)[0]
    return max(a, fudge), max(b, fudge)


def make_prior_initializer(num_slopey, T_cycle):
    return lambda: prior_sample(num_slopey, T_cycle)


def make_hmm_fit_initializer(T_cycle, translocation_frame_guesses, data, translocation_duration=0.2):
    translocation_times = translocation_frame_guesses * T_cycle
    times = interleave(translocation_times - translocation_duration / 2,
                       translocation_times + translocation_duration / 2)
    idx = np.concatenate(((0,), translocation_frame_guesses, (-1,)))
    vals = np.array([np.mean(data[start:end, 0])
                     for start, end in zip(idx[:-1], idx[1:])])
    a, b = fit_ch2_lstsq(data)
    return lambda: ((times, vals), T_cycle * npr.uniform(), (a, b))


def model1(model_params, proposal_params, data, initializer, animate=False):
    prior_params, camera_params = model_params
    data = ensure_2d(data)
    T_cycle, _, _ = camera_params

    # build the model densities, a prior and a likelihood
    log_prior_density, prior_sample = make_prior(prior_params)
    camera_loglike = make_camera_model(camera_params)

    # define the joint distribution as the prior times the likelihood
    def log_p(theta):
        return camera_loglike(data, theta) + log_prior_density(theta)

    # set up inference
    proposal_distn = make_prior_proposer(proposal_params, T_cycle)

    # make a callback to print how often proposals are accepted
    accepts = []
    if animate:
        animation_callback = make_animation_callback(data, T_cycle)
        def callback(alpha, theta, accept):
            accepts.append(accept)
            animation_callback(alpha, theta, accept)
    else:
        def callback(alpha, theta, accept):
            accepts.append(accept)

    # make a runner function
    samples = [initializer()]
    def run(num_iter):
        new_samples = run_mh(samples[-1], log_p, proposal_distn, num_iter, callback)
        samples.extend(new_samples)
        print 'accept proportion: %0.3f' % np.mean(accepts)
        return samples

    return run
