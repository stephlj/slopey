# distutils: extra_compile_args = -O3 -w -ffast-math
# distutils: libraries = gsl
# distutils: include_dirs = /opt/local/include
# distutils: library_dirs = /opt/local/lib
# cython: boundscheck=False, nonecheck=False, wraparound=False, cdivision=True

import numpy as np
cimport numpy as np

from libc.math cimport log, exp

cdef extern from "gsl/gsl_sf_gamma.h":
    double gsl_sf_lngamma(double x)
    double gsl_sf_lnbeta(double a, double b)

cdef extern from "gsl/gsl_rng.h":
    ctypedef struct gsl_rng_type
    ctypedef struct gsl_rng
    gsl_rng_type *gsl_rng_mt19937
    gsl_rng *gsl_rng_alloc(gsl_rng_type * T) nogil

cdef extern from "gsl/gsl_randist.h":
    double gamma "gsl_ran_gamma"(gsl_rng * r, double, double)
    double beta "gsl_ran_beta"(gsl_rng * r, double, double)

cdef gsl_rng *r = gsl_rng_alloc(gsl_rng_mt19937)

cdef double dmin(double a, double b): return a if a < b else b
cdef double dmax(double a, double b): return a if a > b else b

### proposals

cdef inline void cumsum(double[::1] a):
    cdef int k, K = a.shape[0]
    for k in range(1,K):
        a[k] += a[k-1]

cdef inline double clip(double x, double low, double high):
    return dmin(dmax(x, low), high)

def propose(
        # input
        tuple theta,
        # constant needed for proposing u
        double T_cycle,
        # proposal scale parameters
        double u_scale, double ch2_scale,
        double val_scale, double time_scale):
    cdef double[::1] raw_times = theta[0][0]
    cdef double[::1] vals = theta[0][1]
    cdef double u = theta[1]
    cdef double a = theta[2][0]
    cdef double b = theta[2][1]

    cdef int K = raw_times.shape[0]

    cdef double[::1] times = np.zeros(K)
    diff(raw_times, times)

    # propose new times
    cdef double[::1] new_times = np.zeros(K)
    for k in range(K):
        new_times[k] = dmax(1e-6, gamma(r, times[k] * time_scale, 1./time_scale))
    cumsum(new_times)

    # propose new vals
    cdef double[::1] new_vals = np.zeros(K)
    for k in range(K):
        new_vals[k] = dmax(1e-6, gamma(r, vals[k] * val_scale, 1./val_scale))

    # propose new ch2_transform_params
    cdef double new_a, new_b
    new_a = dmax(1e-6, gamma(r, a * ch2_scale, 1./ch2_scale))
    new_b = dmax(1e-6, gamma(r, b * ch2_scale, 1./ch2_scale))

    # propose new u
    cdef double frac = u / T_cycle
    cdef double new_u = T_cycle * clip(beta(r, frac * u_scale, (1.-frac) * u_scale),
                                       1e-6, 1.-1e-6)

    return ((np.asarray(new_times), np.asarray(new_vals)), new_u, (new_a, new_b))

### acceptance prob

cdef inline double gamma_log_density(double x, double alpha, double beta):
    return (alpha-1.)*log(x) - beta*x - gsl_sf_lngamma(alpha) + alpha*log(beta)

cdef inline double beta_log_density(double x, double alpha, double beta):
    return (alpha-1.)*log(x) + (beta-1.)*log(1.-x) - gsl_sf_lnbeta(alpha, beta)

cdef inline void diff(double[::1] a, double[::1] out):
    cdef int k, K = a.shape[0]
    out[0] = a[0]
    for k in range(1, K):
        out[k] = a[k] - a[k-1]

def logq_diff(
        # inputs
        tuple theta, tuple new_theta,
        # constant needed for scoring u
        double T_cycle,
        # proposal scale parameters
        double u_scale, double ch2_scale,
        double val_scale, double time_scale):
    cdef double[::1] raw_times = theta[0][0]
    cdef double[::1] vals = theta[0][1]
    cdef double u = theta[1]
    cdef double a = theta[2][0]
    cdef double b = theta[2][1]

    cdef double[::1] new_raw_times = new_theta[0][0]
    cdef double[::1] new_vals = new_theta[0][1]
    cdef double new_u = new_theta[1]
    cdef double new_a = new_theta[2][0]
    cdef double new_b = new_theta[2][1]

    cdef int k, K = raw_times.shape[0]
    cdef double total = 0.

    cdef double[::1] times = np.zeros(K)
    cdef double[::1] new_times = np.zeros(K)
    diff(raw_times, times)
    diff(new_raw_times, new_times)

    # score times
    for k in range(K):
        total += gamma_log_density(times[k], new_times[k] * time_scale, time_scale) \
               - gamma_log_density(new_times[k], times[k] * time_scale, time_scale)

    # score vals
    for k in range(K):
        total += gamma_log_density(vals[k], new_vals[k] * val_scale, val_scale) \
               - gamma_log_density(new_vals[k], vals[k] * val_scale, val_scale)

    # score ch2
    total += gamma_log_density(a,     ch2_scale*new_a, ch2_scale) \
           + gamma_log_density(b,     ch2_scale*new_b, ch2_scale)
    total -= gamma_log_density(new_a, ch2_scale*a,     ch2_scale) \
           + gamma_log_density(new_b, ch2_scale*b,     ch2_scale)

    # score u
    cdef double frac = u / T_cycle, new_frac = new_u / T_cycle
    total += beta_log_density(frac,     new_frac * u_scale, (1.-new_frac) * u_scale) \
           - beta_log_density(new_frac,     frac * u_scale,     (1.-frac) * u_scale)

    return total

