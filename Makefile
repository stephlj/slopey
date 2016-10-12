DATADIR = .
RESULTSDIR = results_slopey
FIGDIR = figures_slopey

ifeq ($(USER), mattjj)
DATADIR = data
RESULTSDIR = results
FIGDIR = figures
export USE_TQDM = true
endif

FILES = $(wildcard $(DATADIR)/*Results.mat)
SPECIFIC_PARAMS = $(wildcard $(DATADIR)/*Results.params.yml)

# global parameters file with default configuration
GLOBALPARAMS = $(DATADIR)/params.yml

# these variales set up dependencies on the library files, so that analysis
# or plotting can be re-run when library functions change
# Luke: abspath used to be realpath, but realpath resolves symlinks
ROOT = $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
export PYTHONPATH := $(ROOT):$(PYTHONPATH)
LIB = $(ROOT)/slopey
SCRIPTS = $(ROOT)/scripts
ANALYSIS_LIB = $(addprefix $(LIB)/, load.py analysis.py camera_model.py \
                                    priors.py samplers.py util.py fast.so)
PLOTTING_LIB = $(addprefix $(LIB)/, load.py plotting.py util.py)

NAMES = $(sort $(notdir $(FILES)))

RESULTS = $(addprefix $(RESULTSDIR)/, $(NAMES:.mat=.results.pkl))
FIGURES = $(addprefix $(FIGDIR)/, $(NAMES:.mat=.pdf))
MATLAB_RESULTS = $(addprefix $(RESULTSDIR)/, $(NAMES:.mat=.results.mat))
MATLAB_ALL_RESULTS = $(addprefix $(RESULTSDIR)/, all_results.mat)

ALL = $(RESULTS) $(MATLAB_RESULTS) $(FIGURES) # $(MATLAB_ALL_RESULTS)

DISCARD = $(shell $(ROOT)/list_discards.py $(SPECIFIC_PARAMS))
DISCARD_PKL = $(addprefix $(RESULTSDIR)/, $(DISCARD:.params.yml=.results.pkl))
# DISCARD_FIG = $(addprefix $(FIGDIR)/, $(DISCARD:.params.yml=.pdf))
# DISCARD_PRIOR_FIG = $(addprefix $(FIGDIR)/, $(DISCARD:.params.yml=_prior.pdf))

PYTHON=python

.PHONY: all clean clean_discards
all: $(ALL)
clean: ; rm -f $(ALL) $(MATLAB_ALL_RESULTS)
clean_discards:
	rm -f $(DISCARD_PKL) $(MATLAB_ALL_RESULTS)

.SECONDEXPANSION:
$(RESULTSDIR)/%.results.pkl: $(SCRIPTS)/analyze_trace.py $(DATADIR)/%.mat \
		$(GLOBALPARAMS) $$(wildcard $(DATADIR)/%.params.yml) $(ANALYSIS_LIB)
	@mkdir -p $(RESULTSDIR)
	@echo Generating $(notdir $@)
	@$(PYTHON) $(filter-out $(LIB)/%, $^) $@

$(RESULTSDIR)/%.results.mat: $(SCRIPTS)/collect_results.py $(RESULTSDIR)/%.results.pkl
	@echo Generating $(notdir $@)
	@$(PYTHON) $^ $@

$(FIGDIR)/%.pdf: $(SCRIPTS)/plot_results.py $(RESULTSDIR)/%.results.pkl $(PLOTTING_LIB)
	@mkdir -p $(FIGDIR)
	@echo Generating $(notdir $@)
	@$(PYTHON) $(filter-out $(LIB)/%, $^) $@

$(MATLAB_ALL_RESULTS): $(SCRIPTS)/collect_results.py $(RESULTS)
	@mkdir -p $(RESULTSDIR)
	@echo Generating $(notdir $@)
	@$(PYTHON) $(SCRIPTS)/collect_results.py $(RESULTSDIR) $@

$(LIB)/fast.so: $(LIB)/fast.pyx $(ROOT)/setup.py
	@echo Compiling low-level code
	@cd $(ROOT)
	@python setup.py build_ext --inplace
