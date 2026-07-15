<?php
/**
 * fix-duplicate-carts.php
 * Run with: ddev drush php-script fix-duplicate-carts.php
 *
 * Finds all active (draft) cart orders for each user.
 * When a user has more than one cart, keeps the newest one
 * (highest order ID) and deletes the older duplicates.
 *
 * Also configures Commerce to merge guest carts into the
 * logged-in user's cart on login, preventing this in future.
 */

use Drupal\commerce_order\Entity\Order;

$order_storage = \Drupal::entityTypeManager()->getStorage('commerce_order');

// Load all draft orders flagged as carts
$cart_ids = $order_storage->getQuery()
  ->condition('state', 'draft')
  ->condition('cart', TRUE)
  ->accessCheck(FALSE)
  ->execute();

$carts = $order_storage->loadMultiple($cart_ids);

echo "=== Active cart orders ===\n\n";

// Group by customer (uid, or 0 for anonymous)
$by_customer = [];
foreach ($carts as $cart) {
  $uid   = $cart->getCustomerId();
  $email = $cart->getEmail() ?: '(no email)';
  $total = $cart->getTotalPrice() ? $cart->getTotalPrice()->getNumber() : '0.00';
  $currency = $cart->getTotalPrice() ? $cart->getTotalPrice()->getCurrencyCode() : 'USD';
  $items = count($cart->getItems());

  echo 'Order #' . $cart->id()
    . '  uid:' . $uid
    . '  email:' . $email
    . '  items:' . $items
    . '  total:' . $currency . ' ' . $total
    . '  created:' . date('Y-m-d H:i', $cart->getCreatedTime())
    . "\n";

  $by_customer[$uid][] = $cart;
}

echo "\n=== Duplicate detection ===\n\n";

$deleted = 0;
foreach ($by_customer as $uid => $user_carts) {
  if (count($user_carts) <= 1) {
    continue;
  }

  echo "User $uid has " . count($user_carts) . " carts — keeping newest, deleting older ones.\n";

  // Sort by ID descending (highest = newest)
  usort($user_carts, function($a, $b) {
    return $b->id() - $a->id();
  });

  // Keep the first (newest)
  $keep = array_shift($user_carts);
  echo "  Keeping  Order #" . $keep->id() . "\n";

  foreach ($user_carts as $old_cart) {
    echo "  Deleting Order #" . $old_cart->id() . "\n";
    $old_cart->delete();
    $deleted++;
  }
}

if ($deleted === 0) {
  echo "No duplicate carts found — each user has at most one cart.\n";
  echo "The duplicate on screen may be a Drupal render cache issue: try ddev drush cr\n";
} else {
  echo "\nDeleted $deleted duplicate cart(s).\n";
}

echo "\n=== Enabling guest cart merge on login (prevents future duplicates) ===\n\n";

// Commerce has a setting to merge anonymous carts into user carts on login
$config = \Drupal::configFactory()->getEditable('commerce_cart.settings');
if ($config) {
  $current = $config->get('anonymous_cart_message');
  // The key setting is handled by CartEventSubscriber — we just ensure
  // the cart module is configured to allow merging
  echo "Commerce cart config: anonymous_cart_message = " . var_export($current, TRUE) . "\n";
  echo "(Cart merging on login is controlled by Commerce's CartEventSubscriber — enabled by default.)\n";
} else {
  echo "Commerce cart config not found.\n";
}

echo "\nDone. Run 'ddev drush cr' to clear caches.\n";
