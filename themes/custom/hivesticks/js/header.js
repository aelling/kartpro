/**
 * HiveSticks Header — shared Drupal behaviors
 *
 * Behaviors:
 *   hsNav       — sticky nav: adds .is-scrolled shadow once the page scrolls.
 *   hsCartIcon  — keeps the "Cart · N" count live after an add-to-cart AJAX.
 *
 * Cart count:
 *   The server renders the correct count inside .hs-nav__cart-count on every
 *   page load via hivesticks_preprocess_page() (Commerce cart provider). If an
 *   add-to-cart ever happens over AJAX, we bump the visible number immediately;
 *   on the next full navigation the server-rendered value takes over again.
 *
 * Note: redirecting to the cart after adding an item is handled server-side in
 * hivesticks.theme (hivesticks_form_alter → hivesticks_redirect_to_cart),
 * because the add-to-cart form is a normal POST, not an AJAX submit.
 */

(function (Drupal, once) {
  'use strict';

  /* ─── Sticky Nav ──────────────────────────────────────────────────────── */
  Drupal.behaviors.hsNav = {
    attach: function (context) {
      once('hs-nav', '[data-behavior="hs-nav"]', context).forEach(function (nav) {
        var THRESHOLD = 60;
        function update() {
          nav.classList.toggle('is-scrolled', window.scrollY > THRESHOLD);
        }
        window.addEventListener('scroll', update, { passive: true });
        update();
      });
    }
  };

  /* ─── Cart count helpers ──────────────────────────────────────────────── */

  function getCountEl() {
    return document.querySelector('.hs-nav__cart-count');
  }

  function getCurrentCount() {
    var el = getCountEl();
    return el ? (parseInt(el.textContent, 10) || 0) : 0;
  }

  function setCount(n) {
    var el = getCountEl();
    if (!el) return;
    el.textContent = n;
    var link = document.querySelector('[data-behavior="hs-cart-icon"]');
    if (link) {
      link.setAttribute('aria-label',
        n === 0 ? Drupal.t('Cart') : Drupal.t('Cart, @count item(s)', { '@count': n })
      );
    }
  }

  /* ─── Cart update detection ──────────────────────────────────────────── */
  Drupal.behaviors.hsCartIcon = {
    attach: function (context, settings) {
      once('hs-cart-ajax', 'body', context).forEach(function () {
        if (typeof window.jQuery === 'undefined') return;
        window.jQuery(document).on('ajaxSuccess.hs', function (e, xhr, cfg) {
          var post = (cfg && cfg.data) || '';
          if (typeof post !== 'string') {
            try { post = window.jQuery.param(post); } catch (_) { post = ''; }
          }
          if (post.indexOf('commerce_order_item_add_to_cart') === -1) return;
          var qm = post.match(/quantity[^=]*=(\d+)/i);
          var qty = qm ? parseInt(qm[1], 10) : 1;
          setCount(getCurrentCount() + qty);
        });
      });
    }
  };

})(Drupal, once);
