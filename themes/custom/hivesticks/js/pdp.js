/**
 * HiveSticks PDP — Drupal behaviors
 *
 * All interactions are wrapped in Drupal.behaviors so they work correctly
 * with Commerce AJAX (add-to-cart, variation updates, BigPipe, etc.).
 *
 * Behaviors in this file:
 *   hsGallery         — thumbnail click → swap main image
 *   hsTabs            — detail tab switching
 *   hsAccordion       — FAQ single-open accordion
 *   hsStickyBar       — scroll-triggered sticky add-to-cart bar
 *   hsFlavorPicker    — build custom flavor swatches, sync → Commerce selects
 *   hsPackPicker      — build custom pack cards, sync → Commerce selects
 *   hsSubscribe       — one-time / subscribe toggle (visual only)
 *   hsStickyBarSync   — keep sticky bar price in sync with active pack
 */

(function (Drupal, drupalSettings, once) {
  'use strict';

  /* ─── Helpers ─────────────────────────────────────────────── */

  /**
   * Find a Commerce attribute select by attribute machine name.
   * Commerce renders selects with name="purchased_entity[0][attributes][attribute_<id>]"
   */
  function findAttrSelect(context, attrId) {
    return context.querySelector(
      `select[name*="attribute_${attrId}"], input[name*="attribute_${attrId}"]`
    );
  }

  /** Trigger Commerce's variation update AJAX after changing a select. */
  function triggerVariationUpdate(selectEl) {
    if (!selectEl) return;
    selectEl.dispatchEvent(new Event('change', { bubbles: true }));
  }

  /* ─── Gallery ─────────────────────────────────────────────── */

  Drupal.behaviors.hsGallery = {
    attach(context) {
      const galleries = once('hs-gallery', '[data-behavior="hs-gallery"]', context);
      galleries.forEach(function (gallery) {
        const thumbs  = gallery.querySelectorAll('.hs-gallery__thumb');
        const slides  = gallery.querySelectorAll('.hs-gallery__slide');
        const navBtns = gallery.querySelectorAll('.hs-gallery__nav-btn');
        let current = 0;

        function goTo(index) {
          if (index < 0) index = slides.length - 1;
          if (index >= slides.length) index = 0;
          current = index;

          thumbs.forEach(function (t, i) { t.classList.toggle('is-active', i === current); });
          slides.forEach(function (s, i) { s.classList.toggle('is-active', i === current); });
        }

        thumbs.forEach(function (thumb, i) {
          thumb.addEventListener('click', function () { goTo(i); });
        });

        navBtns.forEach(function (btn) {
          btn.addEventListener('click', function () {
            goTo(current + parseInt(btn.dataset.dir, 10));
          });
        });
      });
    }
  };

  /* ─── Tabs ─────────────────────────────────────────────────── */

  Drupal.behaviors.hsTabs = {
    attach(context) {
      const sections = once('hs-tabs', '[data-behavior="hs-tabs"]', context);
      sections.forEach(function (section) {
        const tabs   = section.querySelectorAll('.hs-tab');
        const panels = section.querySelectorAll('.hs-tab-panel');

        tabs.forEach(function (tab) {
          tab.addEventListener('click', function () {
            const target = tab.dataset.tab;

            tabs.forEach(function (t) {
              t.classList.toggle('is-active', t === tab);
              t.setAttribute('aria-selected', t === tab ? 'true' : 'false');
            });

            panels.forEach(function (panel) {
              const isActive = panel.dataset.panel === target;
              panel.classList.toggle('is-active', isActive);
              if (isActive) {
                panel.removeAttribute('hidden');
              } else {
                panel.setAttribute('hidden', '');
              }
            });
          });
        });
      });
    }
  };

  /* ─── FAQ Accordion ─────────────────────────────────────────── */

  Drupal.behaviors.hsAccordion = {
    attach(context) {
      const sections = once('hs-accordion', '[data-behavior="hs-accordion"]', context);
      sections.forEach(function (section) {
        const items = section.querySelectorAll('.hs-faq__item');

        items.forEach(function (item) {
          const btn    = item.querySelector('.hs-faq__q');
          const answer = item.querySelector('.hs-faq__a');
          if (!btn || !answer) return;

          btn.addEventListener('click', function () {
            const isOpen = btn.getAttribute('aria-expanded') === 'true';

            // Close all
            items.forEach(function (other) {
              const ob = other.querySelector('.hs-faq__q');
              const oa = other.querySelector('.hs-faq__a');
              if (ob && oa) {
                ob.setAttribute('aria-expanded', 'false');
                oa.setAttribute('hidden', '');
              }
            });

            // Open this one (unless it was already open)
            if (!isOpen) {
              btn.setAttribute('aria-expanded', 'true');
              answer.removeAttribute('hidden');
            }
          });
        });
      });
    }
  };

  /* ─── Sticky Bar ────────────────────────────────────────────── */

  Drupal.behaviors.hsStickyBar = {
    attach(context) {
      const bars = once('hs-sticky-bar', '[data-behavior="hs-sticky-bar"]', context);
      bars.forEach(function (bar) {
        const SHOW_AFTER  = 700;
        const HIDE_BEFORE = 1200; // px from bottom

        function update() {
          const y = window.scrollY;
          const maxY = document.body.scrollHeight - window.innerHeight - HIDE_BEFORE;
          const visible = y > SHOW_AFTER && y < maxY;
          bar.classList.toggle('is-visible', visible);
          bar.setAttribute('aria-hidden', String(!visible));
        }

        window.addEventListener('scroll', update, { passive: true });
        update();

        // Wire sticky bar "Add to cart" to trigger the real Commerce form submit
        const stickyBtn = bar.querySelector('.hs-sticky-bar__btn');
        if (stickyBtn) {
          stickyBtn.addEventListener('click', function () {
            const realBtn = document.querySelector('.hs-commerce-form input[type="submit"], .hs-commerce-form .button--add-to-cart');
            if (realBtn) realBtn.click();
          });
        }
      });
    }
  };

  /* ─── Pack Picker ───────────────────────────────────────────── */

  Drupal.behaviors.hsPackPicker = {
    attach(context) {
      const pickers = once('hs-pack-picker', '[data-behavior="hs-pack-picker"]', context);
      const packs   = (drupalSettings.hivesticks && drupalSettings.hivesticks.packs) || [];
      if (!packs.length) return;

      pickers.forEach(function (picker) {
        const grid       = picker.querySelector('.hs-packs__grid');
        const perStickEl = picker.querySelector('.hs-packs__per-stick');
        const attrSelect = findAttrSelect(document, 'pack_size');

        if (!grid) return;

        function selectPack(pack, btn) {
          // Update visual
          grid.querySelectorAll('.hs-pack-opt').forEach(function (b) { b.classList.remove('is-active'); });
          btn.classList.add('is-active');

          // Update per-stick label
          if (perStickEl && pack.per_stick) {
            perStickEl.textContent = `$${parseFloat(pack.per_stick).toFixed(2)} per stick`;
          }

          // Update subscribe toggle prices
          updateSubscribePrices(pack.price);

          // Update sticky bar
          updateStickyBar(pack);

          // Sync Commerce
          if (attrSelect) {
            const option = Array.from(attrSelect.options || []).find(function (o) {
              return o.text.trim().toLowerCase() === String(pack.count).toLowerCase();
            });
            if (option) {
              attrSelect.value = option.value;
              triggerVariationUpdate(attrSelect);
            }
          }
        }

        packs.forEach(function (pack, i) {
          const btn = document.createElement('button');
          btn.type = 'button';
          btn.className = 'hs-pack-opt' + (pack.is_popular ? '' : '') + (i === 1 ? ' is-active' : '');
          btn.dataset.id = pack.id;

          let badgeHtml = '';
          if (pack.is_popular) {
            badgeHtml = `<span class="hs-badge hs-badge--popular">POPULAR</span>`;
          } else if (pack.save_label) {
            badgeHtml = `<span class="hs-badge hs-badge--save">${pack.save_label}</span>`;
          }

          btn.innerHTML = `
            ${badgeHtml}
            <div class="hs-pack-opt__top">
              <span class="hs-pack-opt__count">${pack.count}</span>
              <span class="hs-pack-opt__price">$${parseFloat(pack.price).toFixed(2)}</span>
            </div>
            <div class="hs-pack-opt__meta">${pack.label} · ${pack.note}</div>
          `;

          btn.addEventListener('click', function () { selectPack(pack, btn); });
          grid.appendChild(btn);
        });

        // Set default (popular / second pack) — must call selectPack() so Commerce
        // has a variation pre-selected before the user clicks Add to Cart.
        const defaultPack = packs.find(function (p) { return p.is_popular; }) || packs[1] || packs[0];
        if (defaultPack) {
          const defaultBtn = grid.querySelector('[data-id="' + defaultPack.id + '"]');
          if (defaultBtn) {
            selectPack(defaultPack, defaultBtn);
          } else {
            // Fallback: update UI helpers without Commerce sync
            if (perStickEl && defaultPack.per_stick) {
              perStickEl.textContent = '$' + parseFloat(defaultPack.per_stick).toFixed(2) + ' per stick';
            }
            updateSubscribePrices(defaultPack.price);
            updateStickyBar(defaultPack);
          }
        }
      });
    }
  };

  /* ─── Subscribe Toggle ──────────────────────────────────────── */

  Drupal.behaviors.hsSubscribe = {
    attach(context) {
      const toggles = once('hs-subscribe', '[data-behavior="hs-subscribe"]', context);
      toggles.forEach(function (toggle) {
        const opts = toggle.querySelectorAll('.hs-subscribe__opt');

        // Sync the hidden add-to-cart flag (added by the hs_subscribe module).
        function setSubscribeFlag(on) {
          document.querySelectorAll(
            'form[id*="commerce-order-item-add-to-cart"] input.hs-subscribe-flag, ' +
            'form[id*="commerce-order-item-add-to-cart"] input[name="hs_subscribe"]'
          ).forEach(function (input) { input.value = on ? '1' : '0'; });
        }

        opts.forEach(function (opt) {
          opt.addEventListener('click', function () {
            opts.forEach(function (o) { o.classList.remove('is-active'); });
            opt.classList.add('is-active');
            setSubscribeFlag(opt.getAttribute('data-type') === 'subscribe');
          });
        });

        // Initialise from whichever option is active on load.
        var active = toggle.querySelector('.hs-subscribe__opt.is-active');
        setSubscribeFlag(active && active.getAttribute('data-type') === 'subscribe');
      });
    }
  };

  /* ─── Sync subscribe toggle prices when pack changes ──────── */

  function updateSubscribePrices(basePrice) {
    const subscribe = document.querySelector('[data-behavior="hs-subscribe"]');
    if (!subscribe) return;
    const oncePrice = subscribe.querySelector('[data-type="one-time"] .hs-subscribe__opt-price');
    const subPrice  = subscribe.querySelector('[data-type="subscribe"] .hs-subscribe__opt-price--sub');
    if (oncePrice) oncePrice.textContent = `$${parseFloat(basePrice).toFixed(2)}`;
    if (subPrice)  subPrice.textContent  = `$${(parseFloat(basePrice) * 0.85).toFixed(2)} / month`;
  }

  /* ─── Sync sticky bar when pack/flavor changes ───────────── */

  function updateStickyBar(pack) {
    const bar = document.querySelector('[data-behavior="hs-sticky-bar"]');
    if (!bar) return;
    const metaEl  = bar.querySelector('.hs-sticky-bar__meta');
    const priceEl = bar.querySelector('.hs-sticky-bar__price');

    // Get active flavor name
    const activeFlavor = document.querySelector('.hs-flavor-opt.is-active .hs-flavor-opt__name');
    const flavorName = activeFlavor ? activeFlavor.textContent.trim() : '';

    if (metaEl && pack) {
      metaEl.textContent = [flavorName, `${pack.count} ct`].filter(Boolean).join(' · ');
    }
    if (priceEl && pack) {
      priceEl.textContent = `$${parseFloat(pack.price).toFixed(2)}`;
    }
  }

  /* ─── Commerce Form: hide attributes, keep qty + submit ───── */

  Drupal.behaviors.hsCommerceForm = {
    attach(context) {
      once('hs-commerce-form', '[data-behavior="hs-commerce-form"]', context).forEach(function (form) {
        // Hide the default attribute selectors (our custom pickers handle this)
        const attrWrapper = form.querySelector('.field--name-variation-attributes');
        if (attrWrapper) attrWrapper.style.display = 'none';

        // Hide the "Variations" label. Drupal can render it as <label>,
        // <h4 class="label">, <div class="field__label">, <legend>,
        // or <span class="fieldset-legend"> — cover them all, then do a
        // text-node scan as a last resort.
        const purchasedField = form.querySelector('.field--name-purchased-entity');
        if (purchasedField) {
          [
            'legend', 'label', '.label', '.field__label',
            '.fieldset-legend', '.form-item__label'
          ].forEach(function (sel) {
            purchasedField.querySelectorAll(sel).forEach(function (el) {
              el.style.setProperty('display', 'none', 'important');
            });
          });
          // Last-resort: hide any leaf element whose text is exactly "Variations"
          purchasedField.querySelectorAll('*').forEach(function (el) {
            if (el.children.length === 0 && el.textContent.trim() === 'Variations') {
              el.style.setProperty('display', 'none', 'important');
            }
          });
        }
        // Widen the scan to the whole form wrapper in case the label
        // is rendered outside .field--name-purchased-entity
        form.querySelectorAll('*').forEach(function (el) {
          if (el.children.length === 0 && el.textContent.trim() === 'Variations') {
            el.style.setProperty('display', 'none', 'important');
          }
        });

        // Watch Commerce AJAX events to keep our UI in sync after a variation change
        // Commerce dispatches 'commerce:variationChange' on the form
        form.addEventListener('commerce:variationChange', function (e) {
          if (e.detail && e.detail.variation && e.detail.variation.price) {
            const price = e.detail.variation.price.number;
            updateStickyBar({ price: price, count: '' });
            updateSubscribePrices(price);
          }
        });
      });
    }
  };

})(Drupal, drupalSettings, once);
