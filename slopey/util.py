from __future__ import division
import numpy as np

def ensure_2d(z):
    z = np.squeeze(z)
    assert z.ndim == 2 and z.shape[1] == 2
    return z

def interleave(a, b):
    a, b = np.array(a), np.array(b)
    out = np.empty((a.size + b.size,), dtype=a.dtype)
    out[::2] = a
    out[1::2] = b
    return out
