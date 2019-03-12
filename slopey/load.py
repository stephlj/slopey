from __future__ import division
import numpy as np
from scipy.io import loadmat
from re import compile
from string import strip
from collections import defaultdict
import yaml


def load_data(filepath):
    datadict = loadmat(filepath)
    get = lambda name: np.squeeze(datadict[name])

    # extract red and green channels
    zR, zG = get('unsmoothedRedI'), get('unsmoothedGrI')
    z = np.hstack((zR[:,None], zG[:,None]))

    # get defaults from HMM fit, can be overridden by params.yml
    durations = get('model_durations').ravel()
    start = get('start')
    # end = start + sum(durations)
    translocation_frame_guesses = np.cumsum(durations[:-1]) + start
    # Steph edited 3/2019 to not inherit start and end info from pyhsmm output
    start = 0
    end = len(zR)
    defaults = {'start': start, 'end': end,
                'translocation_frame_guesses': translocation_frame_guesses}

    return z, defaults

def load_params(filepath):
    with open(filepath) as infile:
        params = yaml.safe_load(infile)
    return {name: eval(val) if isinstance(val, str) else val
            for name, val in params.items()}
