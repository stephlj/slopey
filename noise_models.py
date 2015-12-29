from __future__ import division
import numpy as np
import numpy.random as npr

def make_poisson_model(gain):
    def sample(y):
        return npr.poisson(y*gain)

    def loglike(y, z):
        lmbda = y * gain
        return np.sum(-lmbda + z*np.log(lmbda) - gammaln(z+1))

    return loglike, sample


def make_gaussian_model(sigmasq):
    def sample(y):
        return npr.normal(y, np.sqrt(sigmasq))

    def loglike(y, z):
        constant = -1./2*np.log(2*np.pi) - 1./2 * np.log(sigmasq)
        return np.sum(constant - 1./2 * (z - y)**2 / sigmasq)

    return loglike, sample
