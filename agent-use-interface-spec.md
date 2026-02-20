# Agent Use Interface (AUI) Specification

**Version:** 0.1.0-draft
**Status:** Draft
**Date:** 2026-02-16

---

## 1. Introduction

The **Agent Use Interface (AUI)** is a lightweight, XML-based schema that enables LLM agents to discover and construct URL-parameter-driven tasks on behalf of users.

AUI is intentionally narrow in scope. It describes **actions that are performed by composing query parameters onto a base URL** — things like searches, filters, form pre-fills, share intents, and configuration links. It is **not** a general-purpose API description format (use OpenAPI for that) and it is **not** a path-templating system (use RFC 6570 for that).

AUI is designed to be referenced from a site's `llms.txt` file and served at a well-known path.

### 1.1 Why XML?

AUI uses XML as its document format for the following reasons:

- **Browser-native rendering.** XML files open in any browser with a structured, navigable tree view — no server configuration required.
- **Optional CSS styling.** A simple `<?xml-stylesheet?>` processing instruction can reference a CSS file, transforming the raw XML into a polished, human-readable document in-browser.
- **Schema validation.** AUI v0.1 ships with a normative XML Schema Definition (XSD) for automated structural validation.
- **Agent compatibility.** All major LLMs can parse and reason about XML natively.
- **Dual audience.** The same file serves both agents (who parse the structure) and users (who can review it visually in a browser before sharing it with an agent).

### 1.2 Design Principles

| Principle | Description |
|---|---|
| **URL-parameter-scoped** | Only describes tasks driven by query parameters (`?key=value`). Path-based routing is out of scope. |
| **Agent-native** | Descriptions, parameter semantics, and examples are written for LLM comprehension, not human documentation. |
| **Composable** | Each task is self-contained. Agents can use one task or chain several together. |
| **Lightweight** | A single XML file with an optional CSS companion. No code generation, no SDKs, no auth flows. |
| **Universal-link friendly** | Base URLs should be universal links / App Links where possible, so constructed URLs open native app experiences. |
| **Scalable** | A catalog + detail pattern lets large sites split task definitions across files. Agents load the lightweight catalog first, then fetch only the detail files they need. |
| **Human-reviewable** | Users can open the file in a browser and understand what tasks an agent will have access to before granting trust. |

---

## 2. Discovery

### 2.1 File Location

An AUI file MUST be served at:

```
https://{domain}/.well-known/aui.xml
```

An optional CSS stylesheet MAY be served alongside it at:

```
https://{domain}/.well-known/aui.css
```

If the AUI file uses the catalog + detail pattern (see Section 4.3.1), detail files SHOULD be served at:

```
https://{domain}/.well-known/tasks/{task-id}.xml
```

### 2.2 Reference from llms.txt

The site's `llms.txt` file SHOULD reference the AUI file:

```
# URL Driven Actions
This site supports the Agent Use Interface specification.
AUI: https://example.com/.well-known/aui.xml
```

### 2.3 Content Type

The AUI file MUST be served with `Content-Type: application/xml` or `text/xml`.

### 2.4 CSS Stylesheet (Optional)

If a site wishes to provide a styled, human-readable view of the AUI file in browsers, it MAY include a CSS stylesheet processing instruction as the **first line after the XML declaration**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/css" href="aui.css"?>
```

The CSS file should be kept **dead simple** — basic typography, spacing, and color. The goal is readability, not a marketing page. See Section 7 for a reference stylesheet.

### 2.5 Canonical Publication

Canonical AUI specification assets are published on `agentuseinterface.org`:

```
Specification: https://agentuseinterface.org/spec/0.1
Namespace:     https://agentuseinterface.org/schema/0.1
XSD:           https://agentuseinterface.org/schema/0.1/aui.xsd
```

---

## 3. XML Namespace

The AUI XML namespace is:

```
https://agentuseinterface.org/schema/0.1
```

All AUI elements MUST be in this namespace. Documents SHOULD declare it as the default namespace on the root element:

```xml
<aui xmlns="https://agentuseinterface.org/schema/0.1" version="0.1">
```

Documents that want XML-validator compatibility SHOULD also include `xsi:schemaLocation`:

```xml
<aui
  xmlns="https://agentuseinterface.org/schema/0.1"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="https://agentuseinterface.org/schema/0.1 https://agentuseinterface.org/schema/0.1/aui.xsd"
  version="0.1">
