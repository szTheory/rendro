# Deferred Items

## 2026-08-17 — Public API manifest drift

- **Discovered during:** 125-03 full-suite verification
- **Scope:** `priv/public_api.json` does not include the already-existing `Rendro.Theme.preset/2` public API entry.
- **Reason deferred:** The API function was present before this plan; regenerating the manifest is outside the source-confined genre-grammar task.
- **Evidence:** `mix test` fails only `Rendro.DocsContract.PublicApiContractTest` and `Rendro.PublicApi.ManifestTest` with the prescribed `mix rendro.api.gen` remediation.
