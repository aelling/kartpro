<?php

namespace Drupal\Tests\commerce_stripe\Kernel;

use Drupal\KernelTests\KernelTestBase;
use Stripe\Stripe as StripeLibrary;

/**
 * Tests the Stripe app information.
 *
 * @note This cannot be a Unit test due to dependency on system_get_info().
 *
 * @group commerce_stripe
 */
class AppInfoTest extends KernelTestBase {

  /**
   * {@inheritdoc}
   */
  protected static $modules = [
    'system',
    'entity',
    'commerce',
    'commerce_order',
    'commerce_payment',
    'commerce_price',
    'commerce_stripe',
  ];

  /**
   * Tests Stripe app info set during plugin initialization.
   */
  public function testStripeAppInfo() {
    $secret_key = $this->randomMachineName();

    /** @var \Drupal\commerce_payment\PaymentGatewayManager $gateway_manager */
    $gateway_manager = $this->container->get('plugin.manager.commerce_payment_gateway');

    $gateway_manager->createInstance('stripe', [
      'mode' => 'test',
      'secret_key' => $secret_key,
      'payment_method_types' => ['credit_card'],
      'display_label' => 'Stripe',
    ]);

    $app_info = StripeLibrary::getAppInfo();
    $this->assertEquals([
      'name' => 'Centarro Commerce for Drupal',
      'partner_id' => 'pp_partner_Fa3jTqCJqTDtHD',
      'url' => 'https://www.drupal.org/project/commerce_stripe',
      'version' => '8.x-1.0-dev',
    ], $app_info);
  }

}
