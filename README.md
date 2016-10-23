## building

```bash
python setup.py build_ext --inplace
```

The makefile will take care of this for you unless you have some crazy
directory structure with spaces.

## Hard-coded limits on numbers of slopey bits and frames

The cython file `slopey/fast.pyx` has hard-coded limits on the number of slopey bits (`NUM_SLOPEY_MAX`) and the number of frames of data (`NUM_FRAMES_MAX`). That is, those limits are set at compile time, but can be increased by editing `slopey/fast.pyx` and changing these lines (which may not be next to each other):

```python
cdef int NUM_SLOPEY_MAX = 25
cdef int NUM_FRAMES_MAX = 50000
```

There's essentially no limit to how large you set these, but for ease of implementation they're preset.

## long-term possible todos
- [ ] learn the noise parameters
- [ ] infer number of slopey bits (RJ MCMC)
- [ ] 'energy ladders' in the prior

## Notes and wish list
Data consist of relatively long-lived “flat bits” where the intensity values
appear to be Gaussian scatter around a mean value (that is, they seem to be
well described as a constant intensity value with some noise). These flat bits
are separated by “slopey” bits that, for the most part, by eye do not seem to
be instantaneous jumps.

For each data set (~100 traces), want:
- mean value +/- error of durations of first flat bit that occurs in each
  trace, second flat bit, and third flat bit (where it exists, not all traces
  get to a third flat bit)
- mean value +/- error of durations of first slopey bit in a trace, second
  slopey bit, and maybe third if we have enough data. Or, if mean+err is too
  hard to get, some equivalent statistic that tells us how long, on average, each
  slopey bit is.
- (bonus because I can do this other ways): Some measure of how much the
  intensity levels change between successive flat bits. For example, on
  average, is the intensity difference between the first and second flat bits the
  same as the second and third flat bits? <- For this I really care about FRET
  values (red/red+green), not intensity per se.
- (bonus because I can do this other ways): Direction reversals: what fraction
  of slopey bits take you to a higher, rather than lower intensity value (that
  is, how often is the n+1 flat bit at a higher intensity than the nth one)
- (bonus because I’m not sure yet if I need to care, and not sure if my data
  can speak to this): Are the slopey bits actually composed of many very short
  flat bits separated by instantaneous drops?
