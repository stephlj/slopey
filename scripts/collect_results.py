#!/usr/bin/env python
from __future__ import division
import sys
import cPickle as pickle
from glob import glob
from os.path import join, basename
from scipy.io import savemat


def load_results(resultsfile):
    with open(resultsfile) as infile:
        results = pickle.load(infile)
    key = basename(resultsfile).split('.')[0]
    return key, results



if __name__ == '__main__':
    if len(sys.argv) == 3:
        resultsdir, outfile = sys.argv[1:]
    else:
        print >>sys.stderr, '{} results_directory out.mat'.format(sys.argv[0])

    all_files = glob(join(resultsdir, '*.results.pkl'))
    all_results = dict(map(load_results, all_files))

    savemat(outfile, all_results, long_field_names=True, oned_as='column')