```

---

## 4. Schema

### 4.0 Normative XSD

The normative XML Schema Definition (XSD) for AUI v0.1 is:

```
https://agentuseinterface.org/schema/0.1/aui.xsd
```

Producers SHOULD validate AUI documents against this schema before publishing.

Some cross-field rules are normative even when not fully expressible in XSD 1.0 (for example: `type="enum"` requires `<options>`). Producers and agents MUST enforce those rules during semantic validation.

### 4.1 Root Element: `<aui>`

| Attribute | Type | Required | Description |
|---|---|---|---|
| `version` | string | ✅ | Specification version. MUST be `"0.1"`. |

| Child Element | Type | Required | Description |
|---|---|---|---|
| `<origin>` | string | ✅ | The canonical origin (scheme + host) for all tasks. |
| `<name>` | string | ✅ | Human-readable name of the service. |
| `<description>` | string | ✅ | Natural-language description of the service, written for agent comprehension. |
| `<metadata>` | element | ❌ | Optional metadata about the service. |
| `<tasks>` | element | ✅ | Container for one or more `<task>` elements. |

### 4.2 `<metadata>` Element

| Child Element | Type | Required | Description |
|---|---|---|---|
| `<logo>` | string | ❌ | URL to a logo image. |
| `<contact>` | string | ❌ | Contact email for the AUI maintainer. |
| `<docs>` | string | ❌ | URL to human-readable documentation. |
| `<platforms>` | element | ❌ | Container for `<platform>` elements. |

Each `<platform>` element contains one of: `ios`, `android`, `web`.

### 4.3 `<task>` Element

A task represents a single URL-parameter-driven action an agent can construct. A `<task>` may appear in **inline form** (full definition) or **reference form** (lightweight summary pointing to a detail file). See Section 4.3.1 for details.

| Attribute | Type | Required | Description |
|---|---|---|---|
| `id` | string | ✅ | A unique, stable identifier for this task (kebab-case). |
| `output` | string | ❌ | One of: `display`, `background`. Defaults to `display`. `background` is for low-risk attribution/analytics fetches only. |
| `href` | anyURI | ❌ | URL of a detail file containing the full task definition (an `<aui-task>` document). When present, the task is in **reference form**. |

| Child Element | Type | Inline | Reference | Description |
|---|---|---|---|---|
| `<name>` | string | ✅ | ✅ | Short human-readable name. |
| `<description>` | string | ✅ | ✅ | Natural-language description of what this task does, written for agent comprehension. Should describe **when** an agent should use this task and **what outcome** the user can expect. |
| `<base-path>` | string | ✅ | ❌ | The URL path onto which parameters are appended. MUST start with `/` and MUST NOT include `?` or `#`. Full URL: `{origin}{base-path}?{params}`. |
| `<tags>` | element | ❌ | ❌ | Container for `<tag>` elements (freeform categorization strings). |
| `<parameters>` | element | ✅ | ❌ | Container for one or more `<param>` elements. |
| `<examples>` | element | ❌ | ❌ | Container for `<example>` elements. |

When `href` is present (reference form), `<base-path>`, `<parameters>`, and `<examples>` MUST be omitted. The catalog entry carries only what an agent needs for relevance judgment: name, description, and optionally tags.

#### 4.3.1 Inline vs. Reference Forms

**Inline form** — the task definition is complete within the catalog file:

```xml
<task id="product-search">
  <name>Search Products</name>
  <description>Search the product catalog.</description>
  <base-path>/search</base-path>
  <tags><tag>search</tag></tags>
  <parameters>...</parameters>
  <examples>...</examples>
</task>
```

**Reference form** — the task summary lives in the catalog; full details are in a separate file:

```xml
<task id="configure-wishlist" href="tasks/configure-wishlist.xml">
  <name>Configure Wishlist View</name>
  <description>Open the user's wishlist with specific display settings.</description>
  <tags><tag>personalization</tag></tags>
</task>
```

A single `aui.xml` MAY mix both forms — use inline for small tasks and reference for complex ones.

