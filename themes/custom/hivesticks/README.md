# HiveSticks Drupal Theme

Custom Drupal 9/10 theme for hivesticks.com.

## Installation

1. Upload the `hivesticks` folder to `/web/themes/custom/` on your Drupal server
   (or `/themes/custom/` depending on your setup).
2. Log into Drupal admin → Appearance → find **HiveSticks** → click **Install and set as default**.
3. Clear the Drupal cache: `drush cr` or Admin → Configuration → Performance → Clear caches.

## File Structure

```
hivesticks/
├── hivesticks.info.yml          # Theme declaration
├── hivesticks.libraries.yml     # CSS/JS asset definitions
├── hivesticks.theme             # PHP preprocessing hooks
├── css/
│   └── global.css               # All theme styles (BEM, .hs- prefix)
├── js/
│   └── global.js                # Mobile nav, smooth scroll, sticky nav
└── templates/
    ├── html.html.twig            # HTML document wrapper
    ├── page.html.twig            # General inner pages (blog, contact, etc.)
    └── page--front.html.twig    # Homepage / landing page
```

## Drupal Regions

The theme defines these regions for placing blocks:

| Region          | Used for                                        |
|-----------------|-------------------------------------------------|
| `header`        | System messages, admin blocks                   |
| `hero`          | Optional promo blocks inside the hero section   |
| `content`       | Main content (product listings, page body)      |
| `footer_first`  | Footer brand area extras                        |
| `footer_second` | Footer Shop column extras                       |
| `footer_third`  | Footer Company column extras                    |
| `sidebar_first` | Inner page left sidebar                         |
| `sidebar_second`| Inner page right sidebar                        |

## Drupal Commerce Integration

The product grid on the homepage checks for content in the `content` region first.
If Drupal Commerce product listings are placed in that region, they will render instead
of the static HTML cards. Use Commerce Views to output products into that region.

## Notes

- All CSS classes are prefixed with `.hs-` to avoid conflicts with Drupal core or contrib modules.
- Google Fonts (Playfair Display + Inter) are loaded in `html.html.twig`.
- The theme is compatible with the Drupal admin toolbar (auto-offsets the sticky nav).
- To enable Twig debugging: edit `services.yml` → set `debug: true` under `twig.config`.