cdef inline double gamma_negenergy(double x, double alpha, double beta):
    return (alpha-1.)*log(x) - beta*x

def logp_diff(tuple theta, tuple new_theta, tuple prior_params):
    cdef double[::1] raw_times = theta[0][0]
    cdef double[::1] vals = theta[0][1]
    cdef double u = theta[1]
    cdef double a = theta[2][0]
    cdef double b = theta[2][1]

    cdef double[::1] new_raw_times = new_theta[0][0]
    cdef double[::1] new_vals = new_theta[0][1]
    cdef double new_u = new_theta[1]
    cdef double new_a = new_theta[2][0]
    cdef double new_b = new_theta[2][1]

    cdef double level_alpha = prior_params[0][0][0], \
                level_beta  = prior_params[0][0][1], \
                slopey_time_alpha = prior_params[0][1][0], \
                slopey_time_beta  = prior_params[0][1][1], \
                flat_time_alpha = prior_params[0][2][0], \
                flat_time_beta = prior_params[0][2][1], \
                a_alpha = prior_params[1][0][0], \
                a_beta  = prior_params[1][0][1], \
                b_alpha = prior_params[1][1][0], \
                b_beta  = prior_params[1][1][1]

    cdef int k, K = raw_times.shape[0]
    cdef double total = 0.

    cdef double[::1] times = np.zeros(K)
    cdef double[::1] new_times = np.zeros(K)
    diff(raw_times, times)
    diff(new_raw_times, new_times)

    # score times
    for k in range(0,K,2):
        total += gamma_negenergy(new_times[k],   flat_time_alpha,   flat_time_beta) \
               - gamma_negenergy(times[k],       flat_time_alpha,   flat_time_beta)
        total += gamma_negenergy(new_times[k+1], slopey_time_alpha, slopey_time_beta) \
               - gamma_negenergy(times[k+1],     slopey_time_alpha, slopey_time_beta)

    # score vals
    for k in range(K):
        total += gamma_negenergy(new_vals[k], level_alpha, level_beta) \
               - gamma_negenergy(vals[k],     level_alpha, level_beta)

    # score ch2
    total += gamma_negenergy(new_a, a_alpha, a_beta) \
           - gamma_negenergy(a,     a_alpha, a_beta)
    total += gamma_negenergy(new_b, b_alpha, b_beta) \
           - gamma_negenergy(b,     b_alpha, b_beta)

    # NOTE: we don't score u because we assume the prior is uniform

    return total

### camera model

cdef inline double integrate_affine(
        double slope, double x0, double y0, double a, double b):
    cdef double y_intercept = y0 - slope * x0
    return 0.5 * slope * (b**2 - a**2) + y_intercept * (b - a)

def loglike(tuple theta, double[:,::1] z, double sigmasq, double T_cycle, double T_blank):
    cdef double u = theta[1]
    cdef double a = theta[2][0]
    cdef double b = theta[2][1]
    cdef double[::1] times = theta[0][0] - u
    cdef double[::1] vals = theta[0][1]
    cdef int num_frames = z.shape[0]

    cdef double[::1] y_red = np.zeros(num_frames)
    cdef double scale = 1. / (T_cycle - T_blank)
    cdef int K = times.shape[0]

    ### put noiseless measurements of red channel into y_red

    cdef int slopey = 0, k = 0, t = 0
    cdef double slope = 0., time = times[0], val = vals[0]
    cdef double start, cycle_end, shutter_close
    while t < num_frames:
        while t < num_frames and (k >= K or (t+1)*T_cycle < times[k]):
            y_red[t] = scale * integrate_affine(
                slope, time, val, t*T_cycle, (t+1)*T_cycle - T_blank)
            t += 1

        if t < num_frames:
            start = t * T_cycle
            cycle_end = (t+1) * T_cycle
            shutter_close = cycle_end - T_blank
            while k < K and times[k] < cycle_end:
                if start < shutter_close:
                    y_red[t] += scale * integrate_affine(
                        slope, time, val, start, dmin(times[k], shutter_close))
                start = times[k]
                k += 1
                slopey ^= 1
                slope = (vals[k-1] - vals[k]) / (times[k-1] - times[k]) \
                    if slopey else 0.
            time = times[k-1]
            val = vals[k-1]
            if start < shutter_close:
                y_red[t] += scale * integrate_affine(slope, time, val, start, shutter_close)
            t += 1

    ### compute green channel and loglike under gaussian model

    cdef double ll = 2*num_frames*(-1./2 * log(np.pi) - 1./2 * log(sigmasq))
    cdef double y_green
    cdef double x_red_max = np.max(vals)
    for t in range(num_frames):
        y_green = -a * y_red[t] + (b + a*x_red_max)
        ll += -1./2 * ((z[t,0] - y_red[t])**2 + (z[t,1] - y_green)**2) / sigmasq

    return ll
