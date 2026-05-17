/**
 * @file
 * HiveSticks — Product Detail Page interactivity.
 *
 * Handles:
 *  1. Gallery thumbnail / panel switching
 *  2. Flavor picker (visual + syncs to Commerce variation select)
 *  3. Pack size picker (visual + syncs to Commerce variation select)
 *  4. Subscribe / one-time toggle
 *  5. Quantity stepper (visual + syncs to Commerce qty input)
 *  6. ATC button — delegates to hidden Commerce form submit
 *  7. Price display updates
 *  8. Sticky add-to-cart bar (show after buy column scrolls off)
 *  9. Tabbed details (Details / Ingredients / Nutrition / Shipping)
 * 10. FAQ accordion
 * 11. Review flavor filter
 */

(function (Drupal) {
  'use strict';

  // ── State ────────────────────────────────────────────────────────────
  var state = {
    flavorName: 'Wildflower',
    packCount:  30,
    packPrice:  20,
    packPer:    0.67,
    subscribe:  false,
    qty:        1,
  };

  function getDisplayPrice() {
    var base = state.packPrice * state.qty;
    return state.subscribe ? base * 0.85 : base;
  }

  function fmt(n) { return n.toFixed(2); }

  // ── Price display sync ───────────────────────────────────────────────
  function syncPrices() {
    var price = getDisplayPrice();
    var perStick = (state.packPrice / state.packCount).toFixed(2);

    // ATC button price
    document.querySelectorAll('.hs-js-atc-price').forEach(function (el) { el.textContent = fmt(price); });

    // One-time price in subscribe toggle
    document.querySelectorAll('.hs-js-onetime-price').forEach(function (el) {
      el.textContent = fmt(state.packPrice * state.qty);
    });
    // Subscribe price
    document.querySelectorAll('.hs-js-sub-price').forEach(function (el) {
      el.textContent = fmt(state.packPrice * state.qty * 0.85);
    });

    // Per-stick label
    document.querySelectorAll('.hs-pdp__per-stick').forEach(function (el) {
      el.setAttribute('data-per', perStick);
      el.textContent = '$' + perStick + ' per stick';
    });

    // Sticky bar prices and info
    document.querySelectorAll('.hs-js-sticky-price').forEach(function (el) { el.textContent = fmt(price); });
    document.querySelectorAll('.hs-js-sticky-flavor').forEach(function (el) { el.textContent = state.flavorName; });
    document.querySelectorAll('.hs-js-sticky-pack').forEach(function (el) { el.textContent = state.packCount + ' ct'; });
    document.querySelectorAll('.hs-js-sticky-qty').forEach(function (el) { el.textContent = state.qty; });
  }

  // ── Commerce form sync ───────────────────────────────────────────────
  // Attempts to keep the hidden Commerce form in sync so clicking the
  // styled ATC button actually adds the right product/variation to cart.

  function syncCommerceVariation() {
    // Try to find and update the variation select (if multiple variations exist)
    var selects = document.querySelectorAll(
      '.hs-pdp__commerce-form select[name*="variation"], ' +
      '.hs-pdp__commerce-form select[id*="variation"]'
    );
    if (!selects.length) return;

    selects.forEach(function (sel) {
      var options = sel.options;
      for (var i = 0; i < options.length; i++) {
        var text = options[i].textContent.toLowerCase();
        // Match pack size by count
        if (text.indexOf(String(state.packCount)) !== -1 ||
            text.indexOf(state.flavorName.toLowerCase()) !== -1) {
          sel.selectedIndex = i;
          // Trigger change so Drupal Commerce re-calculates price
          sel.dispatchEvent(new Event('change', { bubbles: true }));
          break;
        }
      }
    });
  }

  function syncCommerceQty() {
    var qtyInputs = document.querySelectorAll(
      '.hs-pdp__commerce-form input[type="number"][name*="quantity"], ' +
      '.hs-pdp__commerce-form input[type="number"][id*="qty"]'
    );
    qtyInputs.forEach(function (inp) {
      inp.value = state.qty;
      inp.dispatchEvent(new Event('change', { bubbles: true }));
    });
  }

  // ── Gallery ──────────────────────────────────────────────────────────
  function initGallery(context) {
    var thumbs  = context.querySelectorAll('.hs-pdp__thumb');
    var panels  = context.querySelectorAll('.hs-pdp__gallery-panel');
    var prevBtn = context.querySelector('.hs-pdp__gallery-prev');
    var nextBtn = context.querySelector('.hs-pdp__gallery-next');
    var counter = context.querySelector('.hs-pdp__hero-counter');
    var views   = [];

    thumbs.forEach(function (btn) { views.push(btn.getAttribute('data-gallery-view')); });

    var currentIdx = 0;

    function activate(idx) {
      currentIdx = (idx + views.length) % views.length;
      var targetView = views[currentIdx];

      thumbs.forEach(function (btn, i) {
        btn.classList.toggle('is-active', i === currentIdx);
      });
      panels.forEach(function (panel) {
        panel.classList.toggle('is-active', panel.getAttribute('data-panel') === targetView);
      });
      if (counter) {
        var padded = String(currentIdx + 1).padStart(2, '0');
        var total  = String(views.length).padStart(2, '0');
        var flavorLabel = context.querySelector('.hs-pdp__hero-flavor-label');
        var flavor = flavorLabel ? flavorLabel.textContent : '';
        counter.textContent = padded + ' / ' + total + (flavor ? ' — ' + flavor : '');
      }
    }

    thumbs.forEach(function (btn, i) {
      btn.addEventListener('click', function () { activate(i); });
    });
    if (prevBtn) prevBtn.addEventListener('click', function () { activate(currentIdx - 1); });
    if (nextBtn) nextBtn.addEventListener('click', function () { activate(currentIdx + 1); });
  }

  // ── Flavor picker ────────────────────────────────────────────────────
  function initFlavorPicker(context) {
    var btns       = context.querySelectorAll('.hs-pdp__flavor-btn');
    var nameEl     = context.querySelector('.hs-pdp__selected-flavor-name');
    var notesEl    = context.querySelector('.hs-pdp__selected-flavor-notes');
    var flavorLbl  = context.querySelector('.hs-pdp__hero-flavor-label');

    btns.forEach(function (btn) {
      btn.addEventListener('click', function () {
        btns.forEach(function (b) {
          b.classList.remove('is-selected');
          b.setAttribute('aria-pressed', 'false');
        });
        btn.classList.add('is-selected');
        btn.setAttribute('aria-pressed', 'true');

        state.flavorName = btn.getAttribute('data-flavor-name');
        var notes = btn.getAttribute('data-flavor-notes');

        if (nameEl)    nameEl.textContent  = state.flavorName;
        if (notesEl)   notesEl.textContent = notes;
        if (flavorLbl) flavorLbl.textContent = state.flavorName.toUpperCase();

        syncCommerceVariation();
        syncPrices();
      });
    });
  }

  // ── Pack picker ──────────────────────────────────────────────────────
  function initPackPicker(context) {
    var btns = context.querySelectorAll('.hs-pdp__pack-btn');

    btns.forEach(function (btn) {
      btn.addEventListener('click', function () {
        btns.forEach(function (b) {
          b.classList.remove('is-selected');
          b.setAttribute('aria-pressed', 'false');
        });
        btn.classList.add('is-selected');
        btn.setAttribute('aria-pressed', 'true');

        state.packCount = parseInt(btn.getAttribute('data-pack-count'), 10);
        state.packPrice = parseFloat(btn.getAttribute('data-pack-price'));
        state.packPer   = parseFloat(btn.getAttribute('data-pack-per'));

        syncCommerceVariation();
        syncPrices();
      });
    });
  }

  // ── Subscribe toggle ─────────────────────────────────────────────────
  function initSubscribeToggle(context) {
    var btns = context.querySelectorAll('.hs-pdp__sub-btn');

    btns.forEach(function (btn) {
      btn.addEventListener('click', function () {
        btns.forEach(function (b) {
          b.classList.remove('is-selected');
          b.setAttribute('aria-pressed', 'false');
        });
        btn.classList.add('is-selected');
        btn.setAttribute('aria-pressed', 'true');

        state.subscribe = btn.getAttribute('data-sub') === 'subscribe';
        syncPrices();
      });
    });
  }

  // ── Qty stepper ──────────────────────────────────────────────────────
  function initQtyStepper(context) {
    var decBtns = context.querySelectorAll('.hs-pdp__qty-btn[data-qty="dec"]');
    var incBtns = context.querySelectorAll('.hs-pdp__qty-btn[data-qty="inc"]');
    var vals    = context.querySelectorAll('.hs-pdp__qty-val');

    function updateQty() {
      vals.forEach(function (el) { el.textContent = state.qty; });
      syncCommerceQty();
      syncPrices();
    }

    decBtns.forEach(function (btn) {
      btn.addEventListener('click', function () {
        if (state.qty > 1) { state.qty--; updateQty(); }
      });
    });
    incBtns.forEach(function (btn) {
      btn.addEventListener('click', function () {
        state.qty++;
        updateQty();
      });
    });
  }

  // ── ATC button ───────────────────────────────────────────────────────
  function initATCButton(context) {
    var atcBtns = context.querySelectorAll('#hs-pdp-atc-trigger, #hs-pdp-sticky-atc');

    atcBtns.forEach(function (btn) {
      btn.addEventListener('click', function () {
        // Sync state to Commerce form
        syncCommerceVariation();
        syncCommerceQty();

        // Submit the hidden Commerce form
        var form = context.querySelector('.hs-pdp__commerce-form form');
        if (!form) {
          form = document.querySelector('.commerce-order-item-add-to-cart-form');
        }
        if (form) {
          var submit = form.querySelector('[type="submit"], .button--add-to-cart');
          if (submit) { submit.click(); }
          else { form.submit(); }
        }
      });
    });
  }

  // ── Sticky bar visibility ────────────────────────────────────────────
  function initStickyBar(context) {
    var bar     = document.getElementById('hs-pdp-sticky-bar');
    var buyCol  = context.querySelector('.hs-pdp__buy');
    if (!bar || !buyCol) return;

    var shown = false;
    var ticking = false;

    function check() {
      var rect = buyCol.getBoundingClientRect();
      // Show bar when the bottom of the buy column scrolls above the viewport
      var shouldShow = rect.bottom < 0;
      if (shouldShow !== shown) {
        shown = shouldShow;
        bar.classList.toggle('is-visible', shown);
        bar.setAttribute('aria-hidden', String(!shown));
      }
      ticking = false;
    }

    window.addEventListener('scroll', function () {
      if (!ticking) {
        requestAnimationFrame(check);
        ticking = true;
      }
    }, { passive: true });

    check();
  }

  // ── Tabs ─────────────────────────────────────────────────────────────
  function initTabs(context) {
    var tabs   = context.querySelectorAll('.hs-pdp__tab');
    var panels = context.querySelectorAll('.hs-pdp__tab-panel');

    tabs.forEach(function (tab) {
      tab.addEventListener('click', function () {
        var targetId = tab.getAttribute('data-tab');

        tabs.forEach(function (t) {
          t.classList.remove('is-active');
          t.setAttribute('aria-selected', 'false');
        });
        panels.forEach(function (p) {
          p.classList.remove('is-active');
          p.hidden = true;
        });

        tab.classList.add('is-active');
        tab.setAttribute('aria-selected', 'true');

        var panel = context.getElementById('hs-tab-' + targetId) ||
                    document.getElementById('hs-tab-' + targetId);
        if (panel) {
          panel.classList.add('is-active');
          panel.hidden = false;
        }
      });
    });
  }

  // ── FAQ accordion ────────────────────────────────────────────────────
  function initFAQ(context) {
    var items = context.querySelectorAll('.hs-pdp__faq-item');

    items.forEach(function (item, i) {
      var btn    = item.querySelector('.hs-pdp__faq-q');
      var answer = item.querySelector('.hs-pdp__faq-a');
      if (!btn || !answer) return;

      btn.addEventListener('click', function () {
        var isOpen = item.classList.contains('is-open');

        // Close all
        items.forEach(function (it) {
          it.classList.remove('is-open');
          var a = it.querySelector('.hs-pdp__faq-a');
          var b = it.querySelector('.hs-pdp__faq-q');
          if (a) a.hidden = true;
          if (b) b.setAttribute('aria-expanded', 'false');
        });

        // Open clicked (unless it was already open → toggle closed)
        if (!isOpen) {
          item.classList.add('is-open');
          answer.hidden = false;
          btn.setAttribute('aria-expanded', 'true');
        }
      });
    });
  }

  // ── Review flavor filter ─────────────────────────────────────────────
  function initReviewFilter(context) {
    var filterBtns = context.querySelectorAll('.hs-pdp__filter-btn');
    var reviews    = context.querySelectorAll('.hs-pdp__review');

    filterBtns.forEach(function (btn) {
      btn.addEventListener('click', function () {
        filterBtns.forEach(function (b) {
          b.classList.remove('is-active');
          b.setAttribute('aria-pressed', 'false');
        });
        btn.classList.add('is-active');
        btn.setAttribute('aria-pressed', 'true');

        var filter = btn.getAttribute('data-filter');
        reviews.forEach(function (r) {
          if (filter === 'all') {
            r.hidden = false;
          } else {
            var flavor = r.getAttribute('data-review-flavor') || '';
            r.hidden = flavor.indexOf(filter) === -1;
          }
        });
      });
    });
  }

  // ── Drupal behavior ──────────────────────────────────────────────────
  Drupal.behaviors.hiveStickspdp = {
    attach: function (context, settings) {
      var pdpEl = context.querySelector('.hs-pdp') || context.closest('.hs-pdp');
      if (!pdpEl) return;

      // Guard against re-attaching
      if (pdpEl.dataset.pdpInit) return;
      pdpEl.dataset.pdpInit = '1';

      // Override context.getElementById for panels in twig
      // (querySelector searches the subtree; getElementById searches document)
      var origGetById = context.getElementById ? context.getElementById.bind(context) : null;
      pdpEl.getElementById = function (id) { return document.getElementById(id); };

      initGallery(pdpEl);
      initFlavorPicker(pdpEl);
      initPackPicker(pdpEl);
      initSubscribeToggle(pdpEl);
      initQtyStepper(pdpEl);
      initATCButton(pdpEl);
      initStickyBar(pdpEl);
      initTabs(pdpEl);
      initFAQ(pdpEl);
      initReviewFilter(pdpEl);

      // Initial price display
      syncPrices();
    }
  };

}(Drupal));
