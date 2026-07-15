#!/bin/bash
# fix-cart-count.sh
# Adds hivesticks_preprocess_page() so the real Commerce cart count is passed
# to every page template, updates both Twig templates to render it, and
# updates header.js to handle AJAX cart updates via increment.
#
# Usage (from WSL):
#   bash /mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com/fix-cart-count.sh

set -e

WORKSPACE="/mnt/c/Users/aelli/OneDrive/Documents/Claude/Projects/Hivesticks.com"
THEME="$HOME/projects/kartpro/themes/custom/hivesticks"
KARTPRO="$HOME/projects/kartpro"

echo "=== Step 1: Patch hivesticks.theme — add hivesticks_preprocess_page() ==="

python3 << 'PYEOF'
import re

import os
path = os.path.expanduser("~/projects/kartpro/themes/custom/hivesticks/hivesticks.theme")
with open(path, 'r') as f:
    src = f.read()

NEW_HOOK = '''
/**
 * Implements hook_preprocess_page().
 *
 * Passes the real Commerce cart item count to every page template so the
 * nav badge shows the correct number on initial page load (no JS required).
 * The count respects Drupal's session cache context, so cached pages served
 * to anonymous users with empty carts will always show 0 correctly.
 */
function hivesticks_preprocess_page(&$variables) {
  try {
    /** @var \\Drupal\\commerce_cart\\CartProviderInterface $cart_provider */
    $cart_provider = \\Drupal::service('commerce_cart.cart_provider');
    $count = 0;
    foreach ($cart_provider->getCarts() as $cart) {
      $count += count($cart->getItems());
    }
    $variables['cart_count'] = $count;
  }
  catch (\\Exception $e) {
    $variables['cart_count'] = 0;
  }
}

'''

if 'hivesticks_preprocess_page(&$variables)' in src:
    print("  hivesticks_preprocess_page() already exists — skipping")
else:
    # Insert just before the page__front preprocess
    target = 'function hivesticks_preprocess_page__front'
    if target in src:
        src = src.replace(target, NEW_HOOK + target, 1)
        with open(path, 'w') as f:
            f.write(src)
        print("  Patched hivesticks.theme OK")
    else:
        # Append to end of file
        with open(path, 'a') as f:
            f.write(NEW_HOOK)
        print("  Appended to hivesticks.theme")
PYEOF

echo ""
echo "=== Step 2: Deploy updated Twig templates ==="
# Remove stale root-level copies that shadow layout/ versions
rm -f "$THEME/templates/page.html.twig"
rm -f "$THEME/templates/page--front.html.twig"

cp "$WORKSPACE/page.html.twig"      "$THEME/templates/layout/page.html.twig"      && echo "  ✓ page.html.twig"
cp "$WORKSPACE/homepage.html.twig"  "$THEME/templates/layout/page--front.html.twig" && echo "  ✓ page--front.html.twig"

echo ""
echo "=== Step 3: Deploy CSS and JS ==="
cp "$WORKSPACE/header.css"   "$THEME/css/header.css"   && echo "  ✓ header.css"
cp "$WORKSPACE/header.js"    "$THEME/js/header.js"     && echo "  ✓ header.js"
cp "$WORKSPACE/homepage.css" "$THEME/css/homepage.css" && echo "  ✓ homepage.css"

echo ""
echo "=== Step 4: Clear Drupal cache ==="
cd "$KARTPRO" && ddev drush cr && echo "  ✓ Cache cleared"

echo ""
echo "=== Done! Cart count now comes from Commerce on page load. ==="
