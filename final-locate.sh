#!/bin/bash
# final-locate.sh — the Buy Now button is injected by JavaScript that is NOT in
# the workspace, so the DEPLOYED theme JS is a stale version. This finds the exact
# file/line and shows how deployed JS differs from the workspace.
#   cd ~/projects/kartpro && bash final-locate.sh
# Paste the whole output back.

WS="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
TD="$HOME/projects/kartpro/web/themes/custom/hivesticks"

echo "══ 1. Deployed JS files in the theme ══"
ls -la "$TD/js" 2>/dev/null
echo ""

echo "══ 2. Grep the ENTIRE deployed theme for Buy Now / CTA injection ══"
grep -rin "buy *now\|hs-nav__cta\|hs-nav__actions\|hs-buy-now\|nav__buy" "$TD" 2>/dev/null \
  || echo "   (nothing in the deployed theme)"
echo ""

echo "══ 3. Grep custom + contrib modules for Buy Now ══"
grep -riln "buy *now" "$HOME/projects/kartpro/web/modules" 2>/dev/null | head -20 \
  || echo "   (nothing in modules)"
echo ""

echo "══ 4. Does the DEPLOYED homepage.js differ from the workspace copy? ══"
if [ -f "$TD/js/homepage.js" ]; then
  if diff -q "$TD/js/homepage.js" "$WS/homepage.js" >/dev/null 2>&1; then
    echo "   identical — homepage.js is up to date"
  else
    echo "   DIFFERENT. Lines only in the DEPLOYED (stale) homepage.js:"
    diff "$WS/homepage.js" "$TD/js/homepage.js" | grep '^>' | head -40
  fi
else
  echo "   no deployed homepage.js found at $TD/js/"
fi
echo ""

echo "══ 5. Same check for header.js ══"
if [ -f "$TD/js/header.js" ]; then
  diff -q "$TD/js/header.js" "$WS/header.js" >/dev/null 2>&1 \
    && echo "   header.js identical (up to date)" \
    || { echo "   DIFFERENT — deployed-only lines:"; diff "$WS/header.js" "$TD/js/header.js" | grep '^>' | head -40; }
fi
echo ""

echo "══ 6. All JS files the theme loads (grep libraries.yml) ══"
grep -rn "\.js" "$TD"/*.libraries.yml 2>/dev/null
echo ""
echo "Done. Paste everything above."
