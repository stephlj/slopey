# Quantification of single-molecule FRET trajectories containing non-instantaneous transitions

Slopey was written to handle smFRET data that consist of relatively long-lived “flat bits,” where the intensity values appear to be Gaussian scatter around a mean value (that is, they seem to be
well described as a constant intensity value with some noise), separated by “slopey” bits, which, though fast, are not instantaneous jumps. Current HMM fitting techniques in the field assume Gaussian emissions with instantaneous transitions.

## Building

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

## Running Steph’s Matlab code

To use the information in the goodtraces.txt parameters file from pyhsmm (see [Traces](https://github.com/stephlj/Traces)), first run

```matlab
ConvertGoodTracesToYAML(<datadir>)
```

Ensure that datadir has a global params.yml file.

Because Steph does have a crazy directory structure with spaces, you will need to create a symbolic link to each data directory. In Terminal, run:

```bash
cd “~/Documents/UCSF/.../Symlinks_Data” 
ln -s “/Users/Steph/Documents/.../smFRET data analysis/<datadir>” DataDirName 
```

To run slopey, either run in the Terminal:
```bash
./Analyze_Slopey.sh Symlinks_Data/DataDirName
```
with optional additional arguments: clean, -dr (prints debug info from make), -j4 (runs multi-threaded). Or, run in Matlab:

```matlab
RunSlopeyAnalysis(DataDirName)
```

If you get:

```
make: *** [results_slopey/*_Results.results.pkl] Abort trap: 6
```

this is likely a trace with one or more long dwells to which pyhsmm assigned many fast-switching states. If pyhsmm is used for initialization, you’ll have problems. 

Fix: edit the *_Results.params.yml file (or create a new one) such that 

```matlab
translocation_frame_guesses: [x1,x2,x3]
```
has reasonable values for x1, x2, x3, etc.

## long-term possible todos
- [ ] learn the noise parameters
- [ ] infer number of slopey bits (RJ MCMC)
- [ ] 'energy ladders' in the prior

