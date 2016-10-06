# input files
FILES = $(wildcard *Results.mat)
SPECIFIC_PARAMS = $(wildcard *Results.params.yml)

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
export FAST_SLOPEY_PROPOSALS := true
LIB = $(ROOT)/slopey
SCRIPTS = $(ROOT)/scripts
ANALYSIS_LIB = $(addprefix $(LIB)/, load.py analysis.py camera_model.py \
                                    noise_models.py priors.py samplers.py util.py)
PLOTTING_LIB = $(addprefix $(LIB)/, load.py plotting.py util.py)

NAMES = $(sort $(notdir $(FILES)))
RESULTS = $(addprefix $(RESULTSDIR)/, $(NAMES:.mat=.results.pkl))
FIGURES = $(addprefix $(FIGDIR)/, $(NAMES:.mat=.pdf))
MATFILE = $(addprefix $(RESULTSDIR)/, all_results.mat)
ALL = $(RESULTS) $(FIGURES) $(MATFILE)
DISCARD = $(shell $(ROOT)/list_discards.py $(SPECIFIC_PARAMS))
DISCARD_PKL = $(addprefix $(RESULTSDIR)/, $(DISCARD:.params.yml=.results.pkl))
# DISCARD_FIG = $(addprefix $(FIGDIR)/, $(DISCARD:.params.yml=.pdf))
# DISCARD_PRIOR_FIG = $(addprefix $(FIGDIR)/, $(DISCARD:.params.yml=_prior.pdf))

PYTHON=python
# MATLAB=/Applications/MATLAB_R2014b.app/bin/matlab -nodisplay -nosplash -nodesktop -nojvm -r "disp('hi'); quit" > /dev/null

.PHONY: all clean clean_discards
all: $(ALL)
clean: ; rm -f $(ALL)
clean_discards:
	rm -f $(DISCARD_PKL) $(MATFILE)

.SECONDEXPANSION:
$(RESULTSDIR)/%.results.pkl: %.mat $(GLOBALPARAMS) $$(wildcard %.params.yml)
	@mkdir -p $(RESULTSDIR)
	@echo Generating $(notdir $@)
	@$(PYTHON) $(SCRIPTS)/analyze_trace.py $(filter-out $(LIB)/%, $^) $@

$(FIGDIR)/%.pdf: $(SCRIPTS)/plot_results.py $(RESULTSDIR)/%.results.pkl $(PLOTTING_LIB)
	@mkdir -p $(FIGDIR)
	@echo Generating $(notdir $@)
	@$(PYTHON) $(filter-out $(LIB)/%, $^) $@

$(MATFILE): $(SCRIPTS)/collect_results.py $(RESULTS)
	@mkdir -p $(RESULTSDIR)
	@echo Generating $(notdir $@)
	@$(PYTHON) $(SCRIPTS)/collect_results.py $(RESULTSDIR) $@