**href resolution:**
- Relative URLs are resolved against the `aui.xml` location (standard URI resolution).
- Absolute URLs are also allowed.
- Recommended convention: `tasks/{task-id}.xml` relative to `aui.xml`.
- Detail files SHOULD be same-origin as the `aui.xml` host.
- Detail files MUST be served with `Content-Type: application/xml` or `text/xml`.

#### Output Modes

| Value | Meaning |
|---|---|
| `display` | The URL should be presented to the user as a link to act on (default). The user or OS decides how to open it. |
| `background` | The URL may be fetched silently by the agent for attribution/analytics-style pings. Endpoints MUST be safe and idempotent, and MUST NOT create, modify, or delete user state. |

### 4.4 `<param>` Element

| Attribute | Type | Required | Description |
|---|---|---|---|
| `name` | string | ✅ | The query parameter key as it appears in the URL. |
| `type` | string | ✅ | One of: `string`, `number`, `integer`, `boolean`, `enum`. |
| `required` | boolean | ❌ | Whether this parameter must be included. Defaults to `false`. |

| Child Element | Type | Required | Description |
|---|---|---|---|
| `<description>` | string | ✅ | What this parameter represents, written for agent comprehension. |
| `<default>` | string | ❌ | Default value if omitted. |
| `<pattern>` | string | ❌ | A regex pattern the value must match, using ECMAScript (JavaScript) regex syntax without delimiters. |
| `<min>` | number | ❌ | Minimum value (for `number`/`integer`). |
| `<max>` | number | ❌ | Maximum value (for `number`/`integer`). |
| `<separator>` | string | ❌ | Delimiter for multi-value parameters (e.g., `,` for `?tags=a,b,c`). |
| `<example>` | string | ❌ | An example value for this parameter. |
| `<options>` | element | ❌ | Container for `<option>` elements. Required when `type="enum"`. |

### 4.5 `<option>` Element (Enum Values)

| Attribute | Type | Required | Description |
|---|---|---|---|
| `value` | string | ✅ | The literal value used in the URL. |

The text content of `<option>` is a natural-language description of when to use this value, written for agent comprehension.

```xml
<option value="price_asc">Cheapest first. Use when user wants deals or is budget-conscious.</option>
```

### 4.6 `<example>` Element

| Child Element | Type | Required | Description |
|---|---|---|---|
| `<intent>` | string | ✅ | A natural-language description of what the user wants. Written as something a user might say to an agent. |
| `<url>` | string | ✅ | The fully constructed URL that fulfills the intent. |

### 4.7 `<aui-task>` Element (Detail File Root)

When a task uses the reference form (Section 4.3.1), its full definition lives in a standalone detail file with `<aui-task>` as the root element. This element is structurally identical to an inline `<task>` but serves as an unambiguous root for standalone documents.

| Attribute | Type | Required | Description |
|---|---|---|---|
| `id` | string | ✅ | MUST match the `id` of the corresponding `<task>` entry in the catalog. |
| `output` | string | ❌ | One of: `display`, `background`. Defaults to `display`. |

| Child Element | Type | Required | Description |
|---|---|---|---|
| `<name>` | string | ✅ | Short human-readable name. |
| `<description>` | string | ✅ | Natural-language description. |
| `<base-path>` | string | ✅ | The URL path onto which parameters are appended. |
| `<tags>` | element | ❌ | Container for `<tag>` elements. |
| `<parameters>` | element | ✅ | Container for one or more `<param>` elements. |
| `<examples>` | element | ❌ | Container for `<example>` elements. |

The detail file is **self-contained** — it includes all fields needed to construct URLs without merging data from the catalog. If the catalog and detail file disagree on `<name>` or `<description>`, the **detail file is authoritative**.

Example detail file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/css" href="../aui.css"?>
<aui-task xmlns="https://agentuseinterface.org/schema/0.1"
  id="configure-wishlist" output="display">
  <name>Configure Wishlist View</name>
  <description>Open the user's wishlist with specific display settings.</description>
  <base-path>/wishlist</base-path>
  <tags><tag>personalization</tag></tags>
  <parameters>
    <param name="sort" type="enum">
      <description>How to sort wishlist items.</description>
      <options>
        <option value="date_added">Most recently saved first.</option>
        <option value="price_drop">Largest price drop first.</option>
      </options>
    </param>
  </parameters>
