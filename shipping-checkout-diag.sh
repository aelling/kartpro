#!/bin/bash
# shipping-checkout-diag.sh — why doesn't the shipping pane appear at checkout?
#   cd ~/projects/kartpro && bash shipping-checkout-diag.sh   (paste output)

echo "══════════════════════════════════════════"
echo " Shipping-at-checkout diagnostic"
echo "══════════════════════════════════════════"

echo "── 1. Which checkout flow does the 'default' order type use? ──"
ddev drush ev "\$t=\Drupal::entityTypeManager()->getStorage('commerce_order_type')->load('default'); print 'checkout_flow = '.\$t->getThirdPartySetting('commerce_checkout','checkout_flow', '(none)').PHP_EOL;" 2>/dev/null

echo ""
echo "── 2. Is the honey_stick_pack variation type SHIPPABLE? ──"
ddev drush ev "\$vt=\Drupal::entityTypeManager()->getStorage('commerce_product_variation_type')->load('honey_stick_pack'); print 'traits: '.implode(', ', \$vt->getTraits() ?: ['(none)']).PHP_EOL;" 2>/dev/null
ddev drush ev "\$d=\Drupal::service('entity_field.manager')->getFieldDefinitions('commerce_product_variation','honey_stick_pack'); print isset(\$d['weight']) ? 'weight field: YES (shippable)' : 'weight field: NO (NOT shippable)';" 2>/dev/null
echo ""

echo "── 3. Do the honey_stick_pack variations have a weight set? ──"
ddev drush ev "\$ids=\Drupal::entityQuery('commerce_product_variation')->accessCheck(FALSE)->condition('type','honey_stick_pack')->range(0,5)->execute(); foreach(\Drupal::entityTypeManager()->getStorage('commerce_product_variation')->loadMultiple(\$ids) as \$v){ \$w = \$v->hasField('weight') && !\$v->get('weight')->isEmpty() ? \$v->get('weight')->number.' '.\$v->get('weight')->unit : 'EMPTY'; print '  variation '.\$v->id().' ('.\$v->getSku().') weight='.\$w.PHP_EOL; }" 2>/dev/null
echo ""

echo "── 4. Panes in each checkout flow (looking for shipping_information) ──"
ddev drush ev "foreach(\Drupal::entityTypeManager()->getStorage('commerce_checkout_flow')->loadMultiple() as \$id=>\$f){ print 'FLOW: '.\$id.PHP_EOL; \$panes=\$f->get('configuration')['panes'] ?? []; foreach(\$panes as \$pid=>\$c){ if(strpos(\$pid,'shipping')!==false || \$pid=='shipping_information'){ print '   '.\$pid.' | step='.(\$c['step']??'?').' | weight='.(\$c['weight']??'?').PHP_EOL; } } }" 2>/dev/null
echo ""

echo "── 5. Order 16 — is it shippable / does it have shipments? ──"
ddev drush ev "\$o=\Drupal::entityTypeManager()->getStorage('commerce_order')->load(16); if(!\$o){print 'order 16 not found';} else { print 'order type: '.\$o->bundle().PHP_EOL; \$shippable=false; foreach(\$o->getItems() as \$i){ \$pe=\$i->getPurchasedEntity(); if(\$pe && \$pe->hasField('weight')) \$shippable=true; } print 'has shippable items: '.(\$shippable?'YES':'NO').PHP_EOL; print 'shipments field empty: '.(\$o->get('shipments')->isEmpty()?'yes':'no').PHP_EOL; }" 2>/dev/null
echo ""
echo "Done. Paste everything above."
