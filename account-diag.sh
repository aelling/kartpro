#!/bin/bash
# account-diag.sh — reports the Commerce/user data layer so the account area can
# be built against the REAL routes/views/entities. Run and paste the output:
#   cd ~/projects/kartpro && bash account-diag.sh

echo "══════════════════════════════════════════"
echo " HiveSticks account-area data layer"
echo "══════════════════════════════════════════"

echo "── 1. Relevant modules enabled? ──"
ddev drush pm:list --status=enabled --field=name 2>/dev/null | grep -iE \
  "commerce_order|commerce_cart|commerce_checkout|commerce_shipping|commerce_recurring|commerce_payment|^profile$|address" \
  || echo "   (none matched)"
echo ""

echo "── 2. Order-history View (the /user/{uid}/orders page) ──"
ddev drush ev "print implode(\"\n\", array_keys(\Drupal::entityTypeManager()->getStorage('view')->loadMultiple()));" 2>/dev/null \
  | grep -iE "order|commerce" || echo "   (no order-ish views found)"
echo ""

echo "── 3. Does the user orders route exist? ──"
ddev drush ev "\$r=\Drupal::service('router.route_provider'); foreach(['entity.commerce_order.user_view','commerce_order.user_orders','entity.commerce_order.collection'] as \$n){ try { \$r->getRouteByName(\$n); print \$n.\": YES\n\"; } catch (\Throwable \$e){ print \$n.\": no\n\"; } }" 2>/dev/null
echo ""

echo "── 4. Profile types (address book) ──"
ddev drush ev "\$t=\Drupal::entityTypeManager()->getStorage('profile_type')->loadMultiple(); foreach(\$t as \$id=>\$p){ print \$id.\"  |  \".\$p->label().\"\n\"; } if(!\$t) print '   (no profile types — address book may not be installed)';" 2>/dev/null
echo ""

echo "── 5. Address-book route? ──"
ddev drush ev "\$r=\Drupal::service('router.route_provider'); foreach(['entity.profile.type.user_profile_form','profile.user_page','entity.profile.collection'] as \$n){ try { \$r->getRouteByName(\$n); print \$n.\": YES\n\"; } catch (\Throwable \$e){ print \$n.\": no\n\"; } }" 2>/dev/null
echo ""

echo "── 6. commerce_order fields (for the order card + detail) ──"
ddev drush ev "\$d=\Drupal::service('entity_field.manager')->getFieldDefinitions('commerce_order','default'); foreach(\$d as \$n=>\$f){ print \$n.\"  (\".\$f->getType().\")\n\"; }" 2>/dev/null | head -40
echo ""

echo "── 7. How many real orders exist, and their states ──"
ddev drush sqlq "SELECT order_id, state, mail, total_price__number FROM commerce_order ORDER BY order_id DESC LIMIT 15;" 2>/dev/null || echo "   (query failed)"
echo ""

echo "── 8. Is Twig debug on? (lets me see template suggestions) ──"
ddev drush ev "print \Drupal::service('twig')->isDebug() ? 'ON' : 'OFF';" 2>/dev/null
echo ""

echo "── 9. Existing commerce/user template overrides in the theme ──"
THEME=$(ddev drush config:get system.theme default --format=string 2>/dev/null | awk 'END{print $NF}' | tr -d '[:space:]')
REL=$(ddev drush ev "print \Drupal::service('extension.list.theme')->getPath('$THEME');" 2>/dev/null | tr -d '[:space:]\r')
find "$HOME/projects/kartpro/$REL/templates" -type f \( -iname "*order*" -o -iname "*user*" -o -iname "*profile*" -o -iname "*views-view*" \) 2>/dev/null | sed "s|$HOME/projects/kartpro/$REL/||"
echo ""
echo "Done. Paste everything above."
