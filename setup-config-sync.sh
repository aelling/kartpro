#!/bin/bash
# setup-config-sync.sh — relocate the config-sync directory into the repo and
# export the current DB config so it can travel to production via git.
# LOCAL/DDEV ONLY. Safe + reversible (backs up settings.php, only writes files).
#   cd ~/projects/kartpro && bash setup-config-sync.sh

set -e
R="$HOME/projects/kartpro"
cd "$R" || exit 1
SETTINGS="$R/sites/default/settings.php"

echo "── 1. Point config_sync_directory at ./config/sync (in-repo) ──"
if grep -q "config_sync_directory'\] *= *'config/sync'" "$SETTINGS"; then
  echo "   already set."
else
  cp "$SETTINGS" "$SETTINGS.bak.$(date +%s)"
  {
    echo ""
    echo "// HiveSticks: config sync relocated into the repo so it deploys via git."
    echo "\$settings['config_sync_directory'] = 'config/sync';"
  } >> "$SETTINGS"
  echo "   set (settings.php backed up)."
fi
mkdir -p "$R/config/sync"
echo ""

echo "── 2. Export current configuration to config/sync ──"
ddev drush config:export -y
echo "   exported $(ls "$R/config/sync"/*.yml 2>/dev/null | wc -l) yml files"
echo ""

echo "── 3. Validate — re-check status (should report no differences) ──"
ddev drush config:status
echo ""

echo "── 4. Sanity: is core.extension (enabled modules) captured? ──"
grep -E "hs_account|hs_rewards|hs_subscribe|commerce_recurring|commerce_shipping" "$R/config/sync/core.extension.yml" 2>/dev/null || echo "   ⚠ modules not found in core.extension.yml — check the export"
echo ""
echo "Done. Review 'git status' — you should see config/sync/*.yml plus your code."
echo "IMPORTANT: production settings.php must ALSO set config_sync_directory='config/sync'"
echo "(add it alongside the Stripe block). See go-live-checklist.md."
