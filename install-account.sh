#!/bin/bash
# install-account.sh
# ──────────────────
# Deploys the customer login / account feature to the HiveSticks theme.
#
# What it does:
#   1. Copies account.css into the theme
#   2. Copies updated page.html.twig + page--front.html.twig (account link in nav)
#   3. Copies updated header.css (account link styles)
#   4. Copies updated hivesticks.libraries.yml (account library entry)
#   5. Patches hivesticks.theme — adds user_is_logged_in + user_uid variables
#      to BOTH hivesticks_preprocess_page() and hivesticks_preprocess_page__front()
#   6. Clears Drupal cache
#
# Run from anywhere:
#   bash install-account.sh

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
DRUPAL_ROOT="$HOME/projects/kartpro"

cd "$DRUPAL_ROOT" || { echo "ERROR: Cannot cd to $DRUPAL_ROOT"; exit 1; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " HiveSticks — account / login install"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Detect theme ────────────────────────────────────────────────────────────
echo "1. Detecting active theme..."
THEME=$(ddev drush config:get system.theme default --format=string 2>/dev/null | awk 'END{print $NF}' | tr -d '[:space:]')
if [ -z "$THEME" ]; then
  echo "   ERROR: Could not detect theme. Is DDEV running? (ddev start)"
  exit 1
fi
THEME_DIR=$(find "$DRUPAL_ROOT/themes" -maxdepth 3 -type d -name "$THEME" 2>/dev/null | head -1)
if [ -z "$THEME_DIR" ]; then
  echo "   ERROR: Theme directory not found for '$THEME'"
  exit 1
fi
echo "   Theme: $THEME → $THEME_DIR"
echo ""

# ── 2. CSS ─────────────────────────────────────────────────────────────────────
echo "2. Installing Commerce Twig templates..."
COMMERCE_DIR="$THEME_DIR/templates/commerce"
mkdir -p "$COMMERCE_DIR"
cp "$WORKSPACE/commerce-order.html.twig" "$COMMERCE_DIR/commerce-order.html.twig"
echo "   ✓ commerce-order.html.twig → $COMMERCE_DIR/"
echo ""

echo "3. Installing CSS..."
CSS_DIR="$THEME_DIR/css"
mkdir -p "$CSS_DIR"
cp "$WORKSPACE/account.css"   "$CSS_DIR/account.css"
echo "   ✓ account.css → $CSS_DIR/"
cp "$WORKSPACE/header.css"   "$CSS_DIR/header.css"
echo "   ✓ header.css → $CSS_DIR/"
cp "$WORKSPACE/checkout.css" "$CSS_DIR/checkout.css"
echo "   ✓ checkout.css → $CSS_DIR/"
echo ""

# ── 3. Twig templates ──────────────────────────────────────────────────────────
echo "4. Installing layout Twig templates..."
LAYOUT_DIR="$THEME_DIR/templates/layout"
mkdir -p "$LAYOUT_DIR"
cp "$WORKSPACE/page.html.twig"      "$LAYOUT_DIR/page.html.twig"
echo "   ✓ page.html.twig → $LAYOUT_DIR/"
cp "$WORKSPACE/homepage.html.twig"  "$LAYOUT_DIR/page--front.html.twig"
echo "   ✓ homepage.html.twig → $LAYOUT_DIR/page--front.html.twig"
cp "$WORKSPACE/page--user.html.twig" "$LAYOUT_DIR/page--user.html.twig"
echo "   ✓ page--user.html.twig → $LAYOUT_DIR/"
cp "$WORKSPACE/page--404.html.twig"              "$LAYOUT_DIR/page--404.html.twig"
echo "   ✓ page--404.html.twig → $LAYOUT_DIR/"
cp "$WORKSPACE/page--checkout.html.twig" "$LAYOUT_DIR/page--checkout.html.twig"
echo "   ✓ page--checkout.html.twig → $LAYOUT_DIR/"
echo ""

# ── 4. Libraries YAML ──────────────────────────────────────────────────────────
echo "5. Installing hivesticks.libraries.yml..."
cp "$WORKSPACE/hivesticks.libraries.yml" "$THEME_DIR/${THEME}.libraries.yml"
echo "   ✓ ${THEME}.libraries.yml → $THEME_DIR/"
echo ""

# ── 5. Patch hivesticks.theme — add user variables ─────────────────────────────
echo "6. Patching hivesticks.theme..."
THEME_FILE="$THEME_DIR/${THEME}.theme"

if [ ! -f "$THEME_FILE" ]; then
  echo "   ERROR: $THEME_FILE not found"
  exit 1
fi

python3 - "$THEME_FILE" << 'PYEOF'
import sys, re

path = sys.argv[1]

with open(path, 'r') as f:
    content = f.read()

if 'user_is_logged_in' in content:
    print("   · Already patched — skipping user variable injection.")
    sys.exit(0)

# Three lines to inject right after the opening brace of each preprocess function
INJECT = (
    "\n"
    "  $current_user = \\Drupal::currentUser();\n"
    "  $variables['user_is_logged_in'] = $current_user->isAuthenticated();\n"
    "  $variables['user_uid'] = $current_user->id();"
)

# hivesticks_preprocess_page(&$variables) {
content = re.sub(
    r'(function hivesticks_preprocess_page\s*\(&\$variables\)\s*\{)',
    r'\1' + INJECT,
    content
)

# hivesticks_preprocess_page__front(&$variables) {
content = re.sub(
    r'(function hivesticks_preprocess_page__front\s*\(&\$variables\)\s*\{)',
    r'\1' + INJECT,
    content
)

with open(path, 'w') as f:
    f.write(content)

print("   ✓ Added user_is_logged_in + user_uid to both preprocess hooks")
PYEOF

echo ""

# ── 6. Enable user-related modules (idempotent) ────────────────────────────────
echo "7. Ensuring user + Commerce account modules are enabled..."
ddev drush en -y \
  user \
  commerce_order \
  2>/dev/null || true
echo "   ✓ Modules checked"
echo ""

# ── 7. Clear cache ─────────────────────────────────────────────────────────────
echo "8. Clearing Drupal cache..."
ddev drush cr
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Install complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "What to verify:"
echo ""
echo "  1. Visit https://kartpro.ddev.site/"
echo "     → Nav should show a person icon + 'Sign in' next to the cart."
echo ""
echo "  2. Click 'Sign in' → should go to /user/login"
echo "     → Login form should appear styled (card, honey button, etc.)"
echo ""
echo "  3. Log in with uid=1 admin credentials."
echo "     → Nav should switch to person icon + 'My Orders'."
echo "     → Clicking it should go to /user/1/orders"
echo ""
echo "  4. To enable guest checkout + optional account creation:"
echo "     Commerce > Configuration > Checkout flows > Default > Edit"
echo "     In 'Completion' step — enable 'Guest registration after checkout' pane."
echo ""
echo "  5. Run sync-scripts.sh to commit this script to kartpro."
echo ""
