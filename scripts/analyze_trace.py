#!/usr/bin/env python
from __future__ import division
from __future__ import print_function
import numpy.random as npr
import sys
from functools import reduce
try:
  import cPickle as pickle
except ImportError:
  import pickle

from slopey.load import load_data, load_params
from slopey.analysis import model1, make_hmm_fit_initializer
from slopey.fast import set_seed


def merge_dicts(*dcts):
    return reduce(lambda d1, d2: dict(d1, **d2), dcts)


# TODO get rid of slopey_time_hypers
def run_analysis(
        data, start, end, translocation_frame_guesses,
        num_iterations, proposal_params,
        intensity_hypers, slopey_time_hypers, flat_time_hypers, ch2_transform_hypers,
        T_cycle, T_blank):

    # concatenate hyperparameters, make gaussian observation model
    trace_params = intensity_hypers, slopey_time_hypers, flat_time_hypers
    prior_params = trace_params, ch2_transform_hypers
    camera_params = T_cycle, T_blank
    model_params = prior_params, camera_params

    # create initializer function
    initializer = make_hmm_fit_initializer(T_cycle, translocation_frame_guesses, data, start, end)

    # construct the sampler and run it
    run = model1(model_params, proposal_params, data[start:end], initializer)
    samples = run(num_iterations)

    return samples


if __name__ == "__main__":
    if len(sys.argv) == 4:
        datafile, global_paramfile, outfile = sys.argv[1:]
        specific_paramfile = None
    elif len(sys.argv) == 5:
        datafile, global_paramfile, specific_paramfile, outfile = sys.argv[1:]
    else:
        argspec = '{} raw_data.mat global_params.yml [specific_params.yml] outfile.pkl'
        print(argspec.format(sys.argv[0]), file=sys.stderr)
        sys.exit(1)

    data, defaults = load_data(datafile)
    params = merge_dicts(defaults, load_params(global_paramfile),
                         load_params(specific_paramfile) if specific_paramfile else {})

    if 'discard' in params:
        if params['discard']:
            print('...skipping {}'.format(datafile))
            sys.exit(0)
        else:
            del params['discard']

    npr.seed(0)
    set_seed(0)
    samples = run_analysis(data, **params)

    with open(outfile, 'wb') as outfile:
        pickle.dump({'params':params, 'data':data, 'samples':samples}, outfile, protocol=-1)
