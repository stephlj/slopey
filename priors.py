from __future__ import division
import numpy as np
import numpy.random as npr
from scipy.special import gammaln, betaln
import matplotlib.pyplot as plt


### primitive distributions

def beta_log_density(x, params):
    alpha, beta = params
    logprobs = (alpha - 1) * np.log(x) + (beta - 1) * np.log(1-x) \
        - betaln(alpha, beta)
    return np.sum(logprobs)


def beta_sample(params, size=None):
    alpha, beta = params
    return npr.beta(alpha, beta, size=size)


def gamma_log_density(x, params):
    alpha, beta = params
    logprobs = alpha * np.log(beta) - gammaln(alpha) + (alpha-1)*np.log(x) - beta*x
    return np.sum(logprobs)


def gamma_sample(params, size=None):
    alpha, beta = params
    return npr.gamma(alpha, 1./beta, size=size)


### prior on traces (theta)

def make_prior(level_params, slopey_time_params, flat_time_params):
    def log_prior_density(theta):
        times, vals = theta
        flat_times, slopey_times = split_dwelltimes(times)
        return logp_levels(vals, level_params) \
            + logp_dwelltimes(slopey_times, slopey_time_params) \
            + logp_dwelltimes(flat_times, flat_time_params)

    def sample_prior(num_slopey_bits):
        flat_times = sample_dwelltimes(flat_time_params, num_slopey_bits)
        slopey_times = sample_dwelltimes(slopey_time_params, num_slopey_bits)
        times = integrate_dwelltimes(flat_times, slopey_times)
        vals = sample_levels(level_params, num_slopey_bits + 1)
        return times, vals

    def split_dwelltimes(times):
        diffs = np.concatenate((times[:1], np.diff(times)))
        flat_times, slopey_times = diffs[::2], diffs[1::2]
        return flat_times, slopey_times

    def integrate_dwelltimes(flat_times, slopey_times):
        def interleave(a, b):
            out = np.empty((a.size + b.size,), dtype=a.dtype)
            out[::2] = a
            out[1::2] = b
            return out

        return np.cumsum(interleave(flat_times, slopey_times))

    # TODO these should really be factored out as arguments
    logp_dwelltimes = gamma_log_density
    logp_levels = gamma_log_density
    sample_dwelltimes = gamma_sample
    sample_levels = gamma_sample

    return log_prior_density, sample_prior


### proposal distributions for MH

# the proposal is over the pair (theta, u)

def make_proposal(theta_proposal_params, u_proposal_params):
    def log_q(new_params, params):
        (new_theta, new_u), (theta, u) = new_params, params
        return log_q_theta(new_theta, theta) + log_q_u(new_u, u)

    def propose(params):
        theta, u = params
        new_theta = propose_theta(theta)
        new_u = propose_u(u)
        return new_theta, new_u

    def log_q_theta(new_theta, theta):
        pass  # TODO

    def log_q_u(new_u, u):
        pass  # TODO

    def propose_theta(theta):
        pass  # TODO

    def propose_u(u):
        pass  # TODO

    return log_q, propose


### plotting

def plot_theta(theta):
    times, vals = theta

    def get_points(times, vals):
        times = [0.] + list(times) + [times[-1] + 1]
        return times, np.repeat(vals, 2)

    xs, ys = get_points(times, vals)

    plt.plot(xs, ys)
    plt.ylim(0., np.max(ys) + 1.)
