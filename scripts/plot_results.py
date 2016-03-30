#!/usr/bin/env python
from __future__ import division
import numpy.random as npr
import sys
import cPickle as pickle
import matplotlib.pyplot as plt

from slopey.plotting import plot_samples


if __name__ == "__main__":
    if len(sys.argv) == 3:
        resultsfile, outfile = sys.argv[1:]
    else:
        print >>sys.stderr, '{} results.pkl out.pdf'.format(sys.argv[0])
        sys.exit(1)

    with open(resultsfile) as infile:
        results = pickle.load(infile)

    params, samples, data = results['params'], results['samples'], results['data']
    T_cycle = params['T_cycle']

    npr.seed(0)
    plot_samples(samples, data, T_cycle, warmup=len(samples)//2)

    plt.savefig(outfile)
