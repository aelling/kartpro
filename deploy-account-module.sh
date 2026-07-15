#!/bin/bash
# deploy-account-module.sh — installs the hs_account module (theme negotiator
# that forces the front-end theme on /user/{uid} and /user/{uid}/edit).
#   cd ~/projects/kartpro && bash deploy-account-module.sh

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"
MOD_DIR="$DRUPAL_ROOT/modules/custom/hs_account"

echo "Installing hs_account module → $MOD_DIR"
mkdir -p "$MOD_DIR/src/Theme"
cp "$WORKSPACE/hs_account/hs_account.info.yml"                 "$MOD_DIR/hs_account.info.yml"
cp "$WORKSPACE/hs_account/hs_account.services.yml"            "$MOD_DIR/hs_account.services.yml"
cp "$WORKSPACE/hs_account/src/Theme/AccountThemeNegotiator.php" "$MOD_DIR/src/Theme/AccountThemeNegotiator.php"
echo "  ✓ files copied"
echo ""

cd "$DRUPAL_ROOT" || exit 1
echo "Enabling module + clearing cache..."
ddev drush en hs_account -y
ddev drush cr
echo ""
echo "Done. Visit /user/<uid>/edit as admin — it should now render in the HiveSticks theme."
