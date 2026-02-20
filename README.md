# Agent Use Interface (AUI)

A lightweight, XML-based schema that enables LLM agents to discover and construct URL-parameter-driven tasks on behalf of users.

## Overview

AUI describes **actions that are performed by composing query parameters onto a base URL** — things like searches, filters, form pre-fills, share intents, and configuration links. It is intentionally narrow in scope:

- **It is not** a general-purpose API description format (use OpenAPI for that).
- **It is not** a path-templating system (use RFC 6570 for that).
- **It is not** a bidirectional agent protocol (use MCP for that).

AUI is a single XML file, served at `/.well-known/aui.xml`, that both agents and humans can read.

## Quick Links

| Resource | URL |
|---|---|
| Specification | [agentuseinterface.org/spec/0.1](https://agentuseinterface.org/spec/0.1) |
| XML Schema (XSD) | [agentuseinterface.org/schema/0.1/aui.xsd](https://agentuseinterface.org/schema/0.1/aui.xsd) |
| Example | [example/aui.xml](example/aui.xml) |
| Website | [agentuseinterface.org](https://agentuseinterface.org) |

## How It Works

1. **Publish** — A site serves `aui.xml` at `/.well-known/aui.xml` describing its URL-driven tasks.
2. **Discover** — An LLM agent finds the file via `llms.txt` or the well-known path.
3. **Parse** — The agent reads the XML to understand available tasks, parameters, and constraints.
4. **Construct** — Based on user intent, the agent builds a URL with the right query parameters.
5. **Present** — The user receives a link that opens the right experience — on web or in a native app.

## Example

```xml
<aui xmlns="https://agentuseinterface.org/schema/0.1" version="0.1">
  <name>Example Shop</name>
  <origin>https://shop.example.com</origin>
  <description>An online electronics store.</description>
  <tasks>
    <task id="product-search">
      <name>Search Products</name>
      <description>Search the product catalog.</description>
      <base-path>/search</base-path>
      <parameters>
        <param name="q" type="string" required="true">
          <description>The search query.</description>
        </param>
        <param name="category" type="enum">
          <description>Filter by category.</description>
          <options>
            <option value="electronics">Phones, tablets, laptops.</option>
            <option value="audio">Headphones, speakers.</option>
          </options>
        </param>
      </parameters>
    </task>
  </tasks>
</aui>
```

User says: *"Find me noise cancelling headphones under $200"*

Agent constructs: `https://shop.example.com/search?q=noise+cancelling+headphones&category=audio&price_max=200`

## Repo Structure

```
agent-use-interface/
├── agent-use-interface-spec.md   # The specification (source of truth)
├── schema/0.1/aui.xsd            # Normative XML Schema Definition
├── example/
│   ├── aui.xml                    # Full working example
│   ├── aui.css                    # Reference stylesheet for browser rendering
│   └── aui-browser-preview.html   # HTML preview of styled XML
├── public/                        # Website (agentuseinterface.org)
│   ├── index.html
│   ├── style.css
│   ├── spec/0.1/index.html
│   ├── schema/0.1/aui.xsd
│   └── example/
└── firebase.json                  # Hosting config
```

## Contributing

AUI is in early draft. Feedback is welcome — [open an issue](https://github.com/FRE-Studios/agent-use-interface/issues) to share thoughts, suggest changes, or report problems.

## License

- **Specification prose** (`agent-use-interface-spec.md`): [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- **Code, schema, and website**: [Apache License 2.0](LICENSE)
