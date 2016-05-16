#!/usr/bin/env python
from __future__ import division
import numpy as np
import sys
import cPickle as pickle
from glob import glob
from os.path import join, basename
from scipy.io import savemat

def load_results(resultsfile):
    with open(resultsfile) as infile:
        results = pickle.load(infile)
    experiment_name = basename(resultsfile).split('.')[0]
    return experiment_name, flatten_results(results)


def flatten_results(results):
    params, data, samples = results['params'], results['data'], results['samples']
    x_samples, u_samples, ch2_samples = zip(*samples)
    times_samples, vals_samples = map(np.array, zip(*x_samples))
    u_samples, ch2_samples = map(np.array, (u_samples, ch2_samples))

    return {'params': params, 'data': data,
            'times_samples': times_samples, 'vals_samples': vals_samples,
            'u_samples': u_samples, 'ch2_samples': ch2_samples}


if __name__ == '__main__':
    if len(sys.argv) == 3:
        resultsdir, outfile = sys.argv[1:]
    else:
        print >>sys.stderr, '{} results_directory out.mat'.format(sys.argv[0])

    all_files = glob(join(resultsdir, '*.results.pkl'))
    all_results = dict(load_results(file) for file in all_files)

    savemat(outfile, all_results, long_field_names=True, oned_as='column')
