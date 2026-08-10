# GyroidOS Landing Page

Landing page for [GyroidOS](https://github.com/gyroidos), built with
[Material for MkDocs](https://squidfunk.github.io/mkdocs-material/). It is hosted
separately from the `gyroidos.github.io` documentation site; the navigation bar links
to sections of the landing page itself, with a single "Documentation" entry pointing
to <https://gyroidos.github.io/>.

## Structure

- `mkdocs.yml` — site configuration (Material theme, navigation, blue GyroidOS palette)
- `docs/index.md` — all landing page content (hero, features, platforms, resources)
- `docs/stylesheets/extra.css` — GyroidOS blue tones and hero/strip/contact styling
- `docs/assets/` — logo and favicon

## Theme

Built with [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
(developed against version 9.7.7, MIT license). The `overrides/partials/` templates
are modified copies of Material's originals; the corresponding license is included
verbatim in `overrides/LICENSE`.

The site loads no resources from external servers: `theme.font: false` disables
Google Fonts (the theme falls back to the system font stack), and
`overrides/partials/source.html` disables the theme's GitHub statistics fetch.

## Local preview

```sh
pip install -r requirements.txt
mkdocs serve
# open http://localhost:8000
```

## Deployment (GitHub Pages)

Automatic: `.github/workflows/deploy.yml` builds the site and pushes it to the
`gh-pages` branch on every push to `main`/`master`. After the first run, enable it
once under **Settings → Pages → Source: Deploy from a branch → `gh-pages` / (root)**.

Manual alternative from a local checkout:

```sh
mkdocs gh-deploy --force
```

The site is served at the custom domain <https://www.gyroidos.io/> (`site_url` in
`mkdocs.yml`). `docs/CNAME` carries the domain into the published branch; the DNS
for `www.gyroidos.io` must point to GitHub Pages (CNAME record to
`<owner>.github.io`), and the domain should be entered once under
**Settings → Pages → Custom domain** with "Enforce HTTPS" enabled.
