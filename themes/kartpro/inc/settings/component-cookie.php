<?php
// Components -> Cookie message.
$form['components']['cookie'] = [
  '#type'        => 'details',
  '#title'       => t('Cookie Consent message'),
  '#group' => 'components_tab',
];
$form['components']['cookie']['cookie_message_section'] = [
  '#type'        => 'fieldset',
  '#title'       => t('Cookie Consent message'),
];
$form['components']['cookie']['cookie_message_section']['cookie_message'] = [
  '#type'          => 'checkbox',
  '#title'       => t('Show Cookie Consent Popup Message'),
  '#default_value' => theme_get_setting('cookie_message', 'kartpro'),
  '#description'   => t('Make your website EU Cookie Law Compliant. According to EU cookies law, websites need to get consent from visitors to store or retrieve cookies.'),
];
$form['components']['cookie']['cookie_message_section']['cookie_custom'] = [
  '#type'          => 'checkbox',
  '#title'       => t('Show Custom Cookie Consent Message'),
  '#default_value' => theme_get_setting('cookie_custom', 'kartpro'),
  '#description'   => t('<p>Check this option to show custom cookie consent message. Create a new block and place the block in Cookie Consent Message region. Uncheck this option to show default message text.</p><p>For more details, please refer to the <a href="https://drupar.com/node/3371/" target="_blank">documentation page</a></p>'),
];