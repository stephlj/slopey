# distutils: extra_compile_args = -O3 -w -ffast-math
# distutils: extra_link_args = -lm
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

cdef extern from "gsl/gsl_sf_psi.h":
    cdef double gsl_sf_psi_1(double x);

cdef extern from "gsl/gsl_rng.h":
    ctypedef struct gsl_rng_type
    ctypedef struct gsl_rng
    gsl_rng_type *gsl_rng_mt19937
    gsl_rng *gsl_rng_alloc(gsl_rng_type * T) nogil
    void gsl_rng_set(gsl_rng *r, unsigned long int s)

cdef extern from "gsl/gsl_randist.h":
    double gamma "gsl_ran_gamma"(gsl_rng * r, double, double)
    double beta "gsl_ran_beta"(gsl_rng * r, double, double)

cdef gsl_rng *r = gsl_rng_alloc(gsl_rng_mt19937)
gsl_rng_set(r, 0)  # should be seeded by env var, but this is just to make sure

cdef inline double dmin(double a, double b): return a if a < b else b
cdef inline double dmax(double a, double b): return a if a > b else b

cdef double PI = 3.141592653589793
cdef double EPS = 1e-8

cdef int NUM_SLOPEY_MAX = 25
cdef double[::1] _times = np.zeros(NUM_SLOPEY_MAX)
cdef double[::1] _new_times = np.zeros(NUM_SLOPEY_MAX)
cdef double[::1] _new_vals = np.zeros(NUM_SLOPEY_MAX//2+1)

cdef int NUM_FRAMES_MAX = 50000
cdef double[::1] _y_red = np.zeros(NUM_FRAMES_MAX)

### proposals

cdef inline void diff(double[::1] a, double[::1] out):
    # like np.diff(np.concatenate(((0,), a)))
    cdef int k, K = a.shape[0]
    out[0] = a[0]
    for k in range(1, K):
        out[k] = a[k] - a[k-1]

cdef inline void cumsum(double[::1] a):
    # destructive cumsum just like np.cumsum
    cdef int k, K = a.shape[0]
    for k in range(1,K):
        a[k] += a[k-1]

cdef inline double clip(double x, double low, double high):
    return dmin(dmax(x, low), high)

def propose(
        # input
        tuple theta,
        # constants
        double T_cycle,
        double slopey_time_min, double slopey_time_max,
        # proposal scale parameters
        double u_scale, double ch2_scale,
        double val_scale, double time_scale):
    cdef double[::1] raw_times = theta[0][0]
    cdef double[::1] vals = theta[0][1]
    cdef double u = theta[1]
    cdef double a = theta[2][0]
    cdef double b = theta[2][1]

    cdef int k, K = raw_times.shape[0]
    cdef double frac

    cdef double[::1] times = _times[:K]
    diff(raw_times, times)

    # propose new times
    cdef double[::1] new_times = _new_times[:K]
    for k in range(0,K,2):
        new_times[k] = dmax(EPS, gamma(r, times[k] * time_scale, 1./time_scale))

        frac = (times[k+1] - slopey_time_min) / (slopey_time_max - slopey_time_min)
        new_times[k+1] = slopey_time_min + (slopey_time_max - slopey_time_min) \
                * clip(beta(r, frac * time_scale, (1.-frac) * time_scale), EPS, 1.-EPS)
    cumsum(new_times)

    # propose new vals
    cdef double[::1] new_vals = _new_vals[:(K//2+1)]
    for k in range(K//2+1):
        new_vals[k] = dmax(EPS, gamma(r, vals[k] * val_scale, 1./val_scale))

    # propose new ch2_transform_params
    cdef double new_a, new_b
    new_a = dmax(EPS, gamma(r, a * ch2_scale, 1./ch2_scale))
    new_b = dmax(EPS, gamma(r, b * ch2_scale, 1./ch2_scale))

    # propose new u
    frac = u / T_cycle
    cdef double new_u = T_cycle * clip(beta(r, frac * u_scale, (1.-frac) * u_scale),
                                       EPS, 1.-EPS)

    return ((np.array(new_times, copy=True), np.array(new_vals, copy=True)),
            new_u, (new_a, new_b))

### acceptance prob

cdef inline double gamma_log_density(double x, double alpha, double beta):
    return (alpha-1.)*log(x) - beta*x - gsl_sf_lngamma(alpha) + alpha*log(beta)

cdef inline double beta_log_density(double x, double alpha, double beta):
    return (alpha-1.)*log(x) + (beta-1.)*log(1.-x) - gsl_sf_lnbeta(alpha, beta)

def logq_diff(
        # inputs
        tuple theta, tuple new_theta,
        # constants
        double T_cycle,
        double slopey_time_min, double slopey_time_max,
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
    cdef double frac, new_frac
    cdef double total = 0.

    cdef double[::1] times = _times[:K]
    cdef double[::1] new_times = _new_times[:K]
    diff(raw_times, times)
    diff(new_raw_times, new_times)

    # score times
    for k in range(0, K, 2):
        total += gamma_log_density(times[k], new_times[k] * time_scale, time_scale) \
               - gamma_log_density(new_times[k], times[k] * time_scale, time_scale)

        frac = (times[k+1] - slopey_time_min) / (slopey_time_max - slopey_time_min)
        new_frac = (new_times[k+1] - slopey_time_min) / (slopey_time_max - slopey_time_min)
        total += beta_log_density(frac, new_frac * time_scale, (1.-new_frac) * time_scale) \
               - beta_log_density(new_frac, frac * time_scale,     (1.-frac) * time_scale)

    # score vals
    for k in range(K//2+1):
        total += gamma_log_density(vals[k], new_vals[k] * val_scale, val_scale) \
               - gamma_log_density(new_vals[k], vals[k] * val_scale, val_scale)

    # score ch2
    total += gamma_log_density(a,     ch2_scale*new_a, ch2_scale) \
           + gamma_log_density(b,     ch2_scale*new_b, ch2_scale)
    total -= gamma_log_density(new_a, ch2_scale*a,     ch2_scale) \
           + gamma_log_density(new_b, ch2_scale*b,     ch2_scale)

    # score u
    frac = u / T_cycle
    new_frac = new_u / T_cycle
    total += beta_log_density(frac,     new_frac * u_scale, (1.-new_frac) * u_scale) \
           - beta_log_density(new_frac,     frac * u_scale,     (1.-frac) * u_scale)

    return total

cdef inline double gamma_negenergy(double x, double alpha, double beta):
    return (alpha-1.)*log(x) - beta*x

cdef inline double beta_negenergy(double x, double alpha, double beta):
    return (alpha-1.)*log(x) - (beta-1) * log(1.-x)

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
                slopey_time_min = prior_params[0][1][0], \
                slopey_time_max  = prior_params[0][1][1], \
                flat_time_alpha = prior_params[0][2][0], \
                flat_time_beta = prior_params[0][2][1], \
                a_alpha = prior_params[1][0][0], \
                a_beta  = prior_params[1][0][1], \
                b_alpha = prior_params[1][1][0], \
                b_beta  = prior_params[1][1][1]

    cdef int k, K = raw_times.shape[0]
    cdef double frac, new_frac
    cdef double total = 0.

    cdef double[::1] times = _times[:K]
    cdef double[::1] new_times = _new_times[:K]
    diff(raw_times, times)
    diff(new_raw_times, new_times)

    # score times
    for k in range(0,K,2):
        total += gamma_negenergy(new_times[k],   flat_time_alpha,   flat_time_beta) \
               - gamma_negenergy(times[k],       flat_time_alpha,   flat_time_beta)

        # NOTE(mattjj): we don't score slopey times because we assume the prior
        # is uniform, but it would look something like this:
        # # frac = (times[k+1] - slopey_time_min) / (slopey_time_max - slopey_time_min)
        # # new_frac = (new_times[k+1] - slopey_time_min) / (slopey_time_max - slopey_time_min)
        # # total += beta_negenergy(new_frac,   slopey_time_alpha,   slopey_time_beta) \
        # #        - beta_negenergy(frac,       slopey_time_alpha,   slopey_time_beta)

    # score vals
    for k in range(K//2+1):
        total += gamma_negenergy(new_vals[k], level_alpha, level_beta) \
               - gamma_negenergy(vals[k],     level_alpha, level_beta)

    # score ch2
    total += gamma_negenergy(new_a, a_alpha, a_beta) \
           - gamma_negenergy(a,     a_alpha, a_beta)
    total += gamma_negenergy(new_b, b_alpha, b_beta) \
           - gamma_negenergy(b,     b_alpha, b_beta)

    # NOTE(mattjj):: we don't score u because we assume the prior is uniform

    return total

### camera model

cdef inline double integrate_affine(
        double slope, double x0, double y0, double a, double b):
    cdef double y_intercept = y0 - slope * x0
    return 0.5 * slope * (b**2 - a**2) + y_intercept * (b - a)

cdef inline double amax(double[::1] a):
    cdef int k, K = a.shape[0]
    cdef double themax = a[0]
    for k in range(1,K):
        themax = dmax(themax, a[k])
    return themax

cdef inline void zero_out(double[::1] a):
    cdef int k, K = a.shape[0]
    for k in range(K):
        a[k] = 0.

def loglike(tuple theta, double[:,::1] z, double sigmasq, double T_cycle, double T_blank):
    cdef double u = theta[1]
    cdef double a = theta[2][0]
    cdef double b = theta[2][1]
    cdef double[::1] times = theta[0][0] - u
    cdef double[::1] vals = theta[0][1]
    cdef int num_frames = z.shape[0]

    cdef double[::1] y_red = _y_red[:num_frames]
    cdef double scale = 1. / (T_cycle - T_blank)
    cdef int K = times.shape[0]

    zero_out(y_red)

    ### put noiseless measurements of red channel into y_red

    # k = 0 is before first slopey bit, k = 1 is during first slopey bit, etc.
    # for 0 <= k < K,  times[k] is next changepoint
    # for 1 <= k <= K, times[k-1] is previous changepoint
    # for k >= 0, vals[k//2] is value on the left, vals[(k+1)//2] is value on the right

    # (time, val) is set to a valid point for the current segment, either left or right

    cdef int k = 0, t = 0
    cdef double slope = 0., time = times[0], val = vals[0]
    cdef double start, cycle_end, shutter_close
    while t < num_frames:
        # while there are no changepoints and still some frames left, keep integrating
        while t < num_frames and (k >= K or (t+1)*T_cycle < times[k]):
            y_red[t] = scale * integrate_affine(
                slope, time, val, t*T_cycle, (t+1)*T_cycle - T_blank)
            t += 1

        # there's a changepoint in the next frame
        if t < num_frames:
            # start is where we're integrating from on the left
            start = t * T_cycle
            cycle_end = (t+1) * T_cycle
            shutter_close = cycle_end - T_blank
            # while the next changepoint is in the current frame
            while k < K and times[k] < cycle_end:
                # integrate up until the next changepoint (or shutter close)
                if start < shutter_close:
                    y_red[t] += scale * integrate_affine(
                        slope, time, val, start, dmin(times[k], shutter_close))
                # increment our changepoint index, update start
                k += 1
                start = times[k-1]
                # update the slope to reflect the current segment we're in
                slope = (vals[k//2] - vals[(k+1)//2]) / (times[k-1] - times[k])
                # set time/val to the left-side values
                time = times[k-1]
                val = vals[k//2]
            # we're done with changepoints for this frame, but we may still have
            # some integration to do from start to the shutter close
            if start < shutter_close:
                y_red[t] += scale * integrate_affine(slope, time, val, start, shutter_close)
            # ready to move on to the next frame
            t += 1

    ### compute green channel and loglike under gaussian model

    cdef double ll = 2*num_frames*(-1./2 * log(PI) - 1./2 * log(sigmasq))
    cdef double y_green
    cdef double x_red_max = amax(vals)
    for t in range(num_frames):
        y_green = -a * y_red[t] + (b + a*x_red_max)
        ll += -1./2 * ((z[t,0] - y_red[t])**2 + (z[t,1] - y_green)**2) / sigmasq

    return ll

