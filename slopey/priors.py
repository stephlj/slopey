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

def make_prior(prior_params):
    theta_params, ch2_transform_params = prior_params

    def log_prior_density(theta, ch2_transform):
        def logp_theta(theta):
            level_params, slopey_time_params, flat_time_params = theta_params
            logp_dwelltimes = gamma_log_density
            logp_levels = gamma_log_density

            times, vals = theta
            flat_times, slopey_times = split_dwelltimes(times)
            log_density_total = logp_levels(vals, level_params) \
                + logp_dwelltimes(slopey_times, slopey_time_params) \
                + logp_dwelltimes(flat_times, flat_time_params)

            return log_density_total

        def logp_ch2_transform(ch2_transform):
            a_params, b_params = ch2_transform_params
            a, b = ch2_transform
            return gamma_log_density(a, a_params) + gamma_log_density(b, b_params)

        return logp_theta(theta) + logp_ch2_transform(ch2_transform)

    def sample_prior(num_slopey_bits):
        def sample_theta(theta_params):
            level_params, slopey_time_params, flat_time_params = theta_params

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

        return sample_theta(theta_params), sample_ch2_transform(ch2_transform_params)

    return log_prior_density, sample_prior


### prior-based proposal distributions for MH

def make_proposal(proposal_params, T_cycle):
    theta_proposal_params, u_proposal_params, ch2_proposal_params = proposal_params

    def propose(params):
        theta, u, ch2_transform = params


        def propose_ch2_transform(ch2_transform):
            scale = ch2_proposal_params
            gamma_proposal = lambda x: gamma_sample((x*scale, scale))

            a, b = ch2_transform
            return gamma_proposal(a), max(gamma_proposal(b), 1e-8)

        def propose_u(u):
            scale = u_proposal_params
            frac = u / T_cycle
            alpha, beta = frac*scale, (1-frac)*scale
            return T_cycle * beta_sample((alpha, beta))

        def propose_theta(theta):
            def make_proposer(scale):
                propose_one = lambda x: gamma_sample((x*scale, scale))
                propose_list = lambda lst: map(propose_one, lst)
                return propose_list

            val_scale, time_scale = theta_proposal_params
            propose_vals = make_proposer(val_scale)
            propose_times = make_proposer(time_scale)

            times, vals = theta

            new_vals = propose_vals(vals)

            flat_times, slopey_times = split_dwelltimes(times)
            new_flat_times = propose_times(flat_times)
            new_slopey_times = propose_times(slopey_times)
            new_times = integrate_dwelltimes(new_flat_times, new_slopey_times)

            return np.array(new_times), np.array(new_vals)

        return propose_theta(theta), propose_u(u), propose_ch2_transform(ch2_transform)

    def log_q(new_params, params):
        (new_theta, new_u, new_ch2), (theta, u, ch2) = new_params, params

        def log_q_ch2(new_ch2, ch2):
            scale = ch2_proposal_params
            (new_a, new_b), (a, b) = new_ch2, ch2
            return gamma_log_density(new_a, (scale*a, scale)) \
                + gamma_log_density(new_b, (scale*b, scale))

        def log_q_u(new_u, u):
            scale = u_proposal_params
            new_frac, frac = new_u / T_cycle, u / T_cycle
            alpha, beta = frac*scale, (1-frac)*scale
            return beta_log_density(new_frac, (alpha, beta)) - np.log(T_cycle)

        def log_q_theta(new_theta, theta):
            def make_scorer(scale):
                score_one = lambda x_new, x: gamma_log_density(x_new, (x*scale, scale))
                score_lists = lambda lst_new, lst: sum(map(score_one, lst_new, lst))
                return score_lists

            val_scale, time_scale = theta_proposal_params
            score_vals = make_scorer(val_scale)
            score_times = make_scorer(time_scale)

            (new_times, new_vals), (times, vals) = new_theta, theta

            vals_score = score_vals(new_vals, vals)

            flat_times, slopey_times = split_dwelltimes(times)
            new_flat_times, new_slopey_times = split_dwelltimes(new_times)
            flat_score = score_times(new_flat_times, flat_times)
            slopey_score = score_times(new_slopey_times, slopey_times)
            times_score = flat_score + slopey_score

            return times_score + vals_score

        return log_q_theta(new_theta, theta) + log_q_u(new_u, u) + log_q_ch2(new_ch2, ch2)

    return log_q, propose


### internals

def split_dwelltimes(times):
    diffs = np.concatenate((times[:1], np.diff(times)))
    flat_times, slopey_times = diffs[::2], diffs[1::2]
    return flat_times, slopey_times


def integrate_dwelltimes(flat_times, slopey_times):
    def interleave(a, b):
        a, b = np.array(a), np.array(b)
        out = np.empty((a.size + b.size,), dtype=a.dtype)
        out[::2] = a
        out[1::2] = b
        return out

    return np.cumsum(interleave(flat_times, slopey_times))
