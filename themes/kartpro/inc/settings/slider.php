<?php
$form['slider']['slider_show_section'] = [
  '#type'        => 'fieldset',
  '#title'       => t('Enable Slider'),
  '#description'   => t("Slider will be enabled on the pages that have content in Header Hero block region."),
];
$form['slider']['slider_style'] = [
  '#type'          => 'fieldset',
  '#title'         => t('Slider Style'),
  '#description'   => t('<ul><li>Basic Slider (text only)</li><li>Basic Slider (text and image)</li><li>Classic Slider</li><li>Layered Slider</li></ul>'),
];
$form['slider']['slider_faq'] = [
  '#type'        => 'fieldset',
  '#title'       => t('Frequently Asked Questions'),
  '#description'   => t('<h6>Can I create more than one slider?</h6>
  <p>Yes</p>
  <hr />
  <h6>Can I create slider in inner pages?</h6>
  <p>Yes</p>
  <hr />
  <h6>Does the slider support Drupal multilingual?</h6>
  <p>Yes</p>'),
];
$form['slider']['slider_code'] = [
  '#type'          => 'fieldset',
  '#title'         => t('Slider Code'),
  '#description'   => t('<p>Create a block and place it in the slider block region. Please refer to the <a href="https://drupar.com/node/3347/" target="_blank">slider documentation page</a> for more details.</p><p>Please refer to below links for slider codes.<ul>
    <li><a href="https://drupar.com/node/3361/" target="_blank">Slider Basic</a></li>
    <li><a href="https://drupar.com/node/3362/" target="_blank">Slider Basic With Image</a></li>
    <li><a href="https://drupar.com/node/3363/" target="_blank">Slider Style - Classic</a></li>
    <li><a href="https://drupar.com/node/3364/" target="_blank">Slider Style - Layered</a></li>
    </ul>'),
];
$form['slider']['slider_doc'] = [
  '#type'          => 'fieldset',
  '#title'         => t('Slider Documentation'),
  '#description'   => t('<p>Please refer to the <a href="https://drupar.com/node/3347/" target="_blank">slider documentation page</a> for more details.</p>'),
];