<?php
// Color -> Theme Base Colors
$form['color']['color_default_section'] = [
  '#type'        => 'details',
  '#title'       => t('Use Default Colors'),
  '#attributes' => array('class' => array('set-default-fieldset')),
  '#open' => TRUE,
];
$form['color']['color_default_section']['color_default'] = [
  '#type'          => 'checkbox',
  '#title'         => t('Use default color scheme.'),
  '#default_value' => theme_get_setting('color_default', 'kartpro'
),
  '#description'   => t("Check this option to use default colors. Uncheck to customize theme colors below."),
];
$form['color']['color_theme'] = [
  '#type'        => 'details',
  '#title'       => t('Customize Theme Colors'),
  '#open' => TRUE,
];
$form['color']['color_theme']['color_primary'] = [
  '#type'        => 'color',
  '#field_suffix' => theme_get_setting('color_primary'),
  '#title'       => t('Primary Theme Color'),
  '#default_value' => theme_get_setting('color_primary'),
  '#description' => t('<p>Default value is <strong>#dd3923</strong></p><p><hr /></p>'),
];
$form['color']['color_theme']['color_secondary'] = [
  '#type'        => 'color',
  '#field_suffix' => theme_get_setting('color_secondary'),
  '#title'       => t('Secondary Theme Color'),
  '#default_value' => theme_get_setting('color_secondary', 'kartpro'),
  '#description' => t('<p>Default value is <strong>#3a3b54</strong></p><p><hr /></p>'),
];
$form['color']['color_theme']['color_primary_light'] = [
  '#type'        => 'color',
  '#field_suffix' => theme_get_setting('color_primary_light'),
  '#title'       => t('Light Primary Color'),
  '#default_value' => theme_get_setting('color_primary_light', 'kartpro'),
  '#description' => t('<p>Default value is <strong>#f4efec</strong></p><p><hr /></p>'),
];
$form['color']['color_theme']['color_secondary_light'] = [
  '#type'        => 'color',
  '#field_suffix' => theme_get_setting('color_secondary_light'),
  '#title'       => t('Light Secondary Color'),
  '#default_value' => theme_get_setting('color_secondary_light', 'kartpro'),
  '#description' => t('<p>Default value is <strong>#d9dfee</strong></p><p><hr /></p>'),
];
$form['color']['color_theme']['color_border'] = [
  '#type'        => 'color',
  '#field_suffix' => theme_get_setting('color_border'),
  '#title'       => t('Border and Divider Color'),
  '#default_value' => theme_get_setting('color_border', 'kartpro'),
  '#description' => t('<p>Default value is <strong>#e4dcd4</strong></p><p><hr /></p>'),
];
$form['color']['color_theme']['color_text'] = [
  '#type'        => 'color',
  '#field_suffix' => theme_get_setting('color_text'),
  '#title'       => t('Text Color'),
  '#default_value' => theme_get_setting('color_text', 'kartpro'),
  '#description' => t('<p>Default value is <strong>#4a4a4a</strong></p><p><hr /></p>'),
];
$form['color']['color_theme']['color_bold'] = [
  '#type'        => 'color',
  '#field_suffix' => theme_get_setting('color_bold'),
  '#title'       => t('Bold and Heading Color'),
  '#default_value' => theme_get_setting('color_bold', 'kartpro'),
  '#description' => t('<p>Default value is <strong>#222222</strong></p><p><hr /></p>'),
];
$form['color']['color_theme']['color_text_light'] = [
  '#type'        => 'color',
  '#field_suffix' => theme_get_setting('color_text_light'),
  '#title'       => t('Light Text Color'),
  '#default_value' => theme_get_setting('color_text_light', 'kartpro'),
  '#description' => t('<p>Default value is <strong>#878787</strong></p><p><hr /></p>'),
];
$form['color']['color_theme']['color_dark'] = [
  '#type'        => 'color',
  '#field_suffix' => theme_get_setting('color_dark'),
  '#title'       => t('Dark Color'),
  '#default_value' => theme_get_setting('color_dark', 'kartpro'),
  '#description' => t('<p>Default value is <strong>#0f0f22</strong></p><p><hr /></p>'),
];
$form['color']['color_theme']['bg_body'] = [
  '#type'        => 'color',
  '#field_suffix' => theme_get_setting('bg_body'),
  '#title'       => t('Body Background Color'),
  '#default_value' => theme_get_setting('bg_body', 'kartpro'),
  '#description' => t('<p>Default value is <strong>#ffffff</strong></p><p><hr /></p>'),
];