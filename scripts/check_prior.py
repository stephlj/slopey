from __future__ import division
import numpy as np
import matplotlib.pyplot as plt

from slopey.priors import make_prior, plot_theta

log_prior_density, sample_prior = make_prior((3., 1.), (6., 2.), (12., 2.))
theta = sample_prior(1)

print theta
print log_prior_density(theta)

plot_theta(theta)
plt.show()
