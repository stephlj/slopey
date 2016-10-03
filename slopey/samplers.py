from __future__ import division
import numpy as np
import numpy.random as npr
import os

if not os.getenv('MATLAB'): from tqdm import tqdm
else: tqdm = lambda x: x


def run_mh(init_theta, joint_distn, proposal_distn, N, callback=None):
    logp_diff, log_p = joint_distn
    logq_diff, log_q, propose = proposal_distn

    def log_acceptance_prob(theta, new_theta):
        score = logp_diff(theta, new_theta) + logq_diff(theta, new_theta)
        return min(0., score)

    def flip_coin(p):
        return npr.uniform() < p

    def step(theta):
        new_theta = propose(theta)
        alpha = np.exp(log_acceptance_prob(theta, new_theta))
        accept = flip_coin(alpha)
        if callback: callback(alpha, theta, accept)
        return new_theta if accept else theta

    theta = init_theta
    thetas = []
    for n in tqdm(xrange(N)):
        theta = step(theta)
        thetas.append(theta)

    return thetas
