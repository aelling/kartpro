#!/bin/bash
# find-matcher-api.sh — locates the exact order-item matcher service + comparison
# event in the installed Commerce, so the "don't merge subscribe with one-time"
# fix uses the real API. Paste the output back.
#   cd ~/projects/kartpro && bash find-matcher-api.sh

# Find the commerce module dir (docroot=project root here, but check both).
CM="$HOME/projects/kartpro/modules/contrib/commerce"
[ -d "$CM" ] || CM="$HOME/projects/kartpro/web/modules/contrib/commerce"
echo "Commerce dir: $CM"
echo ""

echo "── 1. OrderEvents constants (looking for a comparison-fields event) ──"
grep -n "const " "$CM/modules/order/src/Event/OrderEvents.php" 2>/dev/null || echo "  (OrderEvents.php not found)"
echo ""

echo "── 2. Any comparison-fields event class / usage ──"
grep -rln "ComparisonFields\|comparison_fields" "$CM/modules/order/src" 2>/dev/null || echo "  (none — this Commerce has no comparison event)"
echo ""

echo "── 3. The order item matcher — service id + how it decides matches ──"
grep -rn "order_item_matcher\|OrderItemMatcher" "$CM/modules/order/commerce_order.services.yml" 2>/dev/null || echo "  (no matcher service in commerce_order.services.yml)"
grep -rln "class OrderItemMatcher" "$CM" 2>/dev/null
echo "  -- matchAll() body (comparison fields it uses / event it dispatches):"
sed -n '/function matchAll/,/^  }/p' "$CM/modules/order/src/OrderItemMatcher.php" 2>/dev/null | head -40
echo ""

echo "── 4. What service does the cart manager use for matching? ──"
CC="$HOME/projects/kartpro/modules/contrib/commerce/modules/cart"
[ -d "$CC" ] || CC="$HOME/projects/kartpro/web/modules/contrib/commerce/modules/cart"
grep -n "matcher" "$CC/commerce_cart.services.yml" 2>/dev/null || echo "  (no matcher ref in commerce_cart.services.yml)"
echo ""

echo "── 5. Live service ids containing 'matcher' ──"
ddev drush ev "foreach(\Drupal::getContainer()->getServiceIds() as \$id){ if(stripos(\$id,'matcher')!==false) print \$id.PHP_EOL; }" 2>/dev/null || echo "  (could not list)"
echo ""
echo "Done. Paste everything above."
