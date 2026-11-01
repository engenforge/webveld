#!/bin/sh
# Validate every HTML file in the repository.
# The repository holds nothing that fails the specification;
# this is how that stays true. Two directories are excluded and both hold files
# that are *meant* to fail: tools/validator/tests/ (negative fixtures) and
# tools/render-diff/probes/ (documents using constructs WebVeld forbids, to
# characterize another engine's handling of them). Nothing else is exempt.
cd "$(dirname "$0")/../.." || exit 1
files=$(find . -name '*.html' -not -path './tools/validator/tests/*' -not -path './tools/render-diff/probes/*' -not -path './tmp/*' -not -path './build/*' -not -path './.git/*' | sort)
# An empty list means the find expression broke, not that everything passed.
if [ -z "$files" ]; then echo "no HTML files found -- the file list is broken" >&2; exit 1; fi
set -f
IFS='
'
set -- $files
unset IFS
set +f
exec lua tools/validator/webveld-validate.lua "$@"
