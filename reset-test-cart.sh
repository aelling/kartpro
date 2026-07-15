#!/bin/bash
# reset-test-cart.sh — deletes all in-progress cart orders so subscribe testing
# starts from a clean slate.
#   cd ~/projects/kartpro && bash reset-test-cart.sh
cd "$HOME/projects/kartpro" || exit 1
ddev drush ev "\$ids=\Drupal::entityQuery('commerce_order')->accessCheck(FALSE)->condition('cart',1)->execute(); \$s=\Drupal::entityTypeManager()->getStorage('commerce_order'); if(\$ids){ \$s->delete(\$s->loadMultiple(\$ids)); } print 'Deleted '.count(\$ids).' cart order(s).'.PHP_EOL;"
ddev drush cr
