#!/usr/bin/env python
from __future__ import division
import numpy.random as npr
import sys
import cPickle as pickle

from slopey.load import load_data, load_params
from slopey.noise_models import make_gaussian_model
from slopey.models import model1

def merge_dicts(*dcts):
    return reduce(lambda d1, d2: dict(d1, **d2), dcts)

def run_analysis(
        data, start, end, num_slopey,
        num_iterations, proposal_params,
        intensity_hypers, slopey_time_hypers, flat_time_hypers, ch2_transform_hypers,
        T_cycle, T_blank, noise_sigmasq):
    trace_params = intensity_hypers, slopey_time_hypers, flat_time_hypers
    prior_params = trace_params, ch2_transform_hypers
    camera_params = T_cycle, T_blank, make_gaussian_model(noise_sigmasq)

    run = model1(num_slopey, prior_params, camera_params, proposal_params, data, animate=False)
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

    npr.seed(0)
    samples = run_analysis(data, **params)

    with open(outfile, 'w') as outfile:
        pickle.dump({'params':params, 'data':data, 'samples':samples}, outfile, protocol=-1)
