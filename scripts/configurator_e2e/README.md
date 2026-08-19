# Configurator browser gate

This directory is an isolated, test-only Chromium harness. It is not a root JavaScript application, a product build, or part of the Hex package.

Run the local harness on Linux (using an installed compatible Playwright browser):

```sh
npm ci --prefix scripts/configurator_e2e
npm test --prefix scripts/configurator_e2e
```

The seven committed visual baselines are Linux-only. On macOS or another host platform, use the pinned-container command below for the complete gate; a native `npm test` may exercise functional cases but its platform-specific screenshot comparison is unsupported and must not create or commit `*-darwin.png` (or other host-specific) baselines.

Run the authoritative pinned-container gate:

```sh
npm run test:container --prefix scripts/configurator_e2e
```

Only generate or update visual baselines in the pinned container:

```sh
npm run test:container:update-snapshots --prefix scripts/configurator_e2e
```

CI runs on Linux with only `npm ci` and `npm test`; it never updates snapshots. The harness binds a dependency-free server to localhost and allows only safe committed `assets/rendro/` and `brand/tokens/` paths. Its claims are limited to pinned Chromium behavior, scoped accessibility-tree/axe evidence, and pinned-container Linux pixel comparisons—not host-portable screenshots, Firefox/Safari, VoiceOver/NVDA, WCAG certification, or aesthetic quality.
