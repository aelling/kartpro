<?php
/**
 * find-cart-views.php
 * Run with: ddev drush php-script /path/to/this/file.php
 *
 * Lists every Views display that is mapped to the /cart path.
 * More than one page display -> duplicate cart on the /cart page.
 */

echo "=== Views displays mapped to /cart ===\n\n";

foreach (\Drupal\views\Views::getAllViews() as $view) {
  foreach ($view->get('display') as $display_id => $display) {
    $path = $display['display_options']['path'] ?? '';
    if ($path === 'cart') {
      echo $view->id() . ' / ' . $display_id
        . ' (' . $display['display_plugin'] . ')'
        . ' -> /cart' . "\n";
    }
  }
}

echo "\n=== All displays of commerce_cart_form ===\n\n";

$cart_view = \Drupal\views\Views::getView('commerce_cart_form');
if ($cart_view) {
  foreach ($cart_view->storage->get('display') as $display_id => $display) {
    $path    = $display['display_options']['path']             ?? '(no path)';
    $enabled = $display['display_options']['enabled']          ?? TRUE;
    $type    = $display['display_plugin'];
    echo $display_id . ' [' . $type . '] path:' . $path
      . ' enabled:' . ($enabled ? 'yes' : 'NO') . "\n";
  }
} else {
  echo "commerce_cart_form view not found.\n";
}
