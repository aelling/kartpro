/**
 * @file
 * HiveSticks theme — global JavaScript behaviors.
 */

(function (Drupal) {

  'use strict';

  /**
   * Mobile navigation toggle.
   */
  Drupal.behaviors.hiveSticksNav = {
    attach: function (context, settings) {
      var toggle = context.querySelector('.hs-nav__mobile-toggle');
      var drawer = context.querySelector('.hs-nav__mobile-drawer');

      if (!toggle || !drawer) return;

      toggle.addEventListener('click', function () {
        var expanded = toggle.getAttribute('aria-expanded') === 'true';
        toggle.setAttribute('aria-expanded', !expanded);
        drawer.hidden = expanded;
      });

      // Close drawer when a link inside it is clicked.
      drawer.querySelectorAll('a').forEach(function (link) {
        link.addEventListener('click', function () {
          toggle.setAttribute('aria-expanded', 'false');
          drawer.hidden = true;
        });
      });
    }
  };

  /**
   * Smooth scroll for anchor links within the page.
   */
  Drupal.behaviors.hiveSticksScroll = {
    attach: function (context, settings) {
      context.querySelectorAll('a[href^="#hs-"]').forEach(function (anchor) {
        anchor.addEventListener('click', function (e) {
          var target = document.querySelector(this.getAttribute('href'));
          if (target) {
            e.preventDefault();
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
            // Update URL without reload.
            if (history.pushState) {
              history.pushState(null, null, this.getAttribute('href'));
            }
          }
        });
      });
    }
  };

  /**
   * Sticky nav: add a shadow class when page is scrolled.
   */
  Drupal.behaviors.hiveSticksNavShadow = {
    attach: function (context, settings) {
      var nav = document.querySelector('.hs-nav');
      if (!nav) return;

      function onScroll() {
        if (window.scrollY > 10) {
          nav.classList.add('hs-nav--scrolled');
        } else {
          nav.classList.remove('hs-nav--scrolled');
        }
      }

      window.addEventListener('scroll', onScroll, { passive: true });
      onScroll();
    }
  };

}(Drupal));
