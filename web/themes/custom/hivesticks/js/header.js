/**
 * HiveSticks Header — shared Drupal behaviors
 *
 * Behaviors:
 *   hsNav       — sticky nav: adds .is-scrolled shadow once the page scrolls.
 *   hsCartIcon  — keeps the "Cart · N" count live after add-to-cart AJAX.
 *
 * How cart count works:
 *   The server renders the correct count inside .hs-nav__cart-count on every
 *   page load via hivesticks_preprocess_page() (Commerce cart provider).
 *   After an AJAX add-to-cart we increment the visible number immediately so
 *   the user sees feedback without a page reload. On the next full navigation
 *   the server-rendered value takes over again.
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
    // Update the accessible label on the cart link
    var link = document.querySelector('[data-behavior="hs-cart-icon"]');
    if (link) {
      link.setAttribute('aria-label',
        n === 0 ? Drupal.t('Cart') : Drupal.t('Cart, @count item(s)', { '@count': n })
      );
    }
  }

  /* ─── Add-to-cart prompt (toast) ─────────────────────────────────────── */

  var CART_URL = '/cart';
  var toastTimer = null;

  function buildToast() {
    var existing = document.querySelector('.hs-cart-toast');
    if (existing) return existing;

    var toast = document.createElement('div');
    toast.className = 'hs-cart-toast';
    toast.setAttribute('role', 'alert');
    toast.setAttribute('aria-live', 'polite');
    toast.innerHTML =
      '<button type="button" class="hs-cart-toast__close" aria-label="' +
        Drupal.t('Dismiss') + '">&times;</button>' +
      '<div class="hs-cart-toast__head">' +
        '<span class="hs-cart-toast__check" aria-hidden="true">' +
          '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" ' +
          'fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" ' +
          'stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>' +
        '</span>' +
        '<span class="hs-cart-toast__title">' + Drupal.t('Added to cart') + '</span>' +
      '</div>' +
      '<p class="hs-cart-toast__body">' +
        Drupal.t('Your item is in the cart. Ready to check out?') + '</p>' +
      '<div class="hs-cart-toast__actions">' +
        '<a href="' + CART_URL + '" class="hs-cart-toast__btn hs-cart-toast__btn--primary">' +
          Drupal.t('Go to cart') + '</a>' +
        '<button type="button" class="hs-cart-toast__btn hs-cart-toast__btn--ghost" ' +
          'data-hs-toast-dismiss>' + Drupal.t('Keep shopping') + '</button>' +
      '</div>';

    document.body.appendChild(toast);

    function hide() {
      toast.classList.remove('is-visible');
      if (toastTimer) { clearTimeout(toastTimer); toastTimer = null; }
    }
    toast.querySelector('.hs-cart-toast__close').addEventListener('click', hide);
    toast.querySelector('[data-hs-toast-dismiss]').addEventListener('click', hide);

    return toast;
  }

  function showCartPrompt() {
    var toast = buildToast();
    // Force reflow so the transition runs even if just appended.
    void toast.offsetWidth;
    toast.classList.add('is-visible');
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(function () {
      toast.classList.remove('is-visible');
      toastTimer = null;
    }, 7000);
  }

  /* ─── Cart update detection ──────────────────────────────────────────── */
  Drupal.behaviors.hsCartIcon = {
    attach: function (context, settings) {
      // Single strategy: jQuery ajaxSuccess.
      // Commerce's ATC form always includes 'commerce_order_item_add_to_cart'
      // in the form_id POST field — that's our reliable one-fire-per-event signal.
      // We parse the submitted quantity directly from POST so packs of 5
      // increment by 5, not by 1. Runs once per page via once().
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
          showCartPrompt();
        });
      });
    }
  };

})(Drupal, once);
