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


### util

def fit_ch2_lstsq(ch1, ch2, fudge=1e-2):
    flip = lambda x: np.max(x) - x
    A = np.vstack([flip(ch1), np.ones_like(ch1)]).T
    a, b = scipy.optimize.nnls(A, ch2)[0]
    return max(a, fudge), max(b, fudge)


### initializers

def make_prior_initializer(num_slopey, T_cycle):
    return lambda: prior_sample(num_slopey, T_cycle)


def make_hmm_fit_initializer(T_cycle, translocation_frame_guesses, data, start, end, translocation_duration=0.2):
    # TODO make translocation_duration fudge a parameter, or depend on prior

    # compute translocation times from translocation_frame_guesses
    translocation_times = (translocation_frame_guesses - start) * T_cycle
    times = interleave(translocation_times - translocation_duration / 2,
                       translocation_times + translocation_duration / 2)

    # compute a corresponding set of vals by averaging over data
    idx = np.concatenate(((start,), translocation_frame_guesses, (end,)))
    ch1_vals =   np.array([np.mean(data[start:end, 0]) for start, end in zip(idx[:-1], idx[1:])])
    ch2_vals = np.array([np.mean(data[start:end, 1]) for start, end in zip(idx[:-1], idx[1:])])

    # compute a ch2 transform
    a, b = fit_ch2_lstsq(ch1_vals, ch2_vals)

    return lambda: ((times, ch1_vals), T_cycle * npr.uniform(), (a, b))


### models paired with inference algorithms

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
