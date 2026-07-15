#!/bin/bash
# dump-header-html.sh — fetch the live rendered page and show the markup around
# the "Buy Now" button. Timeout-safe (won't hang). Run:
#   cd ~/projects/kartpro && bash dump-header-html.sh
# Paste the whole output back.

FRONT="/tmp/hs_front.html"
rm -f "$FRONT"

echo "Fetching the front page (max 25s)..."

# Try 1: curl from inside the DDEV web container (site resolves at 127.0.0.1:80).
ddev exec "curl -s --connect-timeout 8 --max-time 25 http://127.0.0.1/" > "$FRONT" 2>/dev/null

# Try 2: if that produced nothing, curl the public URL from the host.
if [ ! -s "$FRONT" ]; then
  URL=$(ddev drush uri 2>/dev/null | tr -d '[:space:]')
  [ -z "$URL" ] && URL="https://kartpro.ddev.site"
  echo "   container fetch empty — trying $URL ..."
  curl -sk --connect-timeout 8 --max-time 25 "$URL/" > "$FRONT" 2>/dev/null
fi

BYTES=$(wc -c < "$FRONT" 2>/dev/null || echo 0)
echo "   got ${BYTES} bytes"
echo ""

if [ "${BYTES:-0}" -lt 100 ]; then
  echo "Could not fetch the page (empty/tiny response). Is 'ddev start' running?"
  echo "Fastest alternative: in your browser, right-click the Buy Now button →"
  echo "Inspect, and paste the highlighted <a ...>Buy Now</a> line + its wrapper."
  exit 0
fi

echo "══ 1. Lines mentioning 'Buy Now' ══"
grep -in "buy now" "$FRONT" || echo "   (not in server HTML — likely injected by JavaScript)"
echo ""

echo "══ 2. Context around 'Buy Now' (20 lines before / 3 after) ══"
grep -in -B20 -A3 "buy now" "$FRONT" 2>/dev/null | head -60 || echo "   (none)"
echo ""

echo "══ 3. The <header> element (wrapper ids/classes) ══"
awk '/<header/{f=1} f{print} /<\/header>/{if(f)exit}' "$FRONT" | head -60
echo ""

echo "══ 4. Drupal block wrappers (id=\"block-…\") ══"
grep -oiE 'id="block-[a-z0-9_-]+"' "$FRONT" | sort -u | head -30
echo ""

echo "══ 5. CTA-ish anchors (class contains cta/btn/buy) ══"
grep -ioE '<a[^>]*class="[^"]*(cta|btn|buy)[^"]*"[^>]*>[^<]*' "$FRONT" | head -20
echo ""
echo "Done. Paste everything above. (Full HTML at $FRONT.)"
