from __future__ import division
import numpy as np
import numpy.random as npr
from tqdm import tqdm


def run_mh(init_theta, log_p, proposal_distn, N, callback=None):
    log_q, propose = proposal_distn

    def log_acceptance_prob(theta, new_theta):
        score = log_p(new_theta) - log_p(theta) \
            + log_q(theta, new_theta) - log_q(new_theta, theta)
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
