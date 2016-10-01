# distutils: extra_compile_args = -O3 -w -ffast-math
# distutils: libraries = gsl
# distutils: include_dirs = /opt/local/include
# distutils: library_dirs = /opt/local/lib
# cython: boundscheck=False, nonecheck=False, wraparound=False, cdivision=True

import numpy as np
cimport numpy as np

cdef extern from "gsl/gsl_sf_gamma.h":
    double gsl_sf_lngamma(double x)

cdef inline double integrate_affine(
        double slope, double x0, double y0, double a, double b):
    cdef double y_intercept = y0 - slope * x0
    return 0.5 * slope * (b**2 - a**2) + y_intercept * (b - a)

def noiseless_measurements(
        tuple x, double u,
        int num_frames, double T_cycle, double T_blank):
    cdef double[::1] times = x[0] - u
    cdef double[::1] vals = x[1]
    cdef double[::1] out = np.zeros(num_frames)
    cdef int K = times.shape[0]

    cdef int slopey = 1, k = 0, t = 0
    cdef double slope = 0., time = times[0], val = vals[0]
    cdef double start, cycle_end, shutter_close
    while t < num_frames:
        while t < num_frames and (k >= K or (t+1)*T_cycle < times[k]):
            out[t] = integrate_affine(
                slope, time, val, t*T_cycle, (t+1)*T_cycle - T_blank)
            t += 1

        if t < num_frames:
            start = t * T_cycle
            cycle_end = (t+1) * T_cycle
            shutter_close = cycle_end - T_blank
            while k < K and times[k] < cycle_end:
                if start < shutter_close:
                    out[t] += integrate_affine(
                        slope, time, val, start, min(times[k], shutter_close))
                start = times[k]
                k += 1
                slopey ^= 1
                slope = (vals[k-1] - vals[k]) / (times[k-1] - times[k]) \
                    if slopey else 0.
            time = times[k-1]
            val = vals[k-1]
            if start < shutter_close:
                out[t] += integrate_affine(slope, time, val, start, shutter_close)
            t += 1

        return np.asarray(out) / (T_cycle - T_blank)
