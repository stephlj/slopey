#!/usr/bin/env python
from __future__ import division
from __future__ import print_function
import numpy.random as npr
import sys
try:
  import cPickle as pickle
except ImportError:
  import pickle
import matplotlib.pyplot as plt
from os.path import splitext, isfile

from slopey.plotting import plot_samples, plot_prior


if __name__ == "__main__":
    if len(sys.argv) == 3:
        resultsfile, outfile = sys.argv[1:]
    else:
        print('{} results.pkl out.pdf'.format(sys.argv[0]), file=sys.stderr)
        sys.exit(1)

    if not isfile(resultsfile):
        print('...skipping {}'.format(resultsfile))
        sys.exit(0)

    with open(resultsfile, 'rb') as infile:
        results = pickle.load(infile)

    params, samples, data = results['params'], results['samples'], results['data']
    T_cycle, start, end = params['T_cycle'], params['start'], params['end']
    prior_params = (params['intensity_hypers'], params['slopey_time_hypers'],
                    params['flat_time_hypers']), params['ch2_transform_hypers']

    npr.seed(0)

    plot_samples(samples, data[start:end], T_cycle, warmup=len(samples)//2,
                 use_every_k_samples=max(25, len(samples)//(2*25)))
    plt.savefig(outfile)

    plot_prior(prior_params, T_cycle, len(data[start:end]), num_slopey=2, num_samples=20)
    basename, ext = splitext(outfile)
    plt.savefig(basename + '_prior' + ext)
