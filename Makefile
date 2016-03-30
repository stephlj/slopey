### configuration

# input files
FILES = $(wildcard data/*.mat)

# output directories
RESULTSDIR = results
FIGDIR = figures

# global parameters file with default configuration
GLOBALPARAMS = data/params.yml

# these variales set up dependencies on the library files, so that analysis
# or plotting can be re-run when library functions change
ANALYSIS_LIB = $(addprefix slopey/, load.py models.py camera_model.py \
                                    noise_models.py priors.py samplers.py)
PLOTTING_LIB = $(addprefix slopey/, load.py plotting.py)

### end configuration

export PYTHONPATH = .
NAMES = $(notdir $(FILES))
RESULTS = $(addprefix $(RESULTSDIR)/, $(NAMES:.mat=.results.pkl))
FIGURES = $(addprefix $(FIGDIR)/, $(NAMES:.mat=.pdf))
MATFILE = $(addprefix $(RESULTSDIR)/, all_results.mat)
ALL = $(RESULTS) $(FIGURES) $(MATFILE)

.PHONY: all clean
all: $(ALL)
clean: ; rm -f $(ALL)

.SECONDEXPANSION:
$(RESULTSDIR)/%.results.pkl: scripts/analyze_trace.py data/%.mat $(GLOBALPARAMS) \
                             $$(wildcard data/%.params.yml) $(ANALYSIS_LIB)
	@mkdir -p $(RESULTSDIR)
	python $(filter-out slopey/%, $^) $@

$(FIGDIR)/%.pdf: scripts/plot_results.py $(RESULTSDIR)/%.results.pkl $(PLOTTING_LIB)
	@mkdir -p $(FIGDIR)
	python $(filter-out slopey/%, $^) $@

$(MATFILE): scripts/collect_results.py $(RESULTS)
	@mkdir -p $(RESULTSDIR)
	python scripts/collect_results.py $(RESULTSDIR) $@
