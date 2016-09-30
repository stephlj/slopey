# distutils: extra_compile_args = -O3 -w
# distutils: libraries = gsl
# distutils: include_dirs = /opt/local/include
# distutils: library_dirs = /opt/local/lib
# cython: boundscheck=False, nonecheck=False, wraparound=False, cdivision=True

import numpy as np
cimport numpy as np

cdef extern from "gsl/gsl_sf_gamma.h":
    double gsl_sf_lngamma(double x)

def gammaln(double x):
     return gsl_sf_lngamma(x)
