from __future__ import division
from __future__ import absolute_import
import numpy as np
import os
from collections import namedtuple

from slopey.fast import logq_diff as logq_diff_locals_, propose as propose_locals_
from slopey.priors import gamma_sample, gamma_log_density

Theta = namedtuple('Theta', ['globals', 'locals'])


def make_prior_proposer(prior_params, proposal_params, T_cycle):
    del prior_params  # Unused.
    (global_prop_scale, trace_proposal_params, u_proposal_params,
     ch2_proposal_params, sigma_proposal_params) = proposal_params

    def propose_locals(local_vars):
        return propose_locals_(local_vars, T_cycle, u_proposal_params,
                               ch2_proposal_params, sigma_proposal_params,
                               *trace_proposal_params)

    def logq_diff_locals(local_vars, new_local_vars):
        return logq_diff_locals_(local_vars, new_local_vars, T_cycle,
                                 u_proposal_params, ch2_proposal_params,
                                 sigma_proposal_params, *trace_proposal_params)

    def propose_globals(ab):
        a, b = ab
        new_a = gamma_sample((a * global_prop_scale, global_prop_scale))
        new_b = gamma_sample((b * global_prop_scale, global_prop_scale))
        return new_a, new_b

    def logq_diff_globals(ab, new_ab):
        tot = 0.
        tot += gamma_log_density(a, (new_a * global_prop_scale, global_prop_scale)) \
             - gamma_log_density(new_a, (a * global_prop_scale, global_prop_scale))
        tot += gamma_log_density(b, (new_b * global_prop_scale, global_prop_scale)) \
             - gamma_log_density(new_b, (b * global_prop_scale, global_prop_scale))
        return tot

    def propose(theta):
        new_globals = propose_globals(theta.globals)
        new_locals = [propose_locals(local_vars) for local_vars in theta.locals]
        return Theta(globals=new_globals, locals=new_locals)

    def logq_diff(theta, new_theta):
        tot = 0.
        tot += logq_diff_globals(theta.globals, new_theta.globals)
        for local_vars, new_local_vars in zip(theta.locals, new_theta.locals):
            tot += logq_diff_locals(local_vars, new_local_vars)
        return tot

    return logq_diff, propose
