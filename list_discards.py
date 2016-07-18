#!/usr/bin/env python
import sys
from slopey.load import load_params

if __name__ == "__main__":
	if len(sys.argv) == 1:
		argspec = '{} [v] specific_params.json [...]'
		print >>sys.stderr, argspec.format(sys.argv[0])
		sys.exit(1)

	if sys.argv[1] == "v":
		invert = True
		files = sys.argv[2:]
	else:
		invert = False
		files = sys.argv[1:]

	for specific_paramfile in files:
		params = load_params(specific_paramfile)

		if invert ^ ('discard' in params and params['discard']):
			print specific_paramfile