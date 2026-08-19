# Deferred Items

## 2026-08-19 — unrelated full-suite archive fixture failure

- `mix test` reaches `Rendro.DocsContract.PresetFontsPackageContractTest` and fails because `contents.tar.gz` is absent from the Hex archive inspected by the test.
- This is outside Plan 128-02's Mix generator and test files. The focused generator and snippet suites pass.
