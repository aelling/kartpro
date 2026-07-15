/**
 * checkout.js — HiveSticks V3 checkout enhancements
 * deploy to: themes/custom/hivesticks/js/checkout.js
 *
 * Matches the React prototype design from the zip:
 *   LOGIN   — icon chips, subtitles, benefit bullets, dark guest button
 *   STEPS   — "Step N of N" eyebrow on each card
 *   SIDEBAR — Secure checkout badge + payment chips below order summary
 *   PAYMENT — lock note inside payment card
 *   COMPLETE — centred confirmation header with checkmark, body, back button
 */
(function (Drupal, once) {
  'use strict';

  /* ── Step detection ──────────────────────────────────────────────────── */
  var _path         = window.location.pathname;
  var IS_LOGIN      = _path.includes('/login');
  var IS_ORDER_INFO = _path.includes('/order_information');
  var IS_PAYMENT    = _path.includes('/payment');
  var IS_COMPLETE   = _path.includes('/complete');

  /* ── SVG icons ───────────────────────────────────────────────────────── */
  var ICON_PERSON =
    '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">' +
    '<circle cx="12" cy="8" r="4" stroke="currentColor" stroke-width="1.7"/>' +
    '<path d="M4 20c0-3.5 3.6-6 8-6s8 2.5 8 6" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/>' +
    '</svg>';

  var ICON_DROP =
    '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">' +
    '<path d="M12 3C12 3 5 10.5 5 15a7 7 0 0 0 14 0c0-4.5-7-12-7-12Z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/>' +
    '</svg>';

  var ICON_LOCK =
    '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" aria-hidden="true">' +
    '<path d="M6 10V8a6 6 0 0 1 12 0v2M5 10h14v10H5z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/>' +
    '</svg>';

  var ICON_CHECK_LG =
    '<svg width="38" height="38" viewBox="0 0 24 24" fill="none" aria-hidden="true">' +
    '<path d="M5 12.5l4.5 4.5L19 7.5" stroke="#a8640e" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  /* ── DOM helpers ─────────────────────────────────────────────────────── */
  function makeChip(iconHtml, honey) {
    var el = document.createElement('span');
    el.className = 'hs-co-card-chip' + (honey ? ' hs-co-card-chip--honey' : '');
    el.innerHTML = iconHtml;
    return el;
  }

  function makeEl(tag, cls, text) {
    var el = document.createElement(tag);
    el.className = cls;
    if (text) el.textContent = text;
    return el;
  }

  function makeBenefits(items) {
    var ul = makeEl('ul', 'hs-co-benefits');
    items.forEach(function (t) {
      var li = document.createElement('li');
      li.innerHTML = '<span class="hs-co-check" aria-hidden="true">✓</span>' + t;
      ul.appendChild(li);
    });
    return ul;
  }

  /* ── Page-embedded cart data (set by hivesticks_preprocess_page__checkout) ── */
  function getPageCartData() {
    var el = document.getElementById('hs-cart-data');
    if (!el) return null;
    try { return JSON.parse(el.textContent || el.innerHTML); } catch (e) { return null; }
  }

  function renderBagFromPage(bagEl, data) {
    var itemsEl = bagEl.querySelector('.hs-co-bag-items');
    if (!itemsEl) return;

    if (!data.items || !data.items.length) {
      itemsEl.innerHTML = '<p class="hs-co-bag-note">Your cart is empty.</p>';
      return;
    }

    var html = '';
    data.items.forEach(function (item) {
      html +=
        '<div class="hs-co-bag-item">' +
          '<div class="hs-co-bag-thumb" aria-hidden="true">🍯</div>' +
          '<div>' +
            '<div class="hs-co-bag-item-name">' + escHtml(item.title) + '</div>' +
            '<div class="hs-co-bag-item-qty">Qty ' + item.quantity + '</div>' +
          '</div>' +
          '<div class="hs-co-bag-item-price">' + escHtml(item.total) + '</div>' +
        '</div>';
    });

    html +=
      '<div class="hs-co-bag-total">' +
        '<span>Subtotal · ' + data.count + ' item' + (data.count === 1 ? '' : 's') + '</span>' +
        '<span class="hs-co-bag-total-amount">' + escHtml(data.total) + '</span>' +
      '</div>' +
      '<p class="hs-co-bag-note">Shipping &amp; tax calculated at checkout.</p>';

    itemsEl.innerHTML = html;
  }

  /* ── Bag sidebar renderer (AJAX fallback) ────────────────────────────── */
  function renderBag(bagEl, data, orderId) {
    /* Commerce cart REST returns an array of cart objects.
       Find the one matching our order (by order_id or use the first). */
    var carts = Array.isArray(data) ? data : (data.carts || []);
    var cart = carts.find(function (c) {
      return String(c.order_id) === String(orderId);
    }) || carts[0];

    var itemsEl = bagEl.querySelector('.hs-co-bag-items');
    if (!itemsEl) return;

    if (!cart) {
      itemsEl.innerHTML = '<p class="hs-co-bag-note">No items found.</p>';
      return;
    }

    var items = cart.order_items || [];
    var subtotal = (cart.order_total && cart.order_total.subtotal) || {};
    var subtotalFormatted = subtotal.formatted || ('$' + parseFloat(subtotal.number || 0).toFixed(2));

    var html = '';
    items.forEach(function (item) {
      var name  = item.title || 'Honey sticks';
      var qty   = parseFloat(item.quantity || 1);
      var price = (item.total_price && item.total_price.formatted) || '';
      html +=
        '<div class="hs-co-bag-item">' +
          '<div class="hs-co-bag-thumb" aria-hidden="true">🍯</div>' +
          '<div>' +
            '<div class="hs-co-bag-item-name">' + escHtml(name) + '</div>' +
            '<div class="hs-co-bag-item-qty">Qty ' + qty + '</div>' +
          '</div>' +
          '<div class="hs-co-bag-item-price">' + escHtml(price) + '</div>' +
        '</div>';
    });

    html +=
      '<div class="hs-co-bag-total">' +
        '<span>Subtotal · ' + items.length + ' item' + (items.length === 1 ? '' : 's') + '</span>' +
        '<span class="hs-co-bag-total-amount">' + escHtml(subtotalFormatted) + '</span>' +
      '</div>' +
      '<p class="hs-co-bag-note">Shipping &amp; tax calculated at checkout.</p>';

    itemsEl.innerHTML = html;
  }

  function escHtml(str) {
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  /* ════════════════════════════════════════════════════════════════════════
     BEHAVIOR
     ════════════════════════════════════════════════════════════════════════ */
  Drupal.behaviors.hsCheckout = {
    attach: function (context) {

      /* ── LOGIN STEP: icon chips, subtitles, benefit bullets ──────────── */
      if (IS_LOGIN) {
        /* Body class drives CSS that collapses the phantom 380px sidebar column */
        document.body.classList.add('hs-co-login-page');

        /* ── Inject "In your bag" sidebar ─────────────────────────────────
           Commerce doesn't render the order summary block on the login step by
           default. We inject it ourselves and try to populate it from the
           Commerce cart REST endpoint.  Falls back gracefully on any error.
           ──────────────────────────────────────────────────────────────── */
        once('hs-co-bag', '.hs-checkout-wrap', context).forEach(function (wrap) {
          /* Build the sidebar card immediately so it takes up its grid column */
          var bag = document.createElement('aside');
          bag.className = 'hs-co-bag-aside';
          bag.innerHTML =
            '<h2>In your cart</h2>' +
            '<div class="hs-co-bag-items"><div class="hs-co-bag-loading">Loading…</div></div>' +
            '<a href="/cart" class="hs-co-bag-back">← Back to cart</a>';

          /* Insert it after the form/wrapper that holds the two login cards.
             We try several candidate parent elements (different Commerce versions
             emit different wrapper classes). */
          var insertTarget =
            wrap.querySelector('.commerce-checkout-flow') ||
            wrap.querySelector('.layout-regions-checkout') ||
            wrap.querySelector('form');

          if (insertTarget) {
            insertTarget.appendChild(bag);

            /* Make sure the insertTarget's grid has room for a third column.
               The CSS sets the outer grid to 1fr when .hs-co-login-page is on <body>,
               so we only need to re-widen it now that we're adding a third sibling. */
            insertTarget.style.gridTemplateColumns = '1fr 1fr 360px';

            /* If the two fieldsets are wrapped in .js-form-wrapper, make it
               display:contents so the fieldsets participate in the outer 3-col grid. */
            var jsWrap = insertTarget.querySelector(':scope > .js-form-wrapper');
            if (jsWrap) jsWrap.style.display = 'contents';
          }

          /* ── Populate bag ────────────────────────────────────────────────
             Primary: read JSON embedded by hivesticks_preprocess_page__checkout()
             in hivesticks.theme — no network call needed, data is already in the page.
             Fallback: try Commerce REST endpoints (require extra module config).
             Last resort: show a "View your cart" link.
             ────────────────────────────────────────────────────────────────── */
          var orderMatch = window.location.pathname.match(/\/checkout\/(\d+)\//);
          if (!orderMatch) return;
          var orderId = orderMatch[1];

          var pageData = getPageCartData();
          if (pageData && pageData.items && pageData.items.length > 0) {
            /* Best path: server already gave us everything we need */
            renderBagFromPage(bag, pageData);
          } else {
            /* Fallback: AJAX to Commerce REST endpoints */
            var apiUrls = [
              '/api/carts?_format=json',
              '/cart?_format=json',
            ];

            function tryFetch(urls, index) {
              if (index >= urls.length) {
                /* All endpoints failed — show a cart link fallback */
                var loading = bag.querySelector('.hs-co-bag-loading');
                if (loading) loading.innerHTML =
                  '<a href="/cart" style="color:inherit;text-decoration:underline">View your cart →</a>';
                return;
              }
              fetch(urls[index], { credentials: 'same-origin' })
                .then(function (r) { return r.ok ? r.json() : Promise.reject(r.status); })
                .then(function (data) { renderBag(bag, data, orderId); })
                .catch(function () { tryFetch(urls, index + 1); });
            }

            tryFetch(apiUrls, 0);
          }
        });

        /* ── Decorate login fieldsets with icon chips + text ───────────── */
        once('hs-co-login', '.hs-checkout-wrap fieldset', context).forEach(function (fieldset, idx) {
          var legend  = fieldset.querySelector('legend');
          var wrapper = fieldset.querySelector('.fieldset-wrapper');
          if (!legend || !wrapper) return;

          /* Hide any paragraphs Drupal Commerce injects natively so we don't
             duplicate them with our own injections below */
          Array.prototype.forEach.call(wrapper.querySelectorAll('p'), function (p) {
            p.style.display = 'none';
          });

          fieldset.classList.add('hs-co-login-card');
          legend.classList.add('hs-co-legend-enhanced');

          if (idx === 0) {
            /* ── Returning customer ── */
            legend.insertBefore(makeChip(ICON_PERSON, false), legend.firstChild);
            wrapper.insertBefore(
              makeEl('p', 'hs-co-card-subtitle', 'Sign in for saved addresses & faster checkout.'),
              wrapper.firstChild
            );
          } else {
            /* ── Guest checkout ── */
            legend.insertBefore(makeChip(ICON_DROP, true), legend.firstChild);

            var benefits = makeBenefits([
              'Order confirmation by email',
              'Same compostable mailer, same farm',
              'Free returns within 30 days'
            ]);
            var para     = makeEl('p', 'hs-co-card-para',
              'Proceed straight to shipping & payment. You can optionally create an account at the end to track your order and reorder in one tap.');
            var subtitle = makeEl('p', 'hs-co-card-subtitle', 'No account needed — fastest way through.');

            wrapper.insertBefore(benefits, wrapper.firstChild);
            wrapper.insertBefore(para,     wrapper.firstChild);
            wrapper.insertBefore(subtitle, wrapper.firstChild);

            /* Dark button */
            var btn = wrapper.querySelector('input[type="submit"], .button, .form-submit');
            if (btn) btn.classList.add('hs-co-btn-dark');
          }
        });
      }

      /* ── CARD EYEBROW: "STEP N OF N" on order_information & payment ─── */
      once('hs-co-eyebrow', '.layout-region-checkout-main', context).forEach(function (region) {
        /* Only count fieldsets that are visually present — Commerce sometimes
           adds hidden method-selector panes that inflate the "N of N" count. */
        var cards = Array.prototype.slice.call(region.querySelectorAll('fieldset')).filter(function (fs) {
          return fs.offsetParent !== null && getComputedStyle(fs).display !== 'none';
        });
        var total = cards.length;
        if (!total) return;
        cards.forEach(function (fieldset, i) {
          var legend = fieldset.querySelector('legend');
          if (!legend) return;
          var eyebrow = makeEl('span', 'hs-co-eyebrow', 'Step ' + (i + 1) + ' of ' + total);
          legend.insertBefore(eyebrow, legend.firstChild);
        });
      });

      /* ── PAYMENT CARD: lock note ─────────────────────────────────────── */
      once('hs-co-payment-lock', '.hs-checkout-wrap fieldset', context).forEach(function (fieldset) {
        var legend = fieldset.querySelector('legend');
        if (!legend) return;
        /* Strip eyebrow text before comparing */
        var raw  = legend.textContent.replace(/step\s+\d+\s+of\s+\d+/i, '').trim().toLowerCase();
        if (raw.includes('payment') || raw.includes('billing') || raw.includes('credit')) {
          var wrapper = fieldset.querySelector('.fieldset-wrapper');
          if (!wrapper) return;
          var note = document.createElement('div');
          note.className = 'hs-co-secure-note';
          note.innerHTML = ICON_LOCK + ' All transactions are encrypted &amp; secure.';
          wrapper.insertBefore(note, wrapper.firstChild);
        }
      });

      /* ── PLACE ORDER button: dark ink ────────────────────────────────── */
      once('hs-co-place-order',
        '[data-drupal-selector="edit-actions"] input[type="submit"],' +
        ' .checkout-pane-payment > .form-actions input[type="submit"]',
        context
      ).forEach(function (btn) {
        btn.classList.add('hs-co-btn-dark');
      });

      /* ── ORDER SUMMARY SIDEBAR: order_information + payment steps ───────
         Injects a fully-styled order summary card into the secondary region:
         product thumbnails, item names/quantities/prices, coupon code field,
         and subtotal/shipping/total breakdown.

         Data comes from the <script type="application/json" id="hs-cart-data">
         tag embedded by hivesticks_preprocess_page__checkout() — no API calls.

         The coupon Apply button is UI-only for now; wire it up when Commerce
         promotions + Stripe are configured (add the coupon pane to secondary
         region in Commerce admin → Checkout flows → Edit).
         ──────────────────────────────────────────────────────────────────── */
      if (IS_ORDER_INFO || IS_PAYMENT) {
        once('hs-co-sum', '.layout-region-checkout-secondary', context).forEach(function (sidebar) {
          var pageData = getPageCartData();
          if (!pageData) return;

          /* Build item rows */
          var itemsHtml = '';
          (pageData.items || []).forEach(function (item) {
            var thumb = item.image
              ? '<img src="' + escHtml(item.image) + '" alt="" class="hs-co-sum-thumb" loading="lazy">'
              : '<div class="hs-co-sum-thumb hs-co-sum-thumb--emoji" aria-hidden="true">🍯</div>';
            itemsHtml +=
              '<div class="hs-co-sum-item">' +
                thumb +
                '<div class="hs-co-sum-item-info">' +
                  '<div class="hs-co-sum-item-name">' + escHtml(item.title) + '</div>' +
                  '<div class="hs-co-sum-item-qty">Qty ' + item.quantity + '</div>' +
                '</div>' +
                '<div class="hs-co-sum-item-price">' + escHtml(item.total) + '</div>' +
              '</div>';
          });

          var card =
            '<div class="hs-co-sum-card">' +
              '<h2 class="hs-co-sum-heading">Order summary</h2>' +
              itemsHtml +
              '<hr class="hs-co-sum-rule" aria-hidden="true">' +
              /* Coupon code field */
              '<div class="hs-co-sum-coupon">' +
                '<label class="hs-co-sum-coupon-label" for="hs-coupon-input">COUPON CODE</label>' +
                '<div class="hs-co-sum-coupon-row">' +
                  '<input id="hs-coupon-input" class="hs-co-sum-coupon-input" type="text" placeholder="Enter code" autocomplete="off">' +
                  '<button type="button" class="hs-co-sum-coupon-btn">Apply</button>' +
                '</div>' +
                '<p class="hs-co-sum-coupon-hint">Try <strong>HIVE10</strong> for 10% off.</p>' +
              '</div>' +
              '<hr class="hs-co-sum-rule" aria-hidden="true">' +
              /* Price breakdown */
              '<div class="hs-co-sum-totals">' +
                '<div class="hs-co-sum-line"><span>Subtotal</span><span>' + escHtml(pageData.total) + '</span></div>' +
                '<div class="hs-co-sum-line"><span>Shipping</span><span class="hs-co-sum-free">FREE</span></div>' +
                '<div class="hs-co-sum-line hs-co-sum-grand-total"><span>Total</span><span>' + escHtml(pageData.total) + '</span></div>' +
              '</div>' +
            '</div>';

          /* Hide Commerce's default secondary region content (unstyled view output)
             but don't remove it — it may hold hidden form elements needed by Drupal */
          Array.prototype.forEach.call(sidebar.childNodes, function (node) {
            if (node.nodeType === 1 /* ELEMENT_NODE */) {
              node.style.display = 'none';
            }
          });

          /* Inject our card at the top */
          sidebar.insertAdjacentHTML('afterbegin', card);
        });
      }

      /* ── SIDEBAR FOOTER: secure badge + payment chips ────────────────── */
      once('hs-co-sidebar-footer', '.layout-region-checkout-secondary', context).forEach(function (sidebar) {
        var badge = document.createElement('div');
        badge.className = 'hs-co-secure-badge';
        badge.innerHTML = ICON_LOCK + ' Secure checkout · 256-bit encrypted';

        var chips = document.createElement('div');
        chips.className = 'hs-co-pay-chips';
        ['VISA', 'MC', 'AMEX', 'PayPal', 'Pay'].forEach(function (label) {
          var chip = makeEl('span', 'hs-co-pay-chip', label);
          chips.appendChild(chip);
        });

        sidebar.appendChild(badge);
        sidebar.appendChild(chips);
      });

      /* ── COMPLETE PAGE: styled confirmation header ────────────────────── */
      if (IS_COMPLETE) {
        once('hs-co-complete', '.hs-checkout-wrap', context).forEach(function (wrap) {
          /* Build the confirmation card */
          var header = document.createElement('div');
          header.className = 'hs-co-complete-header';
          header.innerHTML =
            '<div class="hs-co-complete-icon">' + ICON_CHECK_LG + '</div>' +
            '<h1 class="hs-co-complete-title">Order placed — thank you!</h1>' +
            '<p class="hs-co-complete-body">A confirmation is on its way to your inbox. We’ll hand-pack your sticks at the Iowa farm and ship them in a compostable mailer within one business day.</p>' +
            '<a href="/shop" class="hs-co-complete-cta">Back to shop</a>';

          /* Hide the Twig-rendered page header (we replace its content) */
          var pageHeader = document.querySelector('.hs-co-page-header');
          if (pageHeader) pageHeader.style.display = 'none';

          /* Prepend our styled header; hide Commerce’s raw output */
          wrap.insertBefore(header, wrap.firstChild);
          Array.prototype.forEach.call(wrap.children, function (child) {
            if (!child.classList.contains('hs-co-complete-header')) {
              child.style.display = 'none';
            }
          });
        });
      }
    }
  };

})(Drupal, once);