</aui-task>
```

---

## 5. URL Construction

Agents construct URLs using the following algorithm:

```
1. Start with: {origin}{base-path}
2. Collect all parameter values (from user intent + defaults)
3. URL-encode each key and each value
4. Join as query string: ?key1=value1&key2=value2
5. Append to base: {origin}{base-path}?key1=value1&key2=value2
```

Parameters with null or empty values SHOULD be omitted unless they are required.

Boolean parameters SHOULD be encoded as `true` / `false`.

To tolerate implementation variance:

- Producers MAY encode spaces as either `%20` or `+`.
- Parameter order is not semantically significant.
- Consumers SHOULD accept equivalent URLs that differ only in encoding style or parameter order.

Multi-value parameters using a `<separator>` SHOULD encode the joined value as a single parameter (e.g., `?tags=swift,ios`), not as repeated keys. Consumers MAY accept repeated-key equivalents.

---

## 6. Full Example

See the accompanying `aui.xml` file in `example/` for a complete working example of an AUI document with three tasks (product search, share product, configure wishlist). The example demonstrates both inline and reference forms — two tasks are defined inline, while the configure-wishlist task uses the reference form with its full definition in `tasks/configure-wishlist.xml`.

---

## 7. CSS Styling Guide

Sites MAY provide a CSS file to make the AUI document human-readable in browsers. The stylesheet is referenced via the `<?xml-stylesheet?>` processing instruction.

### 7.1 Principles

- **Dead simple.** Basic typography, spacing, and color only.
- **No JavaScript.** The styled view must work with CSS alone.
- **Readable, not branded.** The goal is trust and transparency, not marketing.
- **Graceful absence.** The XML must remain fully functional without the CSS file.

### 7.2 Reference Stylesheet

A reference `aui.css` in `example/` is provided as a companion file to this specification. Sites MAY use it as-is or adapt it to their brand, provided the core task structure remains legible.

### 7.3 Recommended CSS Targets

Since browsers apply CSS to XML elements by tag name, the following selectors are available:

| Selector | Purpose |
|---|---|
| `aui` | Root container. Set base font, max-width, margin. |
| `name` | Service and task names. Style as headings. |
| `description` | Descriptive text blocks. Style as paragraphs. |
| `origin` | The base URL. Style as monospace/code. |
| `task` | Each task block. Add borders, padding, spacing. |
| `param` | Each parameter. Display as a compact block. |
| `option` | Enum values. Display inline or as a list. |
| `example` | Intent/URL pairs. Style as callout blocks. |
| `intent` | User intent string. Style as italic or quoted. |
| `url` | Constructed URL. Style as monospace/code. |
| `base-path` | Task path. Style as monospace/code. |
| `tag` | Freeform tags. Style as inline badges. |
| `metadata` | Service metadata block. Style as a subtle header. |
| `platform` | Platform indicators. Style as inline badges. |

### 7.4 Reference Tasks and Detail Files

When using the catalog + detail pattern, the CSS SHOULD provide visual differentiation for reference tasks:

| Selector | Purpose |
|---|---|
| `task[href]` | Reference task entries. Use a dashed border or distinct background to indicate the task definition lives elsewhere. |
| `task[href]::after` | Display the `href` value so users can see where the detail file lives. |
| `aui-task` | Root element of standalone detail files. Mirror the base `aui` styles (font, max-width, margin) so detail files render properly in browsers. |

Detail file selectors (`aui-task > name`, `aui-task > description`, etc.) should mirror their `task` counterparts for consistent rendering.

---

## 8. Integration with llms.txt

A site's `llms.txt` SHOULD reference the AUI file and provide brief context:

```
# Example Shop

> An online electronics store with universal link support.

## Agent Use Interface
This site publishes an AUI file describing URL-parameter-driven tasks
that agents can construct on behalf of users.

- AUI Specification: https://shop.example.com/.well-known/aui.xml
- Supported platforms: iOS, Android, Web
- All task URLs are universal links that open native app experiences
  when the app is installed.

