#!/bin/bash
# shipping-diag.sh — reports the current Commerce Shipping / checkout / store setup
# so shipping methods can be configured correctly. Paste the output back.
#   cd ~/projects/kartpro && bash shipping-diag.sh

echo "══════════════════════════════════════════"
echo " Commerce Shipping diagnostic"
echo "══════════════════════════════════════════"

echo "── 1. Stores (id | name | country | default currency) ──"
ddev drush ev "foreach(\Drupal::entityTypeManager()->getStorage('commerce_store')->loadMultiple() as \$id=>\$s){ print \$id.' | '.\$s->label().' | '.(\$s->getAddress() ? \$s->getAddress()->getCountryCode() : '?').' | '.\$s->getDefaultCurrencyCode().PHP_EOL; }" 2>/dev/null

echo ""
echo "── 2. Order types (id | label) ──"
ddev drush ev "foreach(\Drupal::entityTypeManager()->getStorage('commerce_order_type')->loadMultiple() as \$id=>\$t){ print \$id.' | '.\$t->label().PHP_EOL; }" 2>/dev/null

echo ""
echo "── 3. Is shipping enabled on the default order type? (shipments field present) ──"
ddev drush ev "\$d=\Drupal::service('entity_field.manager')->getFieldDefinitions('commerce_order','default'); print isset(\$d['shipments']) ? 'YES — shipments field exists' : 'NO — shipping not enabled on this order type';" 2>/dev/null
echo ""

echo "── 4. Existing shipping methods (commerce_shipping_method) ──"
ddev drush ev "\$m=\Drupal::entityTypeManager()->getStorage('commerce_shipping_method')->loadMultiple(); if(!\$m){ print '(none configured)'.PHP_EOL; } else { foreach(\$m as \$id=>\$s){ print \$id.' | '.\$s->label().' | plugin='.\$s->get('plugin')[0]['target_plugin_id'].PHP_EOL; } }" 2>/dev/null

echo ""
echo "── 5. Package types ──"
ddev drush ev "\$p=\Drupal::entityTypeManager()->getStorage('commerce_package_type')->loadMultiple(); if(!\$p){ print '(none)'.PHP_EOL; } else { foreach(\$p as \$id=>\$pt){ print \$id.' | '.\$pt->label().PHP_EOL; } }" 2>/dev/null

echo ""
echo "── 6. Checkout flows + whether a shipping pane is configured ──"
ddev drush ev "foreach(\Drupal::entityTypeManager()->getStorage('commerce_checkout_flow')->loadMultiple() as \$id=>\$f){ \$cfg=\$f->get('configuration'); \$has=strpos(json_encode(\$cfg),'shipping')!==false ? 'has shipping pane' : 'NO shipping pane'; print \$id.' | '.\$f->label().' | '.\$has.PHP_EOL; }" 2>/dev/null

echo ""
echo "── 7. commerce_shipping module enabled? ──"
ddev drush pm:list --status=enabled --field=name 2>/dev/null | grep -i shipping || echo "  (commerce_shipping NOT enabled)"
echo ""
echo "Done. Paste everything above."
