<?php
// Components -> Scroll to top.
$form['components']['scrolltotop'] = [
  '#type'  => 'details',
  '#title' => t('Scroll To Top'),
  '#group' => 'components_tab',
];
$form['components']['scrolltotop']['scrolltotop_on'] = [
  '#type'          => 'checkbox',
  '#title'         => t('Enable scroll to top feature.'),
  '#default_value' => theme_get_setting('scrolltotop_on', 'kartpro'),
  '#description'   => t("Check this option to enable scroll to top feature. Uncheck to disable this fearure and hide scroll to top icon."),
];