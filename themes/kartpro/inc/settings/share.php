<?php
$form['components_tab']['node_share'] = [
  '#type'        => 'details',
  '#title'       => t('Share Page'),
  '#group' => 'components_tab',
];
// Social-> Node sharing option.
$form['components_tab']['node_share']['page_share'] = [
  '#type'        => 'fieldset',
  '#title'       => t('Node Sharing on Social Networking Websites'),
];
$form['components_tab']['node_share']['page_share']['page_share_all'] = [
  '#type'          => 'checkbox',
  '#title'         => t('Enable Node Sharing Feature'),
  '#default_value' => theme_get_setting('page_share_all', 'kartpro'),
  '#description'   => t("Check this option to enable site wide social sharing. Below you can enable or disable for individual content type and frontpage. Uncheck to disable this feature for all pages."),
];

$form['components_tab']['node_share']['page_share']['page_share_front'] = [
  '#type'          => 'checkbox',
  '#title'         => t('Share Homepage'),
  '#default_value' => theme_get_setting('page_share_front', 'kartpro'),
  '#description'   => t("Check this option to show social sharing buttons (facebook, twitter, Instagram etc) on <strong>Homepage</strong>. Uncheck to hide."),
];

$form['components_tab']['node_share']['page_share']['page_share_page'] = [
  '#type'          => 'checkbox',
  '#title'         => t('Share Page Content Type'),
  '#default_value' => theme_get_setting('page_share_page', 'kartpro'),
  '#description'   => t("Check this option to show social sharing buttons (facebook, twitter, Instagram etc) on <strong>Basic page</strong> content type nodes. Uncheck to hide."),
];

$form['components_tab']['node_share']['page_share']['page_share_article'] = [
  '#type'          => 'checkbox',
  '#title'         => t('Share Article Content Type'),
  '#default_value' => theme_get_setting('page_share_article', 'kartpro'),
  '#description'   => t("Check this option to show social sharing buttons (facebook, twitter, Instagram etc) on <strong>Article</strong> content type nodes. Uncheck to hide."),
];

$form['components_tab']['node_share']['page_share']['page_share_book'] = [
  '#type'          => 'checkbox',
  '#title'         => t('Share Book Pages'),
  '#default_value' => theme_get_setting('page_share_book', 'kartpro'),
  '#description'   => t("Check this option to show social sharing buttons (facebook, twitter, Instagram etc) on <strong>Book</strong> type nodes. Uncheck to hide."),
];

$form['components_tab']['node_share']['page_share']['page_share_other'] = [
  '#type'          => 'checkbox',
  '#title'         => t('Share Other Content Types'),
  '#default_value' => theme_get_setting('page_share_other', 'kartpro'),
  '#description'   => t("Check this option to show social sharing buttons (facebook, twitter, Instagram etc) on other content type nodes. Uncheck to hide."),
];