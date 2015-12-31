from __future__ import division
import numpy as np
import numpy.random as npr
import matplotlib.pyplot as plt

from slopey.priors import make_prior, make_proposal
from slopey.plotting import plot_theta

log_prior_density, sample_prior = make_prior((3., 1.), (6., 2.), (12., 2.))
theta = sample_prior(1)
u = npr.uniform()
x = theta, u

log_q, propose = make_proposal((200., 200.), 100., 1.)
new_x = new_theta, new_u = propose((theta, u))

print theta
print new_theta

print log_q(new_x, x)

plot_theta(theta)
plot_theta(new_theta)
plt.show()
