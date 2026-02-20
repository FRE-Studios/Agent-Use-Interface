# CLAUDE.md

## What This Is

Agent Use Interface (AUI) — a lightweight XML schema that lets LLM agents discover and construct URL-parameter-driven tasks for users. Think: searches, filters, share intents, config links.

## Repo Structure

- `agent-use-interface-spec.md` — The spec (source of truth, CC BY 4.0)
- `schema/0.1/aui.xsd` — Normative XML Schema Definition
- `example/` — Working example (`aui.xml`, `aui.css`, browser preview HTML)
- `public/` — Website for agentuseinterface.org (Firebase Hosting)
  - `index.html` + `style.css` — Homepage
  - `spec/0.1/index.html` — HTML rendering of the spec
  - `schema/0.1/aui.xsd` — Copy of XSD (must stay in sync with `schema/`)
  - `example/` — Copies of example files (must stay in sync with `example/`)
- `firebase.json` — Hosting config (cleanUrls, XML/XSD headers with CORS)

## Key Rules

- **Spec is canonical.** If the spec markdown and the HTML spec page diverge, the markdown wins. Update `public/spec/0.1/index.html` to match.
- **Keep copies in sync.** `public/schema/` and `public/example/` are copies of their root counterparts. After editing originals, copy them to `public/`.
- **Relative links in public/.** All internal links use relative paths (not `/absolute`) so pages work locally via `file://`.
- **No build step.** Everything is static HTML/CSS. No JS, no bundler, no generators.
- **Dual license.** Spec prose = CC BY 4.0. Code/schema/website = Apache 2.0.

## Hosting

- Firebase Hosting, project ID: `agent-use-interface`
- Deploy dir: `public/`
- Domain: agentuseinterface.org
- `.firebaserc` is gitignored

## GitHub

- Repo: `github.com/FRE-Studios/agent-use-interface`
- Main branch: `main`
