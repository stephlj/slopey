# Quantification of single-molecule FRET trajectories containing non-instantaneous transitions

Slopey was written to handle smFRET data that consist of relatively long-lived “flat bits,” 
where the intensity values appear to be Gaussian scatter around a mean value (that is, they seem to be
well described as a constant intensity value with some noise), separated by “slopey” bits, 
which, though fast, are not instantaneous jumps. Current HMM fitting techniques in the field 
assume Gaussian emissions with instantaneous transitions. An introduction to Slopey and
its application to the quantification of timeseries data for a particular enzyme can be
found [here](https://stephlj.github.io/img/SlopeySlides.pdf).

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

Make a copy of the sample global [params.yml](https://github.com/stephlj/slopey/blob/master/data/params.yml) file, edit the 
parameters as needed for your data, and save in the same directory as the .mat files to be analyzed (called `<datadir>` below).

Each .mat file can also be analyzed with its own parameters, if a .yml with the same filename but with extension `.params.yml`
instead of `.mat` is present. To use the information in the goodtraces.txt parameters file from pyhsmm (see [Traces](https://github.com/stephlj/Traces))
to automatically generate trace-specific parameters, first run

```matlab
ConvertGoodTracesToYAML(<datadir>)
```

Because Steph does have a crazy directory structure with spaces, you will need to run the build command as above. If you try to run slopey either through the Terminal
or by running RunSlopeyAnalysis in Matlab, and get:

```
Compiling low-level code
python: can't open file 'setup.py': [Errno 2] No such file or directory
```

then re-build.

With a crazy directory structure with spaces like Steph's, you will also need to create a symbolic link to each data directory. In Terminal, run:

```bash
cd “~/Documents/UCSF/.../Symlinks_Data” 
ln -s “/Users/Steph/Documents/.../smFRET data analysis/<datadir>” DataDirName 
```

To run slopey, either run in the Terminal:
```bash
./Analyze_Slopey.sh Symlinks_Data/DataDirName
```
with optional additional arguments: clean, -dr (prints debug info from make), -j4 (runs multi-threaded; the default in RunSlopeyAnalysis is -j2). Or, run in Matlab:

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

Once slopey is running successfully, it will print out accept proportions for each trace. Optimally they should be ~0.2.

Cropping: Crop traces as little as possible. The more information slopey has about each flat bit's (noisy) distribution of intensity values, the better it will find the intervening slopey bits.
This is somewhat in contrast to the discrete-time HMM based on pyhsmm (see [Traces](https://github.com/stephlj/Traces) and [pyhsmm](https://github.com/mattjj/pyhsmm)), where long noisy flat bits are likely to be assigned multiple states.

## long-term possible todos
- [ ] learn the noise parameters
- [ ] infer number of slopey bits (RJ MCMC)
- [ ] 'energy ladders' in the prior

