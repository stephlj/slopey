from __future__ import division
from __future__ import absolute_import
import numpy as np
import os

from slopey.fast import logq_diff, propose


def make_prior_proposer(prior_params, proposal_params, T_cycle):
    del prior_params  # Unused.
    (trace_proposal_params, u_proposal_params,
     ch2_proposal_params, sigma_proposal_params) = proposal_params

    def propose_cython(theta):
        return propose(
            theta,
            T_cycle, u_proposal_params,
            ch2_proposal_params, sigma_proposal_params, *trace_proposal_params)

    def logq_diff_cython(theta, new_theta):
        return logq_diff(
            theta, new_theta,
            T_cycle, u_proposal_params,
            ch2_proposal_params, sigma_proposal_params, *trace_proposal_params)

    return logq_diff_cython, propose_cython
