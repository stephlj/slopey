#!/usr/bin/env python
from __future__ import division
import numpy.random as npr
import sys
import cPickle as pickle

from slopey.load import load_data, load_params
from slopey.noise_models import make_gaussian_model
from slopey.analysis import model1, make_hmm_fit_initializer


def merge_dicts(*dcts):
    return reduce(lambda d1, d2: dict(d1, **d2), dcts)


def run_analysis(
        data, start, end, translocation_frame_guesses,
        num_iterations, proposal_params,
        intensity_hypers, slopey_time_hypers, flat_time_hypers, ch2_transform_hypers,
        T_cycle, T_blank, noise_sigmasq):

    # concatenate hyperparameters, make gaussian observation model
    trace_params = intensity_hypers, slopey_time_hypers, flat_time_hypers
    prior_params = trace_params, ch2_transform_hypers
    camera_params = T_cycle, T_blank, make_gaussian_model(noise_sigmasq)
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
        argspec = '{} raw_data.mat global_params.json [specific_params.json] outfile.pkl'
        print >>sys.stderr, argspec.format(sys.argv[0])
        sys.exit(1)

    data, defaults = load_data(datafile)
    params = merge_dicts(defaults, load_params(global_paramfile),
                         load_params(specific_paramfile) if specific_paramfile else {})

    if 'discard' in params:
        if params['discard']:
            print '...skipping {}'.format(datafile)
            sys.exit(0)
        else:
            del params['discard']

    npr.seed(0)
    samples = run_analysis(data, **params)

    with open(outfile, 'w') as outfile:
        pickle.dump({'params':params, 'data':data, 'samples':samples}, outfile, protocol=-1)
