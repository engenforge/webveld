#!/bin/sh
# Dump every text-browser case through Lynx, w3m and Links at a fixed width.
#
# These browsers implement no CSS (Lynx, w3m) or very little of it (Links), so
# what they show is what a reader gets from the markup alone. That makes them
# the practical test of whether a construct degrades or breaks at the bottom of
# the implementability continuum, which is the question webveld-pico and
# webveld-nano exist to answer. doc/research/text-browser-assessment.md records the
# findings; this script is how they are reproduced.
#
# Width defaults to 40 so wrapping behavior is unmistakable; 80 is the more
# realistic figure and shows the same thing less starkly.
#
#   sh tools/text-browsers/run.sh            # all cases, width 40
#   WIDTH=80 sh tools/text-browsers/run.sh   # the usual terminal width
#   sh tools/text-browsers/run.sh --include-probes
#
# --include-probes adds the deliberately non-conforming documents in
# ../render-diff/probes/, which use constructs no conforming document can
# contain. See that directory's README.
cd "$(dirname "$0")" || exit 1

WIDTH=${WIDTH:-40}
cases="pre-long-lines.html pre-overflow-x.html sectioning-semantic.html \
sectioning-div.html hiding.html tabindex-and-style.html"

case "$1" in
	--include-probes)
		for p in ../render-diff/probes/*.html; do
			cases="$cases $p"
		done
		;;
esac

missing=
for b in lynx w3m links; do
	command -v "$b" >/dev/null 2>&1 || missing="$missing $b"
done
if [ -n "$missing" ]; then
	echo "not installed:$missing -- install them or read doc/research/text-browser-assessment.md" >&2
	[ "$missing" = " lynx w3m links" ] && exit 1
fi

dump() {
	case "$1" in
		lynx)  lynx -dump -width "$WIDTH" "$2" ;;
		w3m)   w3m  -dump -cols  "$WIDTH" "$2" ;;
		links) links -dump -width "$WIDTH" "$2" ;;
	esac
}

for f in $cases; do
	echo "############ $f (width $WIDTH)"
	for b in lynx w3m links; do
		command -v "$b" >/dev/null 2>&1 || continue
		echo "==== $b"
		# Prefix each line with its length: the wrapping behavior that
		# distinguishes these engines is a property of line length, and it is
		# invisible when you only read the text.
		dump "$b" "$f" 2>/dev/null | awk '{printf "%3d| %s\n", length, $0}'
	done
	echo
done
