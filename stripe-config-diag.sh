#!/bin/bash
# stripe-config-diag.sh — read-only report of the Stripe gateway + Key setup so
# the test/live key strategy can be tailored. Does NOT print secret values.
#   cd ~/projects/kartpro && bash stripe-config-diag.sh   (paste output back)

echo "══════════════════════════════════════════"
echo " Stripe / Key configuration report"
echo "══════════════════════════════════════════"

echo "── 1. commerce_stripe + key module versions ──"
ddev drush pm:list --field=name,version --filter=stripe 2>/dev/null
ddev drush pm:list --status=enabled --field=name 2>/dev/null | grep -x "key" >/dev/null && echo "  key module: ENABLED" || echo "  key module: not enabled"
CM="$HOME/projects/kartpro/modules/contrib/commerce_stripe"
[ -d "$CM" ] || CM="$HOME/projects/kartpro/web/modules/contrib/commerce_stripe"
grep -m1 "version" "$CM/commerce_stripe.info.yml" 2>/dev/null
echo ""

echo "── 2. Payment gateways (id | plugin | mode | status) ──"
ddev drush ev "foreach(\Drupal::entityTypeManager()->getStorage('commerce_payment_gateway')->loadMultiple() as \$id=>\$g){ \$c=\$g->getPluginConfiguration(); print \$id.' | plugin='.\$g->getPluginId().' | mode='.(\$c['mode']??'?').' | status='.(\$g->status()?'on':'off').PHP_EOL; }" 2>/dev/null
echo ""

echo "── 3. Stripe gateway config KEYS (names only, secret value masked) ──"
ddev drush ev "\$gs=\Drupal::entityTypeManager()->getStorage('commerce_payment_gateway')->loadMultiple(); foreach(\$gs as \$id=>\$g){ if(strpos(\$g->getPluginId(),'stripe')===false) continue; print 'gateway: '.\$id.PHP_EOL; foreach(\$g->getPluginConfiguration() as \$k=>\$v){ if(is_scalar(\$v)){ \$show = in_array(\$k,['secret_key','publishable_key']) ? (\$v==='' ? '(empty)' : '(set, '.strlen((string)\$v).' chars, starts \"'.substr((string)\$v,0,7).'\")') : var_export(\$v,true); print '   '.\$k.' = '.\$show.PHP_EOL; } else { print '   '.\$k.' = ['.gettype(\$v).']'.PHP_EOL; } } }" 2>/dev/null
echo ""

echo "── 4. Does the gateway config use a Key reference for the secret? ──"
ddev drush ev "\$gs=\Drupal::entityTypeManager()->getStorage('commerce_payment_gateway')->loadMultiple(); foreach(\$gs as \$id=>\$g){ if(strpos(\$g->getPluginId(),'stripe')===false) continue; \$c=\$g->getPluginConfiguration(); \$sk=\$c['secret_key']??''; if(\Drupal::moduleHandler()->moduleExists('key') && \Drupal::entityTypeManager()->getStorage('key')->load(\$sk)){ print '   secret_key is a KEY entity id: '.\$sk.PHP_EOL; } else { print '   secret_key looks like a RAW value (not a Key reference).'.PHP_EOL; } }" 2>/dev/null
echo ""

echo "── 5. Existing Key entities (if key module on) ──"
ddev drush ev "if(\Drupal::moduleHandler()->moduleExists('key')){ \$ks=\Drupal::entityTypeManager()->getStorage('key')->loadMultiple(); if(!\$ks){print '   (none)';} foreach(\$ks as \$id=>\$k){ print '   '.\$id.' | provider='.\$k->getKeyProvider()->getPluginId().PHP_EOL; } } else { print '   (key module not enabled)'; }" 2>/dev/null
echo ""
echo "Done. Paste everything above (no secret values are shown)."
