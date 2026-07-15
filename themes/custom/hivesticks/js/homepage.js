/**
 * HiveSticks Homepage — Drupal behaviors  v2
 *
 * Behaviors:
 *   hsHomeNav       — sticky nav: adds .is-scrolled on scroll
 *   hsHomeFaq       — FAQ accordion (aria-expanded / hidden pattern)
 *   hsHomeMarquee   — pauses marquee on hover/focus
 *   hsHomePackPicker — hero pack size buttons: update price/per display
 *   hsStickyBar     — fixed buy bar: slides up after scrolling past hero
 *   hsHomeCartIcon  — reads Commerce cart count into nav badge
 *   hsHomeSmoothScroll — smooth anchor scrolling
 */

(function (Drupal, once) {
  'use strict';

  /* ─── Sticky Nav ─────────────────────────────────────────────── */

  Drupal.behaviors.hsHomeNav = {
    attach(context) {
      const navs = once('hs-home-nav', '[data-behavior="hs-sticky-nav"]', context);
      navs.forEach(function (nav) {
        const THRESHOLD = 60;
        function update() {
          nav.classList.toggle('is-scrolled', window.scrollY > THRESHOLD);
        }
        window.addEventListener('scroll', update, { passive: true });
        update();
      });
    }
  };

  /* ─── Homepage FAQ Accordion ─────────────────────────────────── */

  Drupal.behaviors.hsHomeFaq = {
    attach(context) {
      const sections = once('hs-home-faq', '[data-behavior="hs-home-faq"]', context);
      sections.forEach(function (section) {
        const items = section.querySelectorAll('.hs-faq-home__item');

        items.forEach(function (item) {
          const btn    = item.querySelector('.hs-faq-home__q');
          const answer = item.querySelector('.hs-faq-home__a');
          if (!btn || !answer) return;

          // Ensure correct initial ARIA state
          if (btn.getAttribute('aria-expanded') !== 'true') {
            answer.setAttribute('hidden', '');
          }

          btn.addEventListener('click', function () {
            const isOpen = btn.getAttribute('aria-expanded') === 'true';

            // Close all items in this section
            items.forEach(function (other) {
              const ob = other.querySelector('.hs-faq-home__q');
              const oa = other.querySelector('.hs-faq-home__a');
              if (ob && oa) {
                ob.setAttribute('aria-expanded', 'false');
                oa.setAttribute('hidden', '');
              }
            });

            // Open clicked item (unless it was already open)
            if (!isOpen) {
              btn.setAttribute('aria-expanded', 'true');
              answer.removeAttribute('hidden');
            }
          });
        });
      });
    }
  };

  /* ─── Marquee pause on hover / focus ────────────────────────── */

  Drupal.behaviors.hsHomeMarquee = {
    attach(context) {
      const tracks = once('hs-home-marquee', '.hs-marquee__track', context);
      tracks.forEach(function (track) {
        track.addEventListener('mouseenter', function () { track.style.animationPlayState = 'paused'; });
        track.addEventListener('mouseleave', function () { track.style.animationPlayState = ''; });
        track.addEventListener('focusin',   function () { track.style.animationPlayState = 'paused'; });
        track.addEventListener('focusout',  function () { track.style.animationPlayState = ''; });
      });
    }
  };

  /* ─── Hero Pack Size Picker ──────────────────────────────────── */
  // When user clicks a pack button, update the displayed price + per-stick
  // rate, flip the active state, and update the ghost number in the visual.

  Drupal.behaviors.hsHomePackPicker = {
    attach(context) {
      const grids = once('hs-pack-picker', '.hs-pack-grid', context);
      grids.forEach(function (grid) {
        const priceEl = document.getElementById('hs-hero-price');
        const perEl   = document.getElementById('hs-hero-per');
        const ghostEl = document.getElementById('hs-ghost-num');
        const buttons = grid.querySelectorAll('.hs-pack-btn');

        buttons.forEach(function (btn) {
          btn.addEventListener('click', function () {
            // Update active state + aria-pressed
            buttons.forEach(function (b) {
              b.classList.remove('is-active');
              b.setAttribute('aria-pressed', 'false');
            });
            btn.classList.add('is-active');
            btn.setAttribute('aria-pressed', 'true');

            // Update price display
            const price = btn.getAttribute('data-price');
            const unit  = parseFloat(btn.getAttribute('data-unit') || '0');
            const pack  = btn.getAttribute('data-pack');

            if (priceEl) priceEl.textContent = '$' + price;
            if (perEl && unit) perEl.textContent = '$' + unit.toFixed(2) + ' / STICK';
            if (ghostEl && pack) ghostEl.textContent = pack;
          });
        });
      });
    }
  };

  /* ─── Sticky Buy Bar ─────────────────────────────────────────── */
  // Shows a fixed bottom bar after the user scrolls past the hero section.

  Drupal.behaviors.hsStickyBar = {
    attach(context) {
      const bars = once('hs-sticky-bar', '[data-behavior="hs-sticky-bar"]', context);
      bars.forEach(function (bar) {
        const hero = document.getElementById('hs-hero');
        if (!hero) return;

        function update() {
          const bottom = hero.getBoundingClientRect().bottom;
          bar.classList.toggle('is-visible', bottom < 0);
          bar.setAttribute('aria-hidden', bottom >= 0 ? 'true' : 'false');
        }

        window.addEventListener('scroll', update, { passive: true });
        update();
      });
    }
  };

  /* ─── Cart icon badge ────────────────────────────────────────── */

  function readCartCount() {
    var wrapper = document.querySelector('.hs-nav__cart-data');
    if (!wrapper) return 0;
    var countEl = wrapper.querySelector('.cart-block--summary__count');
    if (countEl) {
      var n = parseInt(countEl.textContent.trim(), 10);
      if (!isNaN(n)) return n;
    }
    var text  = wrapper.textContent || '';
    var match = text.match(/\((\d+)/);
    if (match) return parseInt(match[1], 10);
    return 0;
  }

  function applyCartBadge(count) {
    document.querySelectorAll('[data-behavior="hs-cart-icon"]').forEach(function (link) {
      // Text style: "Cart · N"
      var countEl = link.querySelector('.hs-nav__cart-count');
      if (countEl) countEl.textContent = count;
      // Legacy badge fallback
      var badge = link.querySelector('.hs-nav__cart-badge');
      if (badge) { badge.textContent = count; badge.hidden = count === 0; }
      link.setAttribute('aria-label',
        count === 0 ? Drupal.t('Cart') :
          Drupal.t('Cart, @count item(s)', { '@count': count })
      );
    });
  }

  Drupal.behaviors.hsHomeCartIcon = {
    attach: function (context) {
      once('hs-home-cart-icon', 'body', context).forEach(function () {
        applyCartBadge(readCartCount());
      });
      once('hs-home-cart-ajax', 'body', context).forEach(function () {
        document.addEventListener('ajax:success', function () {
          setTimeout(function () { applyCartBadge(readCartCount()); }, 120);
        });
      });
    }
  };

  /* ─── Smooth scroll for anchor links ───────────────────────── */

  Drupal.behaviors.hsHomeSmoothScroll = {
    attach(context) {
      const links = once(
        'hs-smooth-scroll',
        'a[href^="#"]:not([href="#"])',
        context
      );
      links.forEach(function (link) {
        link.addEventListener('click', function (e) {
          const target = document.getElementById(link.getAttribute('href').slice(1));
          if (!target) return;
          e.preventDefault();
          target.scrollIntoView({ behavior: 'smooth', block: 'start' });
          history.pushState(null, '', link.getAttribute('href'));
        });
      });
    }
  };

})(Drupal, once);
