from __future__ import division
import numpy as np
import numpy.random as npr
from scipy.special import gammaln, betaln
import matplotlib.pyplot as plt

from util import interleave


### primitive distributions

def beta_log_density(x, params, sum=True):
    alpha, beta = params
    logprobs = (alpha - 1) * np.log(x) + (beta - 1) * np.log(1-x) \
        - betaln(alpha, beta)
    return np.sum(logprobs) if sum else logprobs


def beta_sample(params, size=None):
    alpha, beta = params
    return np.clip(npr.beta(alpha, beta, size=size), 1e-6, 1. - 1e-6)


def gamma_log_density(x, params, sum=True):
    alpha, beta = params
    logprobs = alpha * np.log(beta) - gammaln(alpha) + (alpha-1)*np.log(x) - beta*x
    return np.sum(logprobs) if sum else logprobs


def gamma_sample(params, size=None):
    alpha, beta = params
    return np.maximum(1e-6, npr.gamma(alpha, 1./beta, size=size))


### util

def split_dwelltimes(times):
    diffs = np.concatenate((times[:1], np.diff(times)))
    flat_times, slopey_times = diffs[::2], diffs[1::2]
    return flat_times, slopey_times


def integrate_dwelltimes(flat_times, slopey_times):
    return np.cumsum(interleave(flat_times, slopey_times))


### prior on trace parameters theta = (x, u, ch2_transform)

def make_prior(prior_params):
    trace_params, ch2_transform_params = prior_params
    level_params, slopey_time_params, flat_time_params = trace_params

    def log_prior_density(theta):
        # NOTE: u is assumed uniform and so doesn't contribute
        x, u, ch2_transform = theta

        def logp_x(x):
            logp_dwelltimes = gamma_log_density
            logp_levels = gamma_log_density

            times, vals = x
            flat_times, slopey_times = split_dwelltimes(times)
            return logp_levels(vals, level_params) \
                + logp_dwelltimes(slopey_times, slopey_time_params) \
                + logp_dwelltimes(flat_times, flat_time_params)

        def logp_ch2_transform(ch2_transform):
            a_params, b_params = ch2_transform_params
            a, b = ch2_transform
            return gamma_log_density(a, a_params) + gamma_log_density(b, b_params)

        return logp_x(x) + logp_ch2_transform(ch2_transform)

    def sample_prior(num_slopey_bits, T_cycle):
        def sample_x(trace_params):
            sample_dwelltimes = gamma_sample
            sample_levels = gamma_sample

            flat_times = sample_dwelltimes(flat_time_params, num_slopey_bits)
            slopey_times = sample_dwelltimes(slopey_time_params, num_slopey_bits)
            times = integrate_dwelltimes(flat_times, slopey_times)
            vals = sample_levels(level_params, num_slopey_bits + 1)

            return times, vals

        def sample_ch2_transform(ch2_transform_params):
            a_params, b_params = ch2_transform_params
            return gamma_sample(a_params), gamma_sample(b_params)

        def sample_u():
            return npr.uniform() * T_cycle

        x = sample_x(trace_params)
        u = sample_u()
        ch2_transform = sample_ch2_transform(ch2_transform_params)

        return x, u, ch2_transform

    return log_prior_density, sample_prior
