#!/bin/bash
W="${STUDY_DIR_WORK:-${TMPDIR:-/tmp}/webveld-corpus-study}"; export STUDY_DIR_WORK="$W"
INPUT_DIR="${STUDY_INPUT_DIR:-${TMPDIR:-/tmp}/webveld-corpus-input}"
rm -rf "$W"; mkdir -p "$W/pages" "$W/css" "$W/out"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"

# --- cohort A: 512kb.club members (size-budget / smol web) ---
grep -o 'href="https\?://[^"]*"' "$INPUT_DIR/512.html" | sed 's/href="//;s/"$//' \
 | grep -vE '512kb\.club|codeberg\.org|nearlyfreespeech|github\.com|nytimes\.com|patreon|twitter|mastodon' \
 | sed -E 's,^(https?://[^/]+).*,\1,' | sort -u | head -75 | sed 's/^/A\t/' > $W/sites.tsv

# --- cohort B: curated lite/text-only sites ---
grep -oE 'https?://[a-zA-Z0-9./_-]+' "$INPUT_DIR/lite.md" | grep -vE 'github|rawgit|shields\.io' \
 | sed -E 's,^(https?://[^/]+).*,\1,' | sort -u | head -22 | sed 's/^/B\t/' >> $W/sites.tsv

# --- cohort C: modern lightweight dev/personal sites (not ideologically retro) ---
for u in https://simonwillison.net https://jvns.ca https://macwright.com https://brandur.org \
         https://htmx.org https://danluu.com https://rachelbythebay.com https://sourcehut.org \
         https://sqlite.org https://suckless.org https://openbsd.org https://alpinelinux.org \
         https://tailscale.com/blog https://blog.cloudflare.com https://css-tricks.com https://developer.mozilla.org; do
  echo -e "C\t$u" >> $W/sites.tsv
done
wc -l < $W/sites.tsv

fetch() {
  W="${STUDY_DIR_WORK:-${TMPDIR:-/tmp}/webveld-corpus-study}"
  UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
  cohort=$(echo "$1" | cut -f1); url=$(echo "$1" | cut -f2)
  id=$(printf '%s' "$url" | md5sum | cut -c1-12)
  h=$W/pages/$id.html; c=$W/css/$id.css
  curl -sL --max-time 15 --max-filesize 3000000 -A "$UA" "$url" -o "$h" 2>/dev/null
  [ -s "$h" ] || return 0
  : > "$c"
  H="$h" lua -e 'local f=io.open(os.getenv("H"),"rb"); if f then local s=f:read("*a"); f:close(); for c in s:gmatch("<[sS][tT][yY][lL][eE][^>]*>(.-)</[sS][tT][yY][lL][eE]%s*>") do print(c) end end' >> "$c" 2>/dev/null
  host=$(printf '%s' "$url" | sed -E 's,^(https?://[^/]+).*,\1,')
  H="$h" lua -e 'local f=io.open(os.getenv("H"),"rb"); if f then local s=f:read("*a"); f:close(); for link in s:gmatch("<[lL][iI][nN][kK]([^>]+)>") do if link:lower():match("stylesheet") then local href = link:match("[%s\"][hH][rR][eE][fF]%s*=%s*[\x22\x27]?([^%s\x22\x27>]+)") or link:match("^[hH][rR][eE][fF]%s*=%s*[\x22\x27]?([^%s\x22\x27>]+)"); if href then print(href) end end end end' 2>/dev/null | head -3 | while read -r href; do
    case "$href" in
      http*) full="$href" ;;
      //*)   full="https:$href" ;;
      /*)    full="$host$href" ;;
      *)     full="$host/$href" ;;
    esac
    curl -sL --max-time 10 --max-filesize 2000000 -A "$UA" "$full" 2>/dev/null >> "$c"
  done
  echo -e "$cohort\t$url\t$id" >> $W/out/ok.tsv
}
export -f fetch
cat $W/sites.tsv | xargs -P 12 -I{} bash -c 'fetch "$@"' _ {}
echo "fetched: $(wc -l < $W/out/ok.tsv)"
echo
echo "now freeze it:  tools/corpus-study/snapshot.sh save"
