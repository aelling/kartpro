/**
 * @file
 * HiveSticks homepage interactions.
 * Handles: flavor picker, pack picker, qty stepper, subscribe toggle,
 * sticky bar, FAQ accordion, mobile nav.
 */

(function (Drupal, once) {
  'use strict';

  /**
   * Homepage interactive behavior.
   */
  Drupal.behaviors.hiveSticksHomepage = {
    attach: function (context, settings) {

      // ── STATE ──────────────────────────────────────────────────────────
      var state = {
        flavorId:    'wildflower',
        flavorName:  'Wildflower',
        flavorColor: '#f0a929',
        packCount:   30,
        packPrice:   19,
        packPer:     '$0.63/stick',
        subscribe:   false,
        qty:         1,
      };

      // Stick gradient colours keyed by flavor
      var flavorPalette = {
        wildflower: { mid: '#f0a929', deep: '#c8851a' },
        clover:     { mid: '#ffce5c', deep: '#d4a012' },
        buckwheat:  { mid: '#a0631e', deep: '#6a3c0a' },
        orange:     { mid: '#ff9b3a', deep: '#c46a10' },
        lavender:   { mid: '#c89a6a', deep: '#8a6040' },
      };

      // Caption text keyed by pack count
      var packCaptions = {
        12:  'STICKS · 5G EACH · NET WT 60G',
        30:  'STICKS · 5G EACH · NET WT 150G',
        60:  'STICKS · 5G EACH · NET WT 300G',
        120: 'STICKS · 5G EACH · NET WT 600G',
      };

      // ── HELPERS ────────────────────────────────────────────────────────

      function updateCaption() {
        var captionEl = context.querySelector('.hs-js-stage-caption');
        if (captionEl) {
          captionEl.textContent =
            state.flavorName.toUpperCase() + ' · ' +
            state.packCount + ' ' +
            (packCaptions[state.packCount] || 'STICKS');
        }
      }

      function updateFlavorPill() {
        var pill = context.querySelector('.hs-js-stage-flavor-pill');
        if (pill) {
          pill.textContent = 'NEW BATCH · ' + state.flavorName.toUpperCase();
        }
        var label = context.querySelector('.hs-js-flavor-label');
        if (label) {
          label.textContent = 'Flavor — ' + state.flavorName;
        }
      }

      function updateBgNum() {
        var num = context.querySelector('.hs-js-bg-num');
        if (num) {
          num.textContent = state.packCount;
        }
      }

      function updateStickColors() {
        var palette = flavorPalette[state.flavorId] || flavorPalette['wildflower'];
        var sticks  = context.querySelectorAll('.hs-js-stick');
        sticks.forEach(function (svg, idx) {
          var stops = svg.querySelectorAll('stop');
          if (stops.length >= 5) {
            stops[0].setAttribute('stop-color', palette.deep);
            stops[1].setAttribute('stop-color', palette.mid);
            stops[2].setAttribute('stop-color', '#fff3c8');
            stops[3].setAttribute('stop-color', palette.mid);
            stops[4].setAttribute('stop-color', palette.deep);
          }
          // Update end caps
          var ellipses = svg.querySelectorAll('ellipse');
          ellipses.forEach(function (el) {
            el.setAttribute('fill', palette.deep);
          });
        });
      }

      function updatePrice() {
        var priceEl = context.querySelector('.hs-js-price');
        if (!priceEl) return;
        var price = state.packPrice;
        if (state.subscribe) {
          price = Math.round(price * 0.85);
        }
        priceEl.textContent = '$' + (price * state.qty);
      }

      function updateSubscribeDiscount() {
        var discountEl = context.querySelector('.hs-price-discount');
        if (discountEl) {
          discountEl.hidden = !state.subscribe;
        }
      }

      function updateQtyDisplay() {
        var qtyEl = context.querySelector('.hs-js-qty');
        if (qtyEl) {
          qtyEl.textContent = state.qty;
        }
      }

      function syncAll() {
        updateCaption();
        updateFlavorPill();
        updateBgNum();
        updateStickColors();
        updatePrice();
        updateSubscribeDiscount();
        updateQtyDisplay();
      }

      // ── FLAVOR PICKER ─────────────────────────────────────────────────

      once('hs-flavor-pills', '.hs-flavor-pill', context).forEach(function (btn) {
        btn.addEventListener('click', function () {
          context.querySelectorAll('.hs-flavor-pill').forEach(function (b) {
            b.classList.remove('is-active');
            b.setAttribute('aria-pressed', 'false');
          });
          btn.classList.add('is-active');
          btn.setAttribute('aria-pressed', 'true');

          state.flavorId    = btn.dataset.flavorId    || state.flavorId;
          state.flavorName  = btn.dataset.flavorName  || state.flavorName;
          state.flavorColor = btn.dataset.flavorColor || state.flavorColor;
          syncAll();
        });
      });

      // ── PACK PICKER ───────────────────────────────────────────────────

      once('hs-pack-btns', '.hs-pack-btn', context).forEach(function (btn) {
        btn.addEventListener('click', function () {
          context.querySelectorAll('.hs-pack-btn').forEach(function (b) {
            b.classList.remove('is-active');
            b.setAttribute('aria-pressed', 'false');
          });
          btn.classList.add('is-active');
          btn.setAttribute('aria-pressed', 'true');

          state.packCount = parseInt(btn.dataset.packCount, 10) || state.packCount;
          state.packPrice = parseInt(btn.dataset.packPrice, 10) || state.packPrice;
          state.packPer   = btn.dataset.packPer || state.packPer;
          // Reset qty to 1 on pack change
          state.qty = 1;
          syncAll();
        });
      });

      // ── QTY STEPPER ───────────────────────────────────────────────────

      once('hs-qty-btns', '.hs-qty__btn', context).forEach(function (btn) {
        btn.addEventListener('click', function () {
          var dir = btn.dataset.qty;
          if (dir === 'inc') {
            state.qty = Math.min(state.qty + 1, 12);
          } else if (dir === 'dec') {
            state.qty = Math.max(state.qty - 1, 1);
          }
          syncAll();
        });
      });

      // ── SUBSCRIBE TOGGLE ──────────────────────────────────────────────

      once('hs-sub-toggle', '.hs-js-sub-check', context).forEach(function (checkbox) {
        checkbox.addEventListener('change', function () {
          state.subscribe = checkbox.checked;
          syncAll();
        });
      });

      // ── ATC BUTTON ────────────────────────────────────────────────────
      // Update the href with quantity parameter so the product page
      // pre-fills quantity when the user lands there.
      once('hs-atc-btn', '.hs-js-atc-btn', context).forEach(function (btn) {
        btn.addEventListener('click', function (e) {
          var href = btn.getAttribute('href') || '';
          if (href && href !== '#') {
            // Append qty as query param; actual add-to-cart happens on PDP
            if (href.indexOf('?') === -1) {
              btn.setAttribute('href', href + '?qty=' + state.qty);
            }
          }
        });
      });

      // ── STICKY NAV ────────────────────────────────────────────────────

      (function () {
        var nav = context.querySelector('#hs-nav') || document.getElementById('hs-nav');
        if (!nav) return;
        var lastScroll = 0;
        window.addEventListener('scroll', function () {
          var y = window.scrollY;
          if (y > 60) {
            nav.classList.add('is-scrolled');
          } else {
            nav.classList.remove('is-scrolled');
          }
          lastScroll = y;
        }, { passive: true });
      }());

      // ── MOBILE NAV TOGGLE ─────────────────────────────────────────────

      once('hs-mobile-nav', '.hs-nav__mobile-toggle', context).forEach(function (toggle) {
        toggle.addEventListener('click', function () {
          var drawer   = document.getElementById('hs-nav-mobile');
          var expanded = toggle.getAttribute('aria-expanded') === 'true';
          toggle.setAttribute('aria-expanded', String(!expanded));
          if (drawer) {
            drawer.hidden = expanded;
          }
        });
      });

      // Close mobile nav when a link inside it is clicked
      once('hs-mobile-links', '.hs-nav__mobile-drawer a', context).forEach(function (link) {
        link.addEventListener('click', function () {
          var drawer = document.getElementById('hs-nav-mobile');
          var toggle = document.querySelector('.hs-nav__mobile-toggle');
          if (drawer) drawer.hidden = true;
          if (toggle) toggle.setAttribute('aria-expanded', 'false');
        });
      });

      // ── FAQ ACCORDION ─────────────────────────────────────────────────

      once('hs-faq-items', '.hs-faq__item', context).forEach(function (item) {
        var trigger = item.querySelector('.hs-faq__q');
        var body    = item.querySelector('.hs-faq__a');
        if (!trigger || !body) return;

        // Generate a unique ID if one isn't already set
        if (!body.id) {
          body.id = 'hs-faq-' + Math.random().toString(36).slice(2, 8);
        }
        trigger.setAttribute('aria-controls', body.id);
        trigger.setAttribute('aria-expanded', item.classList.contains('is-open') ? 'true' : 'false');
        body.setAttribute('role', 'region');

        trigger.addEventListener('click', function () {
          var isOpen = item.classList.contains('is-open');

          // Close all others
          context.querySelectorAll('.hs-faq__item.is-open').forEach(function (openItem) {
            openItem.classList.remove('is-open');
            var openTrigger = openItem.querySelector('.hs-faq__q');
            var openBody    = openItem.querySelector('.hs-faq__a');
            if (openTrigger) openTrigger.setAttribute('aria-expanded', 'false');
            if (openBody) {
              openBody.style.maxHeight = '';
              openBody.hidden = true;
            }
          });

          if (!isOpen) {
            item.classList.add('is-open');
            trigger.setAttribute('aria-expanded', 'true');
            body.hidden = false;
            body.style.maxHeight = body.scrollHeight + 'px';
          }
        });
      });

      // ── REVIEW FILTER TABS ────────────────────────────────────────────

      once('hs-review-tabs', '.hs-reviews__tab', context).forEach(function (tab) {
        tab.addEventListener('click', function () {
          context.querySelectorAll('.hs-reviews__tab').forEach(function (t) {
            t.classList.remove('is-active');
          });
          tab.classList.add('is-active');
          // Actual filtering would require server-side pagination in a real Drupal site.
          // For the static demo, the tab just updates the visual active state.
        });
      });

      // ── HERO FLAVOR GRID (flavor section scroll-in) ───────────────────
      // On click of "Shop [Flavor]" buttons in the flavor grid, update the
      // stage picker and scroll up to the hero.
      once('hs-flavor-cta', '.hs-flavor-card__cta', context).forEach(function (cta) {
        cta.addEventListener('click', function (e) {
          var card = cta.closest('[data-flavor-id]');
          if (!card) return;
          var id    = card.dataset.flavorId;
          var name  = card.dataset.flavorName;
          var color = card.dataset.flavorColor;
          if (!id) return;

          // Activate the matching flavor pill in the stage
          var pill = context.querySelector('.hs-flavor-pill[data-flavor-id="' + id + '"]');
          if (pill) {
            pill.click();
          }
          // Scroll to hero/shop section
          var hero = document.getElementById('hs-shop');
          if (hero) {
            hero.scrollIntoView({ behavior: 'smooth', block: 'start' });
          }
        });
      });

      // ── ANIMATE STATS ON SCROLL ───────────────────────────────────────
      if ('IntersectionObserver' in window) {
        var statsEl = context.querySelector('.hs-hero__stats');
        if (statsEl) {
          var statObs = new IntersectionObserver(function (entries) {
            entries.forEach(function (entry) {
              if (entry.isIntersecting) {
                entry.target.classList.add('is-visible');
                statObs.unobserve(entry.target);
              }
            });
          }, { threshold: 0.2 });
          statObs.observe(statsEl);
        }

        // Generic fade-in observer for section headings
        context.querySelectorAll('.hs-section-eyebrow, .hs-section-head, .hs-step-card, .hs-flavor-card, .hs-use-card').forEach(function (el) {
          el.classList.add('hs-will-fade');
          var obs = new IntersectionObserver(function (entries) {
            entries.forEach(function (entry) {
              if (entry.isIntersecting) {
                entry.target.classList.add('is-visible');
                obs.unobserve(entry.target);
              }
            });
          }, { threshold: 0.12 });
          obs.observe(el);
        });
      }

      // ── INIT ──────────────────────────────────────────────────────────
      syncAll();

    }
  };

}(Drupal, once));
