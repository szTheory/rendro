# Phase 71 Deferral Drafts

Pre-validated `evidence_deferred` strings for matrix-only rows in plan 71-03.
Each string is ≥40 characters and avoids forbidden vocabulary (TBD, not yet, deferred for later).

## Mandated deferrals

### forms.signature_widget_viewers.pdfjs

```json
"evidence_deferred": "PDF.js does not implement AcroForm signature widget editing or unsigned placeholder rendering per mozilla/pdf.js#4202; promotion requires upstream signature-field support."
```

### signing.viewers.apple_preview (signed_artifact)

```json
"evidence_deferred": "Apple Preview does not validate /Sig digital signatures and append-save invalidates signature dictionaries; signed-artifact viewer promotion requires Acrobat or pdfium-cli structural lanes."
```

### signing.viewers.pdfjs (signed_artifact)

```json
"evidence_deferred": "PDF.js exposes no /Sig validation UI or signed-artifact integrity panel for the representative fixture; viewer promotion deferred until signature validation surfaces exist."
```

### signing.long_lived.viewers.apple_preview

```json
"evidence_deferred": "Apple Preview does not surface long-term-validation timestamp, revocation, or expiry indicators for augmented PDF signatures on the representative certomancer fixture."
```

### signing.long_lived.viewers.chrome_pdfium

```json
"evidence_deferred": "pdfium-cli structural open and form extraction do not expose long-term-validation timestamp, revocation, or expiry indicators; LTV posture remains Acrobat-only for viewer promotion."
```

### signing.long_lived.viewers.pdfjs

```json
"evidence_deferred": "PDF.js does not implement long-term-validation timestamp, revocation, or expiry indicators for augmented signatures; viewer promotion deferred until LTV UI exists upstream."
```

## Conditional deferrals (default until operator session proves otherwise)

### forms.viewers.pdfjs

```json
"evidence_deferred": "PDF.js failed the forms four-check save-and-reopen round-trip on the representative fixture during Phase 71 operator review; edit_or_toggle persistence is not reliable."
```

### embedded_files.viewers.apple_preview

```json
"evidence_deferred": "Apple Preview Attachments UI still does not discover, open, or extract the representative embedded-artifact fixture after Phase 71 re-verify; v1.9 deferral stands."
```

### forms.signature_widget_viewers.pdfjs (alias)

Same as `forms.signature_widget_viewers.pdfjs` above — signature widget and forms pdfjs cells defer independently when checklist fails.

## Template references (D-22)

| Template | Used for |
|----------|----------|
| UPSTREAM_ISSUE | forms×pdfjs, signature_widget×pdfjs |
| NO_SIG_VALIDATION | signed_artifact×{apple_preview,pdfjs} |
| NO_LTV_INDICATORS | long_lived×{apple_preview,chrome_pdfium,pdfjs} |
| SURFACE_EQUIVALENCE | signing_preparation non-Acrobat inheritance (supported path, not deferral) |
