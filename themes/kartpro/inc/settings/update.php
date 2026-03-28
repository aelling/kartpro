<?php
// Update
$form['update']['update_theme'] = [
  '#type'        => 'fieldset',
  '#title'       => t('Current Theme Version'),
  '#description' => t("$ver"),
];
$form['update']['update_info'] = [
  '#type'        => 'fieldset',
  '#title'       => t('Latest Kart Pro Version'),
  '#description' => t("<pre>$latest_ver</pre><p><hr /></p><p><a href='https://drupar.com/node/3359/' target='_blank'>How To Update Kart Pro Theme</a></p>"),
];