#!/usr/bin/env python
from __future__ import division
import numpy as np
import sys
import os
try:
  import cPickle as pickle
except ImportError:
  import pickle
from glob import glob
from os.path import join, basename, isfile, isdir, exists
from scipy.io import savemat

if os.getenv('USE_TQDM'): from tqdm import tqdm
else: tqdm = lambda x: x

def load_results(resultsfile):
    with open(resultsfile, 'rb') as infile:
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
        print('{} results_matfile_or_directory out.mat'.format(sys.argv[0]),
              file=sys.stderr)

    if not exists(resultsdir):
        print('...skipping {}'.format(resultsdir))
        sys.exit(0)

    if isfile(resultsdir):
        all_files = [resultsdir]
        all_results = dict(load_results(file) for file in all_files)
    else:
        all_files = glob(join(resultsdir, '*.results.pkl'))
        all_results = dict(load_results(file) for file in tqdm(all_files))

    savemat(outfile, all_results, long_field_names=True, oned_as='column')
