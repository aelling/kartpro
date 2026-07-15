#!/bin/bash
# deploy-rewards.sh — installs the hs_rewards module (Honey Points loyalty) and
# redeploys the account theme files (Rewards nav link + CSS).
#   cd ~/projects/kartpro && bash deploy-rewards.sh

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"
THEME="hivesticks"
cd "$DRUPAL_ROOT" || { echo "ERROR: cannot cd $DRUPAL_ROOT"; exit 1; }

# ── 1. Module ───────────────────────────────────────────────────────────────
MOD_DIR="$DRUPAL_ROOT/modules/custom/hs_rewards"
echo "1. Installing hs_rewards module → $MOD_DIR"
mkdir -p "$MOD_DIR/src/Controller" "$MOD_DIR/src/EventSubscriber" "$MOD_DIR/templates"
cp "$WORKSPACE/hs_rewards/hs_rewards.info.yml"      "$MOD_DIR/hs_rewards.info.yml"
cp "$WORKSPACE/hs_rewards/hs_rewards.routing.yml"   "$MOD_DIR/hs_rewards.routing.yml"
cp "$WORKSPACE/hs_rewards/hs_rewards.services.yml"  "$MOD_DIR/hs_rewards.services.yml"
cp "$WORKSPACE/hs_rewards/hs_rewards.module"        "$MOD_DIR/hs_rewards.module"
cp "$WORKSPACE/hs_rewards/src/Controller/RewardsController.php"          "$MOD_DIR/src/Controller/RewardsController.php"
cp "$WORKSPACE/hs_rewards/src/EventSubscriber/OrderPointsSubscriber.php" "$MOD_DIR/src/EventSubscriber/OrderPointsSubscriber.php"
cp "$WORKSPACE/hs_rewards/templates/hs-rewards-page.html.twig"           "$MOD_DIR/templates/hs-rewards-page.html.twig"
echo "   ✓ module files copied"
echo ""

# ── 2. Theme files (Rewards nav + CSS) ──────────────────────────────────────
REL=$(ddev drush ev "print \Drupal::service('extension.list.theme')->getPath('$THEME');" 2>/dev/null | tr -d '[:space:]\r')
if [ -n "$REL" ] && [ -d "$DRUPAL_ROOT/$REL" ]; then THEME_DIR="$DRUPAL_ROOT/$REL";
elif [ -d "$DRUPAL_ROOT/themes/custom/$THEME" ]; then THEME_DIR="$DRUPAL_ROOT/themes/custom/$THEME"; fi
if [ -n "$THEME_DIR" ]; then
  cp "$WORKSPACE/page--user.html.twig" "$THEME_DIR/templates/layout/page--user.html.twig"
  cp "$WORKSPACE/account.css"          "$THEME_DIR/css/account.css"
  echo "2. Redeployed page--user.html.twig + account.css to $THEME_DIR"
else
  echo "2. WARNING: live theme dir not found — run sync-theme.sh for the nav + CSS."
fi
echo ""

# ── 3. Enable + cache ───────────────────────────────────────────────────────
echo "3. Enabling module + clearing cache..."
ddev drush en hs_rewards -y
ddev drush cr
echo ""
echo "Done. Visit /user/<uid>/rewards. Points are awarded 1/\$1 on each order placed."
echo "To seed points for testing: ddev drush ev \"\Drupal::service('user.data')->set('hs_rewards', 1, 'points', 640);\" && ddev drush cr"
