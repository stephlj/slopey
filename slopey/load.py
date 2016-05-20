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
    zR, zG = get('unsmoothedRedI'), get('unsmoothedGrI')
    start, end = get('start'), sum(get('model_durations'))
    end = end+start
    num_slopey = len(get('model_durations').ravel()) - 1

    z = np.hstack((zR[:,None], zG[:,None]))
    defaults = {'start': start, 'end': end, 'num_slopey': num_slopey}

    return z, defaults

def load_params(filepath):
    with open(filepath) as infile:
        params = yaml.safe_load(infile)
    return {name: eval(val) if isinstance(val, str) else val
            for name, val in params.items()}
