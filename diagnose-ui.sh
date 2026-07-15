#!/bin/bash
# diagnose-ui.sh — reports the current deployed state of the UI changes.
# Run from ~/projects/kartpro:  cd ~/projects/kartpro && bash diagnose-ui.sh
# Paste the entire output back.

DRUPAL_ROOT="$HOME/projects/kartpro"
cd "$DRUPAL_ROOT" || { echo "ERROR: cannot cd to $DRUPAL_ROOT"; exit 1; }

echo "══════════════════════════════════════════"
echo " HiveSticks UI diagnostic"
echo "══════════════════════════════════════════"

THEME=$(ddev drush config:get system.theme default --format=string 2>/dev/null | awk 'END{print $NF}' | tr -d '[:space:]')
echo "Active theme: '${THEME}'"

THEME_DIR=$(find "$DRUPAL_ROOT/web/themes" -maxdepth 3 -type d -name "$THEME" 2>/dev/null | head -1)
[ -z "$THEME_DIR" ] && THEME_DIR=$(find "$DRUPAL_ROOT/themes" -maxdepth 3 -type d -name "$THEME" 2>/dev/null | head -1)
echo "Theme dir:    ${THEME_DIR:-NOT FOUND}"
echo ""

echo "── 1. Did apply-ui-changes.sh land in the .theme file? ──"
grep -l "preprocess_menu_local_tasks" "$THEME_DIR/${THEME}.theme" 2>/dev/null \
  && echo "   menu_local_tasks hook: PRESENT" || echo "   menu_local_tasks hook: MISSING (apply script not run)"
echo ""

echo "── 2. Which templates render the View/Edit/Delete tabs? ──"
grep -rl "hs-admin-tabs" "$THEME_DIR/templates" 2>/dev/null || echo "   (none found — tabs come from core Tabs block)"
echo "   -> is the tab nav gated by product_edit_url?"
grep -rn "product_edit_url" "$THEME_DIR/templates" 2>/dev/null | head
echo ""

echo "── 3. Where is the header / Buy Now button? ──"
echo "   Templates containing a header nav (hs-nav):"
grep -rl "hs-nav__inner\|class=\"hs-nav\"" "$THEME_DIR/templates" 2>/dev/null
echo "   Templates containing 'Buy Now' text:"
grep -rln "Buy Now" "$THEME_DIR/templates" 2>/dev/null || echo "   (no 'Buy Now' text in any template)"
echo "   Templates containing hs-nav__cta class:"
grep -rln "hs-nav__cta" "$THEME_DIR/templates" 2>/dev/null || echo "   (no hs-nav__cta in any template)"
echo ""

echo "── 4. Which page template does the PRODUCT page use? ──"
ls -1 "$THEME_DIR/templates"/page--*.html.twig 2>/dev/null
ls -1 "$THEME_DIR/templates/layout"/page--*.html.twig 2>/dev/null
echo ""

echo "── 5. Is the header library CSS/JS updated? ──"
grep -q "hs-cart-toast" "$THEME_DIR/css/header.css" 2>/dev/null \
  && echo "   header.css toast styles: PRESENT" || echo "   header.css toast styles: MISSING"
grep -q "showCartPrompt" "$THEME_DIR/js/header.js" 2>/dev/null \
  && echo "   header.js prompt code:  PRESENT" || echo "   header.js prompt code:  MISSING"
echo ""

echo "── 6. Recently modified theme files (last 10) ──"
find "$THEME_DIR" -type f \( -name "*.twig" -o -name "*.css" -o -name "*.js" -o -name "*.theme" \) \
  -printf '%TY-%Tm-%Td %TH:%TM  %p\n' 2>/dev/null | sort -r | head -10
echo ""
echo "Done. Copy everything above and paste it back."
