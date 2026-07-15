#!/bin/bash
# deploy-readiness-diag.sh — read-only: how is code/config/deploy set up, so a
# correct production deploy plan can be written. Paste the output back.
#   cd ~/projects/kartpro && bash deploy-readiness-diag.sh

R="$HOME/projects/kartpro"
cd "$R" || exit 1

echo "══════════════════════════════════════════"
echo " Deploy readiness report"
echo "══════════════════════════════════════════"

echo "── 1. Does the site use CONFIG SYNC? ──"
SYNC=$(ddev drush ev "print \Drupal\Core\Site\Settings::get('config_sync_directory');" 2>/dev/null)
echo "   config_sync_directory = ${SYNC:-'(not set)'}"
# Count exported yml (host path guess)
for d in "$R/config/sync" "$R/config" "$R/../config/sync"; do
  [ -d "$d" ] && echo "   $d : $(ls "$d"/*.yml 2>/dev/null | wc -l) yml files"
done
ddev drush pm:list --status=enabled --field=name 2>/dev/null | grep -x "config_split" >/dev/null && echo "   config_split: ENABLED" || echo "   config_split: not enabled"
echo "   pending config diff (drush cst):"
ddev drush config:status 2>/dev/null | head -20
echo ""

echo "── 2. deploy.sh (what the push-to-host actually does) ──"
if [ -f "$R/deploy.sh" ]; then sed -n '1,60p' "$R/deploy.sh"; else echo "   (no deploy.sh in project root)"; fi
echo ""

echo "── 3. Git: is the new code committed / tracked? ──"
echo "   branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
echo "   -- git status (short) --"
git -C "$R" status --short 2>/dev/null | head -40
echo "   -- are the custom modules tracked? --"
git -C "$R" ls-files modules/custom/hs_account modules/custom/hs_rewards modules/custom/hs_subscribe 2>/dev/null | head
echo "   -- is the live theme tracked? --"
git -C "$R" ls-files themes/custom/hivesticks 2>/dev/null | wc -l
echo ""

echo "── 4. Composer: are the new deps in composer.json? ──"
grep -E "commerce_recurring|drupal/core-recommended" "$R/composer.json" 2>/dev/null
echo ""

echo "── 5. Modules enabled locally that must be enabled on prod ──"
ddev drush pm:list --status=enabled --field=name 2>/dev/null | grep -E "commerce_recurring|hs_account|hs_rewards|hs_subscribe|commerce_shipping"
echo ""
echo "Done. Paste everything above."
