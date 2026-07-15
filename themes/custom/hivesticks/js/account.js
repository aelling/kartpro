/**
 * HiveSticks Account — small behaviors for the account area.
 *   hsOrderFilter — filter order cards by derived status tone (client-side).
 */
(function (Drupal, once) {
  'use strict';

  Drupal.behaviors.hsOrderFilter = {
    attach: function (context) {
      once('hs-order-filter', '[data-behavior="hs-order-filter"]', context).forEach(function (bar) {
        var list = document.querySelector('.hs-ord-list');
        var emptyMsg = document.querySelector('.hs-ord-empty-filter');
        if (!list) return;
        var cards = Array.prototype.slice.call(list.querySelectorAll('.hs-ocard'));

        function matches(tone, filter) {
          if (filter === 'all') return true;
          if (filter === 'progress') return tone === 'active' || tone === 'pending';
          return tone === filter;
        }

        bar.addEventListener('click', function (e) {
          var btn = e.target.closest('.hs-pill');
          if (!btn) return;
          var filter = btn.getAttribute('data-filter');
          bar.querySelectorAll('.hs-pill').forEach(function (p) {
            p.classList.toggle('is-active', p === btn);
          });
          var shown = 0;
          cards.forEach(function (card) {
            var ok = matches(card.getAttribute('data-tone'), filter);
            card.style.display = ok ? '' : 'none';
            if (ok) shown++;
          });
          if (emptyMsg) emptyMsg.hidden = shown !== 0;
        });
      });
    }
  };
})(Drupal, once);
