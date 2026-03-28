<?php

use Drupal\Core\Form\FormStateInterface;

/**
 * Custom setting for kartpro theme.
 */
function kartpro_form_system_theme_settings_alter(&$form, FormStateInterface $form_state) {
  $form['#attached']['library'][] = 'kartpro/theme-settings';
  $ver = '1.0.2';
  $latest_ver = file_get_contents("https://drupar.com/theme-update-info/kartpro.txt");
  $form['kartpro'] = [
    '#type'       => 'vertical_tabs',
    '#title'      => '<h3 class="settings-form-title">' . t('') . '</h3>',
    '#default_tab' => 'general',
  ];
  // General settings tab.
  $form['general'] = [
    '#type'  => 'details',
    '#title' => t('General'),
    '#description' => t('<h4>Thanks for using KartPro Theme</h4><p>KartPro is a premium Drupal commerce theme designed and developed by <a href="https://drupar.com" target="_blank">Drupar.com</a></p>'),
    '#group' => 'kartpro',
  ];
  // layout tab.
  $form['layout'] = [
    '#type'  => 'details',
    '#title' => t('Layout'),
    '#group' => 'kartpro',
  ];
  // Theme Color tab.
  $form['color'] = [
    '#type'  => 'details',
    '#title' => t('Theme Color'),
    '#group' => 'kartpro',
  ];
  // Social tab.
  $form['social'] = [
    '#type'  => 'details',
    '#title' => t('Social'),
    '#description' => t('These icons appear in the footer region.'),
    '#group' => 'kartpro',
  ];
  // Slider tab.
  $form['slider'] = [
    '#type'  => 'details',
    '#title' => t('Slider'),
    '#group' => 'kartpro',
  ];
  // Header tab.
  $form['header'] = [
    '#type'  => 'details',
    '#title' => t('Header'),
    '#group' => 'kartpro',
  ];
  // Sidebar tab.
  $form['sidebar'] = [
    '#type'  => 'details',
    '#title' => t('Sidebar'),
    '#group' => 'kartpro',
  ];
  // Content tab.
  $form['content'] = [
    '#type'  => 'details',
    '#title' => t('Content'),
    '#group' => 'kartpro',
  ];
  // Footer tab.
  $form['footer'] = [
    '#type'  => 'details',
    '#title' => t('Footer'),
    '#group' => 'kartpro',
  ];
  // components tab.
  $form['components'] = [
    '#type'  => 'details',
    '#title' => t('Components'),
    '#group' => 'kartpro',
  ];
  // Insert codes
  $form['insert_codes'] = [
    '#type'  => 'details',
    '#title' => t('Insert Codes'),
    '#group' => 'kartpro',
  ];
  $form['update'] = [
    '#type'  => 'details',
    '#title' => t('Update'),
    '#description' => t('<h4>Check For Update</h4>'),
    '#group' => 'kartpro',
  ];
  $form['license'] = [
    '#type'  => 'details',
    '#title' => t('Theme License'),
    '#group' => 'kartpro',
  ];
  // Support tab.
  $form['support'] = [
    '#type'  => 'details',
    '#title' => t('Support'),
    '#group' => 'kartpro',
  ];
  // General
  $form['general']['general_info'] = [
    '#type'        => 'fieldset',
    '#title'       => t('Theme Info'),
    '#description' => t('<a href="https://drupar.com/theme/kartpro" target="_blank">Theme Homepage</a> || <a href="https://kartpro.dev5.dev" target="_blank">Theme Demo</a> || <a href="https://drupar.com/doc/kartpro" target="_blank">Theme Documentation</a> || <a href="https://drupar.com/doc/kartpro/support" target="_blank">Theme Support</a>'),
  ];
  // Layout -> Container width
  $form['layout']['layout_container'] = [
    '#type'        => 'fieldset',
    '#title'         => t('Container width (px)'),
  ];
  $form['layout']['layout_container']['container_width'] = [
    '#type'          => 'number',
    '#default_value' => theme_get_setting('container_width', 'kartpro'),
    '#description'   => t('Set width of the container in px. Default width is 1260px.'),
  ];
  // Layout -> Header Layout
  $form['layout']['layout_header'] = [
    '#type'        => 'fieldset',
    '#title'         => t('Header Layout'),
  ];
  $form['layout']['layout_header']['header_width'] = [
    '#type'          => 'select',
    '#options' => array(
    	'header_width_contained' => t('contained'),
    	'header_width_full' => t('Full Width'),),
    '#default_value' => theme_get_setting('header_width', 'kartpro'),
  ];
  // Layout -> Main Layout
  $form['layout']['layout_main'] = [
    '#type'        => 'fieldset',
    '#title'         => t('Main Layout'),
  ];
  $form['layout']['layout_main']['main_width'] = [
    '#type'          => 'select',
    '#options' => array(
    	'main_width_contained' => t('contained'),
    	'main_width_full' => t('Full Width'),),
    '#default_value' => theme_get_setting('main_width', 'kartpro'),
  ];
  // Layout -> Footer Layout
  $form['layout']['layout_footer'] = [
    '#type'        => 'fieldset',
    '#title'         => t('Footer Layout'),
  ];
  $form['layout']['layout_footer']['footer_width'] = [
    '#type'          => 'select',
    '#options' => array(
    	'footer_width_contained' => t('contained'),
    	'footer_width_full' => t('Full Width'),),
    '#default_value' => theme_get_setting('footer_width', 'kartpro'),
  ];
  // Color
  include_once 'inc/settings/color.php';
  
  // Social settings
  /* Social -> Show or hide all icons */
  $form['social']['all_icons'] = [
    '#type'        => 'fieldset',
    '#title'       => t('Show Social Icons'),
  ];
  $form['social']['all_icons']['all_icons_show'] = [
    '#type'          => 'checkbox',
    '#title'         => t('Show social icons in footer'),
    '#default_value' => theme_get_setting('all_icons_show', 'kartpro'),
    '#description'   => t("Check this option to show social icons in footer. Uncheck to hide."),
  ];
  // Facebook.
    $form['social']['facebook'] = [
    '#type'        => 'details',
    '#title'       => t("Facebook"),
  ];
  $form['social']['facebook']['facebook_url'] = [
    '#type'          => 'textfield',
    '#title'         => t('Facebook Url'),
    '#description'   => t("Enter yours facebook profile or page url. Leave the url field blank to hide this icon."),
    '#default_value' => theme_get_setting('facebook_url', 'kartpro'),
  ];
  // Twitter.
  $form['social']['twitter'] = [
    '#type'        => 'details',
    '#title'       => t("Twitter"),
  ];
  $form['social']['twitter']['twitter_url'] = [
    '#type'          => 'textfield',
    '#title'         => t('Twitter Url'),
    '#description'   => t("Enter yours twitter page url. Leave the url field blank to hide this icon."),
    '#default_value' => theme_get_setting('twitter_url', 'kartpro'),
  ];
  // Instagram.
  $form['social']['instagram'] = [
    '#type'        => 'details',
    '#title'       => t("Instagram"),
  ];
  $form['social']['instagram']['instagram_url'] = [
    '#type'          => 'textfield',
    '#title'         => t('Instagram Url'),
    '#description'   => t("Enter yours instagram page url. Leave the url field blank to hide this icon."),
    '#default_value' => theme_get_setting('instagram_url', 'kartpro'),
  ];
  // Linkedin.
  $form['social']['linkedin'] = [
    '#type'        => 'details',
    '#title'       => t("Linkedin"),
  ];
  $form['social']['linkedin']['linkedin_url'] = [
    '#type'          => 'textfield',
    '#title'         => t('Linkedin Url'),
    '#description'   => t("Enter yours linkedin page url. Leave the url field blank to hide this icon."),
    '#default_value' => theme_get_setting('linkedin_url', 'kartpro'),
  ];
  // YouTube.
  $form['social']['youtube'] = [
    '#type'        => 'details',
    '#title'       => t("YouTube"),
  ];
  $form['social']['youtube']['youtube_url'] = [
    '#type'          => 'textfield',
    '#title'         => t('YouTube Url'),
    '#description'   => t("Enter yours youtube.com page url. Leave the url field blank to hide this icon."),
    '#default_value' => theme_get_setting('youtube_url', 'kartpro'),
  ];
  // Vimeo.
  $form['social']['vimeo'] = [
    '#type'        => 'details',
    '#title'       => t("Vimeo"),
  ];
  $form['social']['vimeo']['vimeo_url'] = [
    '#type'          => 'textfield',
    '#title'         => t('YouTube Url'),
    '#description'   => t("Enter yours vimeo.com page url. Leave the url field blank to hide this icon."),
    '#default_value' => theme_get_setting('vimeo_url', 'kartpro'),
  ];
  // Social -> vk.com url.
  $form['social']['vk'] = [
    '#type'        => 'details',
    '#title'       => t("vk.com"),
  ];
  $form['social']['vk']['vk_url'] = [
    '#type'          => 'textfield',
    '#title'         => t('vk.com'),
    '#description'   => t("Enter yours vk.com page url. Leave the url field blank to hide this icon."),
    '#default_value' => theme_get_setting('vk_url', 'kartpro'),
  ];
  // Social -> whatsapp.
  $form['social']['whatsapp'] = [
    '#type'        => 'details',
    '#title'       => t("whatsapp"),
  ];
  $form['social']['whatsapp']['whatsapp_url'] = [
    '#type'          => 'textfield',
    '#title'         => t('WhatsApp'),
    '#description'   => t("Enter yours whatsapp url. Leave the url field blank to hide this icon."),
    '#default_value' => theme_get_setting('whatsapp_url', 'kartpro'),
  ];
  // Social -> github.
  $form['social']['github'] = [
    '#type'        => 'details',
    '#title'       => t("Github"),
  ];
  $form['social']['github']['github_url'] = [
    '#type'          => 'textfield',
    '#title'         => t('Github'),
    '#description'   => t("Enter yours github url. Leave the url field blank to hide this icon."),
    '#default_value' => theme_get_setting('github_url', 'kartpro'),
  ];
  // Social -> telegram.
  $form['social']['telegram'] = [
    '#type'        => 'details',
    '#title'       => t("Telegram"),
  ];
  $form['social']['telegram']['telegram_url'] = [
    '#type'          => 'textfield',
    '#title'         => t('Telegram'),
    '#description'   => t("Enter yours telegram url. Leave the url field blank to hide this icon."),
    '#default_value' => theme_get_setting('telegram_url', 'kartpro'),
  ];
  // Slider
  include_once 'inc/settings/slider.php';
  // Header -> Sticky header.
  $form['header']['sticky_header_section'] = [
    '#type'        => 'fieldset',
    '#title'       => t('Sticky Header'),
  ];

  $form['header']['sticky_header_section']['sticky_header'] = [
    '#type'          => 'checkbox',
    '#title'         => t('Enable Sticky Header'),
    '#default_value' => theme_get_setting('sticky_header', 'kartpro'),
    '#description'   => t("Check this option to enable sticky header. Uncheck to disable."),
  ];
  $form['header']['header_links'] = [
    '#type'        => 'fieldset',
    '#title'       => t('Documentation Links'),
    '#description'   => t('<p><a href="https://drupar.com/node/3340/" target="_blank">How to change favicon icon</a></p><p><a href="https://drupar.com/node/3341" target="_blank">How to manage website logo</a></p><p><a href="https://drupar.com/node/3343" target="_blank">Header Search Form</a></p><p><a href="https://drupar.com/node/3342" target="_blank">Header main menu</a></p>'),
  ];
  // Sidebar
  $form['sidebar']['animated_sidebar'] = [
    '#type'        => 'fieldset',
    '#title'       => t('Animated Sliding Sidebar'),
  ];
  $form['sidebar']['animated_sidebar']['sliding_sidebar'] = [
    '#type'          => 'checkbox',
    '#title'         => t('Enable Sliding Sidebar'),
    '#default_value' => theme_get_setting('sliding_sidebar', 'kartpro'),
    '#description'   => t("Check this option to enable animated sidebar feature. Uncheck to hide.<br />Please refer to this tutorial for details. <a href='https://drupar.com/node/3350/' target='_blank'>How To Create Animated Sliding Sidebar</a>"),
  ];
  // Content
  $form['content']['content_tab'] = [
    '#type'  => 'vertical_tabs',
  ];
  // content -> Demo site
  $form['content_tab']['demo_content'] = [
    '#type'        => 'details',
    '#title'       => t('Demo Site Content'),
    '#description'   => t('You can <a href="https://drupar.com/demo-site/kartpro" target="_blank">purchase demo site content</a> for $19 only. This contains all Drupal files and database file. We can also create demo site on your server.'),
    '#group' => 'content_tab',
  ];
  // content -> Homepage  content
  $form['content_tab']['home_content'] = [
    '#type'        => 'details',
    '#title'       => t('Homepage content'),
    '#description' => t('<p>Please follow this tutorial to add content on homepage.</p><p><a href="https://drupar.com/node/3345" target="_blank">How To Create Homepage</a></p><p><a href="https://drupar.com/node/3346/" target="_blank">How to add content on homepage</a></p>'),
    '#group' => 'content_tab',
  ];
  // content -> Animated Content
  $form['content_tab']['animated_content_tab'] = [
    '#type'        => 'details',
    '#title'       => t('Animated Content'),
    '#group' => 'content_tab',
  ];
  $form['content_tab']['animated_content_tab']['animated_content_section'] = [
    '#type'        => 'fieldset',
    '#title'       => t('Animated Page Content'),
    '#description'   => t('<p><hr /></p><p>With animated page content shortcodes, you can create contents with animation effects. These contents will appear with some animation effect when it will come in browser view.</p><p>Please visit this tutorial page for details. <a href="https://drupar.com/node/3370/" target="_blank">How to create animated content</a>.</p>'),
  ];
  $form['content_tab']['animated_content_tab']['animated_content_section']['animated_content'] = [
    '#type'          => 'checkbox',
    '#title'         => t('Enable Animated Page Content when in view'),
    '#default_value' => theme_get_setting('animated_content', 'kartpro'),
    '#description'   => t("Check this option to enable animated page content when in view feature. Uncheck to disable this feature."),
  ];
  // content -> shortcodes
  $form['content_tab']['shortcode'] = [
    '#type'        => 'details',
    '#title'       => t('Shortcodes'),
    '#description' => t('<p>KartPro theme has some custom shortcodes. You can create some styling content using these shortcodes.</p><p>Please visit this page for list of all available shortcodes and how to use these shortcodes.</p><p><a href="https://drupar.com/node/3356/" target="_blank">Kart Pro Shortcodes</a></p>'),
    '#group' => 'content_tab',
  ];
  // content -> comment
  $form['content_tab']['comment'] = [
    '#type'        => 'details',
    '#title'       => t('Comment'),
    '#description' => t(''),
    '#group' => 'content_tab',
  ];

  // content -> comment -> Highlight author comment
  $form['content_tab']['comment']['comment_section'] = [
    '#type'        => 'fieldset',
    '#title'       => t('Highlight Node Author Comment'),
  ];
  $form['content_tab']['comment']['comment_section']['highlight_author_comment'] = [
    '#type'          => 'checkbox',
    '#title'         => t("Highlight Node Author's Comments"),
    '#default_value' => theme_get_setting('highlight_author_comment', 'kartpro'),
    '#description'   => t("Check this option to highlight node author's comments."),
  ];
  // Footer
  include_once 'inc/settings/footer.php';
  /**
   * Components
   */
  $form['components']['components_tab'] = [
    '#type'  => 'vertical_tabs',
  ];
  // Page loader
  $form['components_tab']['preloader'] = [
    '#type'        => 'details',
    '#title'       => t('Pre Page Loader'),
    '#group' => 'components_tab',
  ];
  $form['components_tab']['preloader']['preloader_section'] = [
    '#type'        => 'fieldset',
    '#title'       => t('Pre Page Loader'),
    '#open' => true,
  ];
  $form['components_tab']['preloader']['preloader_section']['preloader_option'] = [
    '#type'          => 'checkbox',
    '#title'         => t('Show a loading icon before page loads.'),
    '#default_value' => theme_get_setting('preloader_option', 'kartpro'),
    '#description'   => t('Check this option to show a cool animated image until your website is loading. Uncheck to disable this feature. For more details, please refer to the <a href="#" target="_blank">documentation page</a>.'),
  ];
  // Font icons
  $form['components_tab']['icon_tab'] = [
    '#type'        => 'details',
    '#title'       => t('Font Icons'),
    '#group' => 'components_tab',
  ];
  $form['components_tab']['icon_tab']['fontawesome6_sec'] = [
    '#type'        => 'fieldset',
    '#title'       => t('FontAwesome 6'),
  ];
  $form['components_tab']['icon_tab']['fontawesome6_sec']['fontawesome_six'] = [
    '#type'          => 'checkbox',
    '#title'         => t('Enable FontAwesome 6 Font Icons'),
    '#default_value' => theme_get_setting('fontawesome_six', 'kartpro'),
    '#description'   => t('<p>Check this option to enable fontawesome version 6 font icons.</p><p><a href="https://drupar.com/node/3355/">How to use FontAwesome 6</a></p>'),
  ];
  $form['components_tab']['icon_tab']['bootstrap_icons'] = [
    '#type'        => 'fieldset',
    '#title'       => t('Bootstrap Font Icons'),
    '#description'   => t('Bootstrap Font Icons is enabled by default. You can use these font icons on your website. Read more about <a href="https://drupar.com/node/3125" target="_blank">Bootstrap Icons</a>'),
  ];
  // share page
  include_once 'inc/settings/share.php';
  // Components - Scroll to top
  include_once 'inc/settings/component-scroll.php';
  // Components - Cookie Consent message
  include_once 'inc/settings/component-cookie.php';
  // Insert Codes
  include_once 'inc/settings/insert-codes.php';
  // Update
  include_once 'inc/settings/update.php';
  // License
  $form['license']['info'] = [
    '#type'        => 'fieldset',
    '#title'       => t('License Type'),
    '#description' => t('<p>Your theme license is: <strong>Single Domain License</strong></p>
    <p>You are allowed to use this theme on a single website. For details, please refer to <a href="https://drupar.com/theme-license" target="_blank">Theme License Details</a></p>
    <hr /><br /><a href="https://drupar.com/upgrade/kartpro" target="_blank">Upgrade to unlimited domain license</a>. Upgrade fee is $30 only.'),
  ];
  // Support
  $form['support']['info'] = [
    '#type'        => 'fieldset',
    '#title'         => t('Theme Support'),
    '#description' => t('<h4>Documentation</h4>
    <p>We have a detailed documentation about how to use theme. Please read the <a href="https://drupar.com/doc/kartpro" target="_blank">KartPro Theme Documentation</a>.</p>
    <hr />
    <h4>Create Support Ticket</h4>
    <p>If you need support that is beyond our theme documentation, please <a href="https://drupar.com/node/add/ticket" target="_blank">create a support ticket</a>.</p>
    <hr />
    <h4>Contact Us</h4>
    <p>If you need some specific customization in theme, please contact us<br><a href="https://drupar.com/contact" target="_blank">drupar.com/contact</a></p>'),
  ];
}
