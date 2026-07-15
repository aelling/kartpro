#!/bin/bash
# subscriptions-diag.sh — run AFTER installing commerce_recurring. Reports what it
# provides so the Subscriptions section can be configured + restyled.
#   cd ~/projects/kartpro && bash subscriptions-diag.sh   (paste output back)

echo "══════════════════════════════════════════"
echo " Commerce Recurring diagnostic"
echo "══════════════════════════════════════════"

echo "── 1. Is commerce_recurring enabled? ──"
ddev drush pm:list --status=enabled --field=name 2>/dev/null | grep -iE "recurring|interval" || echo "  (commerce_recurring NOT enabled — run the composer + drush en steps first)"
echo ""

echo "── 2. Billing schedules (config entities) ──"
ddev drush ev "\$b=\Drupal::entityTypeManager()->getStorage('commerce_billing_schedule')->loadMultiple(); if(!\$b){print '(none — need to create one)'.PHP_EOL;} else { foreach(\$b as \$id=>\$s){ print \$id.' | '.\$s->label().PHP_EOL; } }" 2>/dev/null

echo ""
echo "── 3. Subscription types ──"
ddev drush ev "\$t=\Drupal::service('plugin.manager.commerce_subscription_type')->getDefinitions(); foreach(array_keys(\$t) as \$id){ print \$id.PHP_EOL; }" 2>/dev/null

echo ""
echo "── 4. Product variation types + whether subscriptions are enabled on them ──"
ddev drush ev "foreach(\Drupal::entityTypeManager()->getStorage('commerce_product_variation_type')->loadMultiple() as \$id=>\$v){ \$s=\$v->getThirdPartySetting('commerce_recurring','subscription_type'); print \$id.' | '.\$v->label().' | subscription_type='.(\$s ?: 'none').PHP_EOL; }" 2>/dev/null

echo ""
echo "── 5. Subscription user route / views ──"
ddev drush ev "\$r=\Drupal::service('router.route_provider'); foreach(['entity.commerce_subscription.collection','view.subscriptions.user_subscriptions','entity.commerce_subscription.user_view'] as \$n){ try { \$r->getRouteByName(\$n); print \$n.': YES'.PHP_EOL; } catch (\Throwable \$e){ print \$n.': no'.PHP_EOL; } }" 2>/dev/null
ddev drush ev "\$v=\Drupal::entityTypeManager()->getStorage('view')->loadMultiple(); foreach(array_keys(\$v) as \$id){ if(strpos(\$id,'subscription')!==false) print 'view: '.\$id.PHP_EOL; }" 2>/dev/null

echo ""
echo "── 6. Existing subscriptions (count) ──"
ddev drush ev "print 'subscriptions: '.\Drupal::entityQuery('commerce_subscription')->accessCheck(FALSE)->count()->execute();" 2>/dev/null
echo ""
echo "Done. Paste everything above."
