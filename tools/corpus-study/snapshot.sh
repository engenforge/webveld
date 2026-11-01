#!/bin/bash
# Keep a fetched corpus outside the repository so a corrected script can be
# re-run against the same population, and fingerprint it so any published
# number can be traced to the bytes it came from.
#
#   snapshot.sh save [LABEL]   copy the working corpus into the cache
#   snapshot.sh list           show cached snapshots, newest first
#   snapshot.sh resolve        print the corpus directory the analysers will read
#   snapshot.sh fingerprint    print the fingerprint of that corpus
#   snapshot.sh verify [LABEL] re-hash a cached snapshot against its manifest
#   snapshot.sh drop LABEL     delete one cached snapshot
#
# The cache is a cache. It lives at ${WEBVELD_CACHE:-~/.cache/webveld}, nothing
# in the repository depends on it, and every script degrades to a clear message
# when it is missing or has been cleared.
set -eu

CACHE="${WEBVELD_CACHE:-$HOME/.cache/webveld}/corpus"
WORK="${STUDY_DIR_WORK:-${TMPDIR:-/tmp}/webveld-corpus-study}"

# Where the analysers read from: an explicit STUDY_DIR wins, then the newest
# cached snapshot, then the working directory a fresh fetch writes to.
resolve() {
    if [ -n "${STUDY_DIR:-}" ] && [ -s "${STUDY_DIR}/out/ok.tsv" ]; then
        printf '%s\n' "$STUDY_DIR"; return 0
    fi
    if [ -d "$CACHE" ]; then
        local newest
        newest=$(ls -1dt "$CACHE"/*/ 2>/dev/null | head -1 || true)
        if [ -n "$newest" ] && [ -s "${newest}out/ok.tsv" ]; then
            printf '%s\n' "${newest%/}"; return 0
        fi
    fi
    if [ -s "$WORK/out/ok.tsv" ]; then printf '%s\n' "$WORK"; return 0; fi
    return 1
}

# A corpus fingerprint is the digest of its manifest, which is itself built from
# per-file digests. Same bytes in, same fingerprint out, on any machine.
write_manifest() {
    local d="$1" man="$1/MANIFEST.tsv"
    printf 'cohort\turl\tid\tpage_bytes\tpage_sha256\tcss_bytes\tcss_sha256\n' > "$man"
    sort "$d/out/ok.tsv" | while IFS=$'\t' read -r cohort url id; do
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$cohort" "$url" "$id" \
            "$(wc -c < "$d/pages/$id.html" 2>/dev/null || echo 0)" \
            "$(sha256sum "$d/pages/$id.html" 2>/dev/null | cut -d' ' -f1)" \
            "$(wc -c < "$d/css/$id.css" 2>/dev/null || echo 0)" \
            "$(sha256sum "$d/css/$id.css" 2>/dev/null | cut -d' ' -f1)" >> "$man"
    done
    tail -n +2 "$man" | sha256sum | cut -d' ' -f1 > "$d/FINGERPRINT"
}

case "${1:-}" in
save)
    label="${2:-$(date +%Y-%m-%d)}"
    [ -s "$WORK/out/ok.tsv" ] || { echo "no fetched corpus at $WORK — run fetch.sh first" >&2; exit 1; }
    dest="$CACHE/$label"
    rm -rf "$dest"; mkdir -p "$dest"
    cp -r "$WORK/pages" "$WORK/css" "$WORK/out" "$dest/"
    [ -f "$WORK/sites.tsv" ] && cp "$WORK/sites.tsv" "$dest/"
    write_manifest "$dest"
    echo "saved    $dest"
    echo "sites    $(( $(wc -l < "$dest/MANIFEST.tsv") - 1 ))"
    echo "size     $(du -sh "$dest" | cut -f1)"
    echo "finger   $(cut -c1-16 < "$dest/FINGERPRINT")"
    ;;
list)
    [ -d "$CACHE" ] || { echo "no cache at $CACHE"; exit 0; }
    printf '%-14s %6s %8s  %s\n' LABEL SITES SIZE FINGERPRINT
    for d in $(ls -1dt "$CACHE"/*/ 2>/dev/null); do
        d="${d%/}"
        printf '%-14s %6s %8s  %s\n' "$(basename "$d")" \
            "$([ -f "$d/MANIFEST.tsv" ] && echo $(( $(wc -l < "$d/MANIFEST.tsv") - 1 )) || echo '?')" \
            "$(du -sh "$d" 2>/dev/null | cut -f1)" \
            "$([ -f "$d/FINGERPRINT" ] && cut -c1-16 < "$d/FINGERPRINT" || echo '(none)')"
    done
    ;;
resolve)
    resolve || { echo "no corpus: cache $CACHE is empty and nothing fetched at $WORK" >&2; exit 1; }
    ;;
fingerprint)
    d=$(resolve) || { echo "no corpus available" >&2; exit 1; }
    if [ -f "$d/FINGERPRINT" ]; then cut -c1-16 < "$d/FINGERPRINT"
    else write_manifest "$d" >/dev/null 2>&1 && cut -c1-16 < "$d/FINGERPRINT"; fi
    ;;
verify)
    label="${2:-}"
    d=$([ -n "$label" ] && echo "$CACHE/$label" || resolve)
    [ -f "$d/MANIFEST.tsv" ] || { echo "no manifest in $d" >&2; exit 1; }
    bad=$(mktemp)
    while IFS=$'\t' read -r cohort url id pb ph cb ch; do
        [ "$(sha256sum "$d/pages/$id.html" 2>/dev/null | cut -d' ' -f1)" = "$ph" ] || echo "MISMATCH page $url" >> "$bad"
        [ "$(sha256sum "$d/css/$id.css" 2>/dev/null | cut -d' ' -f1)" = "$ch" ]   || echo "MISMATCH css  $url" >> "$bad"
    done < <(tail -n +2 "$d/MANIFEST.tsv")
    n=$(( $(wc -l < "$d/MANIFEST.tsv") - 1 ))
    if [ -s "$bad" ]; then cat "$bad"; echo "$(wc -l < "$bad") of $((n * 2)) files differ"; rm -f "$bad"; exit 1; fi
    rm -f "$bad"
    echo "verified $d: $n sites, all hashes match, fingerprint $(cut -c1-16 < "$d/FINGERPRINT")"
    ;;
drop)
    [ -n "${2:-}" ] || { echo "drop needs a label" >&2; exit 1; }
    rm -rf "${CACHE:?}/$2" && echo "dropped $2"
    ;;
*)
    sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
    echo
    "$0" list
    exit 1
    ;;
esac