## Additional Resources
- API Documentation: https://docs.example.com/api
- Privacy Policy: https://example.com/privacy
```

---

## 9. Agent Behavior Guidelines

Agents consuming AUI files SHOULD:

1. **Respect `required` parameters.** Never construct a URL without all required parameters populated.
2. **Apply defaults.** Use declared `<default>` values when the user's intent doesn't specify a preference.
3. **Use `<option>` descriptions for disambiguation.** When multiple enum values could match a user's intent, prefer the value whose description best aligns with the stated goal.
4. **Prefer `<example>` elements for calibration.** Use the intent → URL examples to understand the expected mapping style before constructing novel URLs.
5. **Respect the `output` attribute.** Don't silently fetch a URL marked `display`. Only fetch `background` URLs when they meet the Section 10 safety requirements.
6. **Validate before constructing.** Check `<pattern>`, `<min>`, `<max>`, and `<options>` constraints before emitting a URL.
7. **Chain tasks when needed.** If a task requires a value the agent doesn't have (e.g., a SKU), use another task (e.g., product search) to discover it first.
8. **Attribute agent usage.** If a `ref` or attribution parameter exists, agents SHOULD populate it.
9. **Disclose background fetches.** Agents SHOULD provide user-visible activity logs or equivalent disclosure for background URL fetches.
10. **Ignore the CSS.** The `<?xml-stylesheet?>` instruction is for browsers. Agents should parse the XML structure directly.
11. **Load the catalog first.** When discovering a site's AUI file, read the root `aui.xml` catalog before fetching any detail files. Use task names, descriptions, and tags to judge relevance.
12. **Fetch detail files on demand.** Only fetch detail files (via `href`) for tasks the agent judges relevant to the user's current intent. Do not eagerly fetch all detail files.
13. **Handle detail file failures gracefully.** If a detail file fetch fails (404, timeout, invalid XML), the agent MUST NOT construct URLs for that task and SHOULD inform the user the task is unavailable.
14. **Support mixed-mode catalogs.** A single `aui.xml` may contain both inline and reference tasks. Agents MUST handle both forms correctly.
15. **Detail file is authoritative.** If a catalog entry's `<name>` or `<description>` differs from the detail file, the detail file takes precedence. The `id` in the detail file MUST match the catalog entry's `id`.

---

## 10. Security Considerations

- AUI files MUST be served over HTTPS.
- AUI files MUST NOT include authentication tokens, API keys, or secrets in `<base-path>` or `<default>` values.
- `background` tasks are intended for attribution/analytics pings where a direct user click may not occur.
- `background` endpoints MUST be safe and idempotent.
- `background` endpoints MUST NOT create, modify, or delete user resources, trigger purchases/messages, or mutate authenticated session state.
- Agents SHOULD provide clear user-visible disclosure (for example, activity history) when background URLs are fetched.
- Agents SHOULD NOT construct URLs that include user PII in parameters unless the user has explicitly requested the action.
- The optional CSS stylesheet MUST NOT contain external resource references beyond fonts. No images, no iframes, no tracking pixels.
- Detail files referenced via `href` MUST be served over HTTPS.
- Detail files SHOULD be same-origin as the catalog `aui.xml`. Agents SHOULD warn users before fetching cross-origin detail files.
- Agents MUST verify that the `id` attribute in the detail file matches the catalog entry. A mismatch indicates a configuration error or potential tampering.

---

## 11. Comparison with Related Specifications

| Specification | Scope | AUI Relationship |
|---|---|---|
| `llms.txt` | Site-level agent guidance | AUI is discovered via `llms.txt`. |
| OpenAPI | Full API description | AUI is narrower — URL parameters only, no request bodies, no auth. |
| RFC 6570 (URI Templates) | URL path + param templating | AUI adds semantics (descriptions, types, constraints) on top of the template concept. |
| MCP (Model Context Protocol) | Agent ↔ server tool calls | AUI is stateless and URL-only; MCP is for richer, bidirectional interactions. |
| Apple AASA / Android Asset Links | App ↔ domain ownership verification | AUI complements these by describing *how* to construct the URLs they verify. |

---

## 12. Future Considerations

The following are **out of scope** for v0.1 but may be addressed in future versions:

- **Authentication flows** — OAuth-aware parameter injection.
- **Response schemas** — Describing what the user sees after navigating.
- **Task chaining** — Formal dependency graphs between tasks.
- **Localization** — Multi-language descriptions and parameter values.
- **Rate limiting hints** — Telling agents how frequently they can construct certain task URLs.
- **Path parameters** — Extending scope beyond query parameters to include `{id}`-style path segments.
- **XSLT alternative** — An optional XSLT stylesheet for richer browser rendering.

---

## License

This specification is released under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
