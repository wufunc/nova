---
tags: [api, dom, fallback, scraping, provider, architecture]
modules: [contents/providers, core/providers]
summary: "API-first integration strategy with DOM scraping as fallback"
tag: mem/001
---

# ADR 001: API-First Strategy with DOM Fallback

## Date
2026-01-10 15:30

## Background

The browser extension needs to interact with multiple AI chat providers (ChatGPT, Claude, Gemini, etc.) to enhance their functionality. Two fundamentally different integration approaches were considered:

1. **DOM-first**: Scrape the web UI, inject elements, intercept DOM events. This is what most browser extensions do.
2. **API-first**: Intercept/reuse the provider's internal API calls, only falling back to DOM when API access is unavailable or insufficient.

Key constraints:
- Providers frequently change their web UI (DOM structure), breaking scrapers
- Internal APIs are more stable but undocumented and may require authentication tokens
- Some features (e.g., UI customization) inherently require DOM access
- Extension must work across 5+ providers with varying API accessibility

## Decision

**Chosen approach: API-first with DOM fallback.**

Each provider module implements a layered strategy:
1. **Try API first**: Intercept network requests to discover API endpoints and auth tokens. Use these for data operations (sending messages, fetching conversations).
2. **Fall back to DOM**: Only when API is unavailable (e.g., provider blocks internal API access) or for inherently visual operations (UI injection, layout modification).
3. **Error classification drives fallback**: API errors are classified as `retryable` (network issues) vs `fatal` (auth failure, endpoint removed). Only `fatal` errors trigger DOM fallback.

Implementation key points:
- Each provider has `api-client.ts` (primary) and `dom-adapter.ts` (fallback)
- A shared `ProviderStrategy` interface ensures both paths expose the same contract
- Auth tokens are extracted from intercepted requests, not hardcoded

## Consequences

### Advantages
- API responses are structured data — no fragile DOM parsing
- API endpoints change less frequently than UI layouts
- Faster execution (no DOM traversal, no mutation observers)
- Easier testing (API responses can be mocked cleanly)

### Disadvantages
- Reverse-engineering internal APIs requires ongoing maintenance
- Some providers actively obfuscate their API (e.g., encrypted payloads)
- Two code paths per provider increases complexity
- Auth token extraction may break on provider security updates

### Risk Mitigation
- Monitor provider API changes via automated regression tests
- Keep DOM fallback functional as insurance (not just a stub)
- Abstract provider-specific auth into isolated modules for quick patching

## Related Decisions
- None (first ADR in this project)
