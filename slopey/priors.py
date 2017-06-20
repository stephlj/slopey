from __future__ import division
import numpy as np
import numpy.random as npr
from scipy.special import gammaln, betaln
import matplotlib.pyplot as plt

from util import interleave
from fast import logp_diff as logp_diff_fast


### primitive distributions

beta_negenergy = lambda x, alpha, beta: (alpha-1)*np.log(x) + (beta-1)*np.log(1-x)
beta_lognormalizer = lambda alpha, beta: betaln(alpha, beta)

gamma_negenergy = lambda x, alpha, beta: (alpha - 1.) * np.log(x) - beta * x
gamma_lognormalizer = lambda alpha, beta: gammaln(alpha) - alpha * np.log(beta)

uniform_negenergy = lambda x, low, high: \
        np.where((low <= x) & (x <= high), np.log(high - low), -np.inf)
uniform_lognormalizer = lambda low, high: 0.

def make_densities(negenergy, lognormalizer):
    def log_density(x, params, sum=True):
        logprobs = negenergy(x, *params) - lognormalizer(*params)
        return np.sum(logprobs) if sum else logprobs

    def make_log_density(params):
        logZ = lognormalizer(*params)
        def log_density(x, sum=True):
            logprobs = negenergy(x, *params) - logZ
            return np.sum(logprobs) if sum else logprobs
        return log_density

    return log_density, make_log_density

beta_log_density, make_beta_log_density = \
    make_densities(beta_negenergy, beta_lognormalizer)
gamma_log_density, make_gamma_log_density = \
    make_densities(gamma_negenergy, gamma_lognormalizer)
uniform_log_density, make_uniform_log_density = \
    make_densities(uniform_negenergy, uniform_lognormalizer)

def beta_sample(params, size=None):
    alpha, beta = params
    return np.clip(npr.beta(alpha, beta, size=size), 1e-6, 1. - 1e-6)

def gamma_sample(params, size=None):
    alpha, beta = params
    return np.maximum(1e-6, npr.gamma(alpha, 1./beta, size=size))

def uniform_sample(params, size=None):
    slopey_time_min, slopey_time_max = params
    return np.maximum(1e-6, npr.uniform(slopey_time_min, slopey_time_max, size=size))

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
    logp_levels = make_gamma_log_density(level_params)
    logp_slopeytimes = make_uniform_log_density(slopey_time_params)
    logp_flattimes = make_gamma_log_density(flat_time_params)

    a_params, b_params = ch2_transform_params
    logp_ch2transform_a, logp_ch2transform_b = \
        map(make_gamma_log_density, ch2_transform_params)

    def logp_x(x):
        times, vals = x
        flat_times, slopey_times = split_dwelltimes(times)
        return logp_levels(vals) + logp_slopeytimes(slopey_times) \
                + logp_flattimes(flat_times)

    def logp_ch2_transform(ch2_transform):
        a, b = ch2_transform
        return logp_ch2transform_a(a) + logp_ch2transform_b(b)

    def log_prior_density(theta):
        # NOTE: u is assumed uniform and so doesn't contribute
        x, u, ch2_transform = theta
        return logp_x(x) + logp_ch2_transform(ch2_transform)

    def sample_prior(num_slopey_bits, T_cycle):
        def sample_x(trace_params):
            flat_times = gamma_sample(flat_time_params, num_slopey_bits)
            slopey_times = uniform_sample(slopey_time_params, num_slopey_bits)
            times = integrate_dwelltimes(flat_times, slopey_times)
            vals = gamma_sample(level_params, num_slopey_bits + 1)
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

    def logp_diff(theta, new_theta):
        return logp_diff_fast(theta, new_theta, prior_params)

    return logp_diff, log_prior_density, sample_prior
