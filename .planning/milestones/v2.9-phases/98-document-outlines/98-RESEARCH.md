# Phase 98: Document Outlines (Bookmarks) - Research

**Researched:** 2024-06-14 (interrupted)
**Domain:** Core PDF Serialization / Engine Rendering
**Confidence:** MEDIUM

## Summary

The objective of this phase is to add support for hierarchical Document Outlines (Bookmarks) to the Rendro PDF engine. It requires extracting outline items from blocks during the `paginate` phase and serializing them into a doubly-linked `/Outlines` dictionary tree during the `render` phase. To support internationalization and non-Latin characters, the outline titles (`/Title`) must be explicitly encoded as UTF-16BE with a Byte Order Mark (`\xFE\xFF`).

**Primary recommendation:** Add `outline: boolean() | String.t()` and `outline_level: non_neg_integer()` attributes to `Rendro.Block`. Have `Rendro.Pipeline.Paginate` aggregate these into a hierarchical structure stored on `Rendro.Metadata` (similar to how it collects anchors). In `Rendro.PDF.Writer`, add a new allocation/serialization pass to output the doubly-linked Outline Item dictionaries, linked from the Catalog's `/Outlines` entry.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Outline Harvesting | Paginate Phase | — | Outline items are tied to specific blocks and resolved page numbers, which are finalized during pagination. |
| Outline Storage | Metadata | — | Like `anchors`, outlines represent document-level semantic structure derived from blocks. |
| PDF Dictionary Serialization | Render Phase (Writer) | — | PDF objects, cross-references, doubly-linked `/Outlines` tree and UTF-16BE encoding must happen at the binary protocol layer. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir `unicode` | Native | UTF-16BE encoding | Erlang's `:unicode` module natively handles UTF-8 to UTF-16BE conversions. |

## Architecture Patterns

### Harvesting in Paginate
Similar to `collect_anchors/1` in `lib/rendro/pipeline/paginate.ex`, we need to collect outlines by traversing blocks on each page.
- Add `outline` (default `false`) and `outline_level` (default `1`) to `Rendro.Block`.
- When `outline: true` (or a string value), extract the string content (e.g., from `Rendro.Text`) and store it along with its `outline_level`, the page index, and the block's `y` coordinate.
- Add an `outlines: []` field to `Rendro.Metadata` to hold the aggregated tree.

### Encoding UTF-16BE Strings
PDF strings for `/Title` can be ASCII or UTF-16BE. To guarantee cross-viewer rendering of non-Latin characters, use UTF-16BE with a Byte Order Mark (BOM).
```elixir
defp encode_utf16be_string(str) do
  utf16 = :unicode.characters_to_binary(str, :utf8, {:utf16, :big})
  bom = <<0xFE, 0xFF>>
  bom <> utf16
end
```
Serialize this as a hex string `<FEFF...>` to avoid escaping issues in PDF literals.

### Serializing the Doubly-Linked Tree
The PDF Outline hierarchy requires a doubly-linked list.
- **Outline Dictionary (Root)**: Contains `/Type /Outlines`, `/First`, `/Last`, and `/Count` (total visible descendants).
- **Outline Item Dictionaries**: Each item contains `/Title`, `/Parent`, `/Dest` (e.g., `[page_ref, /XYZ, x, y, null]`), and optionally `/Next`, `/Prev`, `/First`, `/Last`, and `/Count` (negative if collapsed).

During `build_objects` in `Rendro.PDF.Writer`:
1. Recursively build the outline items, assigning them object numbers.
2. Link them together by establishing Parent, Next, Prev, First, Last relationships.
3. Link the root Outline Dictionary to the Catalog with `/Outlines`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| String Encoding | Manual bit manipulation | `:unicode.characters_to_binary/3` | Erlang standard library handles surrogate pairs and complex UTF-8 codepoints securely and correctly. |

## Common Pitfalls

### Pitfall 1: Incorrect Dictionary Linking
**What goes wrong:** PDF outlines don't show up, or clicking them crashes the viewer.
**Why it happens:** The `/First`, `/Last`, `/Next`, and `/Prev` pointers are incorrectly assigned, breaking the doubly-linked tree requirement of the PDF spec.
**How to avoid:** Ensure rigorous unit tests validate the structural pointers for nested hierarchies. Each parent must point to its first and last child. Children must form a contiguous Next/Prev chain.

### Pitfall 2: Escaping in Literal Strings
**What goes wrong:** UTF-16BE strings get corrupted when written to PDF.
**Why it happens:** Writing binary data containing `(` or `)` or `\` into a PDF `()` string literal requires complex escaping.
**How to avoid:** Always serialize UTF-16BE strings using PDF hex string syntax `<...>` instead of literal string syntax `(...)`.

## Code Examples

### UTF-16BE Conversion
```elixir
# In Rendro.PDF.Object or Writer
def serialize_utf16_hex(string) do
  utf16_bytes = :unicode.characters_to_binary(string, :utf8, {:utf16, :big})
  bom = <<0xFE, 0xFF>>
  {:hex_string, bom <> utf16_bytes}
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Flat lists | Declarative block outlines | Phase 98 | Developers just assign `outline: true` to a block and the engine automatically builds the hierarchy. |

## Open Questions (RESOLVED)

1. **Extraction Logic**
   - What we know: `outline: true` on a block needs to extract text.
   - What's unclear: If the block contains a complex composition (e.g., a `MeasuredText` with multiple lines), what is the best way to extract a plain string for the `/Title`?
   - RESOLVED: Recommendation: If `outline` is a string (e.g., `outline: "My Section"`), use it literally. If `outline: true`, implement a simple text extraction protocol for `Rendro.Text`/`MeasuredText` content.
