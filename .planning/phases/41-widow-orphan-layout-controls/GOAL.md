# S01: Widow/Orphan Layout Controls

## Goal
Implement predictive line splitting for text blocks across page boundaries. A multi-line text block must break cleanly without leaving solitary lines (widows/orphans), respecting typographic constraints.

## Architecture & Decisions

### Schema Strategy: Content over Container
- `widows` and `orphans` are typographic properties of the content, not the layout container.
- We add `widows: 2` and `orphans: 2` defaults directly to the `Rendro.Text` struct.
- This prevents applying text-specific logic to incompatible block types (like images) and aligns with the Ecto-style pattern of validating/constraining the specific payload field rather than a generic wrapper.

### Pipeline Flow: Measure -> Paginate
1.  **Measure Phase:** The `Rendro.Text` struct is converted to `Rendro.Pipeline.MeasuredText`. We must pass the `widows` and `orphans` values down into this struct so they are available during pagination.
2.  **Paginate Phase (`Rendro.Pipeline.Paginate`):**
    -   When a `MeasuredText` block's height exceeds the available space (`max_h - current_h`), we calculate how many lines physically fit (`floor(available_h / line_height)`).
    -   We apply a strict enforcer algorithm:
        -   **Check Orphans:** Is `lines_fitting < orphans`? If yes, the split is invalid. Push the *entire block* to the next page.
        -   **Check Widows:** Is `total_lines - lines_fitting < widows`? If yes, reduce `lines_fitting` so enough lines spill over to the next page to satisfy the widow requirement.
        -   **Re-check Orphans:** Did reducing `lines_fitting` push the remaining lines on the current page below the `orphans` threshold? If yes, the split is invalid. Push the *entire block* to the next page.
3.  **AST Mutation:** A valid split transforms a single `%Rendro.Block{content: %MeasuredText{}}` into two distinct `%Rendro.Block{}` structures placed on consecutive pages.

### Protocol Boundary Prep (S02 Alignment)
While S02 will introduce `Rendro.Fragmentable` for recursive splitting, S01 implements text fragmentation via explicit function matching in `paginate.ex` (analogous to the existing `handle_table_split/10`). This isolates the text-splitting math and ensures it's ready to be slotted behind a protocol boundary in the next slice without user-facing schema changes.

## Verification
- Unit tests must prove that a 5-line paragraph with `widows: 2, orphans: 2` correctly shifts lines across boundaries to prevent 1-line breaks.
- Unit tests must prove that if constraints cannot be met (e.g., a 3-line paragraph that fits 2 lines on the current page but needs 2 widows), the entire block is moved to the next page.