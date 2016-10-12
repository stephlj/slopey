from __future__ import division
import numpy as np
import os

from priors import split_dwelltimes, integrate_dwelltimes, \
    beta_log_density, beta_sample, gamma_log_density, gamma_sample
from fast import logq_diff as logq_diff_fast, propose as propose_fast


def make_prior_proposer(proposal_params, T_cycle):
    trace_proposal_params, u_proposal_params, ch2_proposal_params = proposal_params

    def propose_cython(theta):
        return propose_fast(theta, T_cycle, u_proposal_params, ch2_proposal_params,
                            *trace_proposal_params)

    def propose(theta):
        x, u, ch2_transform = theta

        def propose_ch2_transform(ch2_transform):
            scale = ch2_proposal_params
            gamma_proposal = lambda x: gamma_sample((x*scale, scale))

            a, b = ch2_transform
            return gamma_proposal(a), gamma_proposal(b)

        def propose_u(u):
            scale = u_proposal_params
            frac = u / T_cycle
            alpha, beta = frac*scale, (1-frac)*scale
            return T_cycle * beta_sample((alpha, beta))

        def propose_x(x):
            def make_proposer(scale):
                propose_one = lambda x: gamma_sample((x*scale, scale))
                propose_list = lambda lst: map(propose_one, lst)
                return propose_list

            val_scale, time_scale = trace_proposal_params
            propose_vals = make_proposer(val_scale)
            propose_times = make_proposer(time_scale)

            times, vals = x

            new_vals = propose_vals(vals)

            flat_times, slopey_times = split_dwelltimes(times)
            new_flat_times = propose_times(flat_times)
            new_slopey_times = propose_times(slopey_times)
            new_times = integrate_dwelltimes(new_flat_times, new_slopey_times)

            return np.array(new_times), np.array(new_vals)

        new_x = propose_x(x)
        new_u = propose_u(u)
        new_ch2_transform = propose_ch2_transform(ch2_transform)

        return new_x, new_u, new_ch2_transform


    def logq(new_theta, theta):
        (new_x, new_u, new_ch2), (x, u, ch2) = new_theta, theta

        def logq_ch2(new_ch2, ch2):
            scale = ch2_proposal_params
            (new_a, new_b), (a, b) = new_ch2, ch2
            return gamma_log_density(new_a, (scale*a, scale)) \
                + gamma_log_density(new_b, (scale*b, scale))

        def logq_u(new_u, u):
            scale = u_proposal_params
            new_frac, frac = new_u / T_cycle, u / T_cycle
            alpha, beta = frac*scale, (1-frac)*scale
            return beta_log_density(new_frac, (alpha, beta)) - np.log(T_cycle)

        def logq_x(new_x, x):
            def make_scorer(scale):
                score_one = lambda x_new, x: gamma_log_density(x_new, (x*scale, scale))
                score_lists = lambda lst_new, lst: sum(map(score_one, lst_new, lst))
                return score_lists

            val_scale, time_scale = trace_proposal_params
            score_vals = make_scorer(val_scale)
            score_times = make_scorer(time_scale)

            (new_times, new_vals), (times, vals) = new_x, x

            vals_score = score_vals(new_vals, vals)

            flat_times, slopey_times = split_dwelltimes(times)
            new_flat_times, new_slopey_times = split_dwelltimes(new_times)
            flat_score = score_times(new_flat_times, flat_times)
            slopey_score = score_times(new_slopey_times, slopey_times)
            times_score = flat_score + slopey_score

            return times_score + vals_score

        return logq_x(new_x, x) + logq_u(new_u, u) + logq_ch2(new_ch2, ch2)

    def logq_diff(theta, new_theta):
        return logq_diff_fast(
            theta, new_theta, T_cycle, u_proposal_params, ch2_proposal_params,
            *trace_proposal_params)

    return logq_diff, logq, propose_cython
