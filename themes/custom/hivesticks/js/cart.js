/**
 * HiveSticks Cart — Drupal behaviors
 *
 * Behaviors:
 *   hsCartLineItems — injects product thumbnail + qty stepper into each row.
 *   hsShipBar       — free-shipping progress bar.
 *   hsCartRows      — re-runs everything after Commerce AJAX updates.
 */

(function (Drupal, once) {
  'use strict';

  /* ─── Flavor → swatch map ──────────────────────────────────────────────── */
  // Matches product title keywords (case-insensitive) to a brand swatch color.
  var SWATCH_MAP = [
    [/wildflower/i,  '#f0a929'],
    [/clover/i,      '#f7c948'],
    [/cinnamon/i,    '#c47a3a'],
    [/lemon/i,       '#f5e04b'],
    [/lavender/i,    '#b48dd4'],
    [/raspberry/i,   '#e05070'],
    [/blueberry/i,   '#6b7fd4'],
    [/orange/i,      '#f07830'],
    [/mint/i,        '#5db88a'],
    [/peach/i,       '#f09070'],
    [/strawberry/i,  '#e86080'],
    [/mango/i,       '#f5a623'],
    [/grape/i,       '#9b59b6'],
    [/coconut/i,     '#e8d5a3'],
    [/vanilla/i,     '#f3e0a0'],
    [/cherry/i,      '#c0392b'],
    [/watermelon/i,  '#e74c6c'],
    [/apple/i,       '#a8cc5c'],
  ];

  var SWATCH_DEFAULT = '#f0a929';

  function swatchForName(name) {
    if (!name) return SWATCH_DEFAULT;
    for (var i = 0; i < SWATCH_MAP.length; i++) {
      if (SWATCH_MAP[i][0].test(name)) return SWATCH_MAP[i][1];
    }
    return SWATCH_DEFAULT;
  }

  /* ─── Honey stick SVG thumbnail ────────────────────────────────────────── */
  // Simple stylized honey-stick illustration; fill color set per swatch.

  function honeySVG(color) {
    return (
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="52" height="52" aria-hidden="true">' +
      '<rect x="22" y="6" width="20" height="46" rx="8" fill="' + color + '" opacity="0.9"/>' +
      '<rect x="22" y="6" width="20" height="12" rx="8" fill="' + color + '"/>' +
      '<rect x="26" y="10" width="12" height="4" rx="2" fill="rgba(255,255,255,0.45)"/>' +
      '<rect x="22" y="46" width="20" height="6" rx="4" fill="rgba(0,0,0,0.12)"/>' +
      '</svg>'
    );
  }

  /* ─── Inject thumbnails ─────────────────────────────────────────────────── */
  // Always searches document — Drupal may pass a child element as context
  // (e.g. after AJAX), which would miss .hs-cart-rows as an ancestor.

  function injectThumbs() {
    var rows = document.querySelectorAll('.hs-cart-rows tbody tr');
    rows.forEach(function (row) {
      // Skip if already injected
      if (row.querySelector('.hs-line-thumb')) return;

      // Get product name from the purchased-entity cell
      var nameCell = row.querySelector('.views-field-purchased-entity');
      var name = nameCell ? nameCell.textContent.trim() : '';
      var color = swatchForName(name);

      var thumb = document.createElement('div');
      thumb.className = 'hs-line-thumb';
      thumb.style.setProperty('--hs-thumb-swatch', color);
      thumb.innerHTML = honeySVG(color);

      // Insert as first child so CSS grid column 1 picks it up
      row.insertBefore(thumb, row.firstChild);
    });
  }

  /* ─── Inject qty steppers ──────────────────────────────────────────────── */
  // Commerce renders the qty inputs OUTSIDE the views-field td (at the form
  // level), named edit_quantity[0], edit_quantity[1], … matching row order.
  // We inject the stepper UI into the td and drive the out-of-band input.

  function injectSteppers() {
    var rows = document.querySelectorAll('.hs-cart-rows tbody tr');
    rows.forEach(function (row, rowIndex) {
      var field = row.querySelector('.views-field-edit-quantity');
      if (!field) return;
      if (field.querySelector('.hs-qty-stepper')) return;

      // Find the Commerce-rendered qty input by row index (anywhere in form)
      var input = document.querySelector('input[name="edit_quantity[' + rowIndex + ']"]');
      if (!input) return;

      var val = parseInt(input.value, 10) || 1;

      // Build stepper
      var stepper = document.createElement('div');
      stepper.className = 'hs-qty-stepper';
      stepper.setAttribute('aria-label', Drupal.t('Quantity'));

      var btnMinus = document.createElement('button');
      btnMinus.type = 'button';
      btnMinus.className = 'hs-qty-stepper__btn hs-qty-stepper__btn--minus';
      btnMinus.setAttribute('aria-label', Drupal.t('Decrease quantity'));
      btnMinus.textContent = '−';

      var display = document.createElement('span');
      display.className = 'hs-qty-stepper__val';
      display.setAttribute('aria-live', 'polite');
      display.textContent = val;

      var btnPlus = document.createElement('button');
      btnPlus.type = 'button';
      btnPlus.className = 'hs-qty-stepper__btn hs-qty-stepper__btn--plus';
      btnPlus.setAttribute('aria-label', Drupal.t('Increase quantity'));
      btnPlus.textContent = '+';

      stepper.appendChild(btnMinus);
      stepper.appendChild(display);
      stepper.appendChild(btnPlus);

      // Append stepper into the qty td (the real input lives outside the td)
      field.appendChild(stepper);

      /* ── Stepper click handlers ── */
      btnMinus.addEventListener('click', function () {
        var current = parseInt(input.value, 10) || 1;
        if (current <= 1) return;
        var next = current - 1;
        input.value = next;
        display.textContent = next;
        triggerUpdate(input);
      });

      btnPlus.addEventListener('click', function () {
        var current = parseInt(input.value, 10) || 1;
        var next = current + 1;
        input.value = next;
        display.textContent = next;
        triggerUpdate(input);
      });
    });
  }

  /**
   * Trigger a Commerce cart update.
   * Commerce listens for `change` on qty inputs and submits via AJAX.
   */
  function triggerUpdate(input) {
    // Dispatch native change so Drupal's AJAX binding picks it up
    var ev = new Event('change', { bubbles: true });
    input.dispatchEvent(ev);

    // Also try to find and click the hidden "Update cart" button Commerce
    // sometimes uses as the AJAX submit target (depends on Commerce version).
    var form = input.closest('form');
    if (form) {
      var updateBtn = form.querySelector('[name="op"][value*="Update"], .button--update-cart, input[value*="Update"]');
      if (updateBtn) {
        updateBtn.click();
      }
    }
  }

  /* ─── Helpers ──────────────────────────────────────────────────────────── */

  function parsePrice(str) {
    if (!str) return 0;
    return parseFloat(String(str).replace(/[^0-9.]/g, '')) || 0;
  }

  function readSubtotal() {
    var subtotalRow = document.querySelector('.hs-totals__row--subtotal .hs-totals__value');
    if (subtotalRow) return parsePrice(subtotalRow.textContent);

    var rows = document.querySelectorAll('.hs-totals__row');
    for (var i = 0; i < rows.length; i++) {
      var label = rows[i].querySelector('.hs-totals__label');
      if (label && /subtotal/i.test(label.textContent)) {
        var val = rows[i].querySelector('.hs-totals__value');
        if (val) return parsePrice(val.textContent);
      }
    }

    var commerceTotal = document.querySelector('.order-total-line__subtotal .order-total-line-value');
    if (commerceTotal) return parsePrice(commerceTotal.textContent);

    return 0;
  }

  function updateShipBar(bar, subtotal) {
    var threshold = parseFloat(bar.dataset.threshold) || 25;
    var fill  = bar.querySelector('.hs-shipbar__fill');
    var label = bar.querySelector('.hs-shipbar__label');
    if (!fill || !label) return;

    var pct = Math.max(0, Math.min(100, (subtotal / threshold) * 100));
    fill.style.width = pct + '%';

    if (subtotal >= threshold) {
      label.innerHTML = '<strong>' + Drupal.t('Free shipping unlocked.') + '</strong> ' + Drupal.t('Sweet.');
      label.classList.add('hs-shipbar__label--unlocked');
      bar.setAttribute('aria-label', Drupal.t('Free shipping unlocked'));
    } else {
      var remaining = (threshold - subtotal).toFixed(2);
      label.innerHTML = Drupal.t(
        "You're <strong>$@amount</strong> away from free shipping.",
        { '@amount': remaining }
      );
      label.classList.remove('hs-shipbar__label--unlocked');
      bar.setAttribute('aria-label', Drupal.t('$@amount away from free shipping', { '@amount': remaining }));
    }
  }

  /* ─── hsCartLineItems ──────────────────────────────────────────────────── */
  // Runs on initial attach and after every Commerce AJAX re-render.
  // Uses `once()` on the rows wrapper so we don't double-attach listeners,
  // but injectThumbs/injectSteppers check for existing elements so they're
  // safe to call multiple times (idempotent).

  Drupal.behaviors.hsCartLineItems = {
    attach: function (context) {
      injectThumbs();
      injectSteppers();

      // Commerce's cart form JS rebuilds the DOM shortly after page load,
      // wiping any elements we just injected. Re-run once after 350ms to
      // catch that rebuild. `once` ensures we only schedule it on the first
      // attach (the initial full-page load).
      once('hs-cart-delayed-inject', 'body', context).forEach(function () {
        setTimeout(function () {
          injectThumbs();
          injectSteppers();
        }, 350);
      });
    }
  };

  /* ─── hsOrderTotals ────────────────────────────────────────────────────── */
  // Commerce appends the rendered order total summary OUTSIDE our sidebar
  // (after the views template output rather than through {{ footer }}).
  // Move .hs-totals into .hs-summary-totals so it appears in the sidebar.

  function moveOrderTotals() {
    var totals = document.querySelector('.hs-totals[data-behavior="hs-totals"]');
    var target = document.querySelector('.hs-summary-totals');
    if (!totals || !target) return;
    if (target.contains(totals)) return; // already in place
    target.appendChild(totals);
  }

  Drupal.behaviors.hsOrderTotals = {
    attach: function (context) {
      once('hs-order-totals', 'body', context).forEach(function () {
        moveOrderTotals();
      });
    }
  };

  /* ─── hsShipBar ────────────────────────────────────────────────────────── */

  Drupal.behaviors.hsShipBar = {
    attach: function (context) {
      once('hs-shipbar', '[data-behavior="hs-shipbar"]', context).forEach(function (bar) {
        moveOrderTotals(); // ensure totals are in place before reading
        updateShipBar(bar, readSubtotal());
      });
    }
  };

  /* ─── hsCartRows ───────────────────────────────────────────────────────── */
  // Re-runs line-item injection + ship bar after Commerce AJAX.

  Drupal.behaviors.hsCartRows = {
    attach: function (context) {
      once('hs-cart-rows', '[data-behavior="hs-cart-rows"]', context).forEach(function (rows) {
        document.addEventListener('ajax:success', function () {
          injectThumbs();
          injectSteppers();

          var bar = document.querySelector('[data-behavior="hs-shipbar"]');
          if (!bar) return;
          setTimeout(function () {
            updateShipBar(bar, readSubtotal());
          }, 80);
        });
      });
    }
  };

})(Drupal, once);
