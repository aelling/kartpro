<?php
// Footer -> Copyright.
$form['footer']['copyright'] = [
  '#type'        => 'fieldset',
  '#title'       => t('Website Copyright Text'),
];
$form['footer']['copyright']['copyright_text'] = [
  '#type'          => 'checkbox',
  '#title'         => t('Show website copyright text in footer.'),
  '#default_value' => theme_get_setting('copyright_text', 'kartpro'),
  '#description'   => t("Check this option to show website copyright text in footer. Uncheck to hide.<br />Read more: <a href='https://drupar.com/node/3352/' target='_blank'>Copyright Text in Footer</a>"),
];
$form['footer']['copyright']['copyright_custom'] = [
  '#type'          => 'checkbox',
  '#title'         => t('Show custom copyright text from copyright block region.'),
  '#default_value' => theme_get_setting('copyright_custom', 'kartpro'),
  '#description'   => t('<p>Check this option to show custom copyright text. Create a new block and place the block in copyright region. Uncheck this option to show default copyright text.</p><p>For more details, please refer to the <a href="https://drupar.com/node/3352/" target="_blank">documentation page</a></p>'),
];