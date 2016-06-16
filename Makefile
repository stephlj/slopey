# input files
FILES = $(wildcard *Results.mat)

# output directories
RESULTSDIR = results_slopey
FIGDIR = figures_slopey

# global parameters file with default configuration
GLOBALPARAMS = params.yml

# these variales set up dependencies on the library files, so that analysis
# or plotting can be re-run when library functions change
# Luke: abspath used to be realpath, but realpath resolves symlinks
ROOT = $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
export PYTHONPATH := $(ROOT):$(PYTHONPATH)
LIB = $(ROOT)/slopey
SCRIPTS = $(ROOT)/scripts
ANALYSIS_LIB = $(addprefix $(LIB)/, load.py analysis.py camera_model.py \
                                    noise_models.py priors.py samplers.py util.py)
PLOTTING_LIB = $(addprefix $(LIB)/, load.py plotting.py util.py)

NAMES = $(notdir $(FILES))
RESULTS = $(addprefix $(RESULTSDIR)/, $(NAMES:.mat=.results.pkl))
FIGURES = $(addprefix $(FIGDIR)/, $(NAMES:.mat=.pdf))
MATFILE = $(addprefix $(RESULTSDIR)/, all_results.mat)
ALL = $(RESULTS) $(FIGURES) $(MATFILE)

#$(info $$FILES is [${FILES}])
#$(info $$MATFILE is [${MATFILE}])

.PHONY: all clean
all: $(ALL)
clean: ; rm -f $(ALL)

.SECONDEXPANSION:
$(RESULTSDIR)/%.results.pkl: $(SCRIPTS)/analyze_trace.py %.mat $(GLOBALPARAMS) \
                             $$(wildcard %.params.yml) $(ANALYSIS_LIB)
	@mkdir -p $(RESULTSDIR)
	python $(filter-out $(LIB)/%, $^) $@

$(FIGDIR)/%.pdf: $(SCRIPTS)/plot_results.py $(RESULTSDIR)/%.results.pkl $(PLOTTING_LIB)
	@mkdir -p $(FIGDIR)
	python $(filter-out $(LIB)/%, $^) $@

$(MATFILE): $(SCRIPTS)/collect_results.py $(RESULTS)
	@mkdir -p $(RESULTSDIR)
	python $(SCRIPTS)/collect_results.py $(RESULTSDIR) $@
