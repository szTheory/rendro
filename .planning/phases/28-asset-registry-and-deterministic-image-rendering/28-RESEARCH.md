# Phase 28 Research: Asset Registry & Deterministic Image Rendering

## Ecosystem Context & Tradeoffs

This research evaluates the optimal architecture for handling images and graphical assets in Rendro, evaluated strictly against its core tenets: pure-functional design, deterministic layout execution, and high observability without runtime side effects.

### 1. Asset Registration Location
**Evaluated Approaches:**
*   **Global/Application-Level Registry (`Agent`, `ets`):**
    *   *Pros:* Authoring is simple; assets are declared once globally.
    *   *Cons:* Introduces hidden state. Breaks concurrency and parallel testing. Anti-pattern in Elixir.
*   **Pipeline Option Map (`opts[:assets]` passed to pipeline):**
    *   *Pros:* Keeps the core document struct small.
    *   *Cons:* Fragments the domain model. `Rendro.Document` is no longer a complete, serializable representation.
*   **On the `Rendro.Document` struct (Alongside `FontRegistry`):**
    *   *Pros:* The document acts as an immutable, portable state container (akin to `Plug.Conn`). The source of truth is explicit.

**Recommendation:** A document-bound `AssetRegistry`. Assets must be registered directly onto the `Rendro.Document` struct via a dedicated `Rendro.AssetRegistry`. By enforcing registration at the document boundary, Rendro can validate binaries, extract metadata (mime type, intrinsic dimensions), and cache them upfront. The layout engine later simply queries the pure data structure.

### 2. Authoring API
**Evaluated Approaches:**
*   **Dedicated `Rendro.Image` struct with block duplication:** Requires duplicating the entire box-model implementation (margins, breaks) that already exists for blocks.
*   **Injecting into `Rendro.Block{content: %Rendro.Image{}}`:** Reuses the existing robust box-model and layout flow engine.

**Recommendation:** A semantic `Rendro.image/2` component helper. The authoring API should use a helper function that returns a standard `Rendro.Block`, but with an internal content shape of `%Rendro.Image{logical_name: :logo_primary}` that references the *logical name* from the `AssetRegistry`. The AST declares *intent*, while the `AssetRegistry` holds the *payload*.

### 3. Image Sizing and Bounds
**Evaluated Approaches:**
*   **Implicit Sizing (Extract dimensions dynamically during layout):** Requires binary parsing inside the pure `measure` pipeline phase, causing non-deterministic slowdowns and masking errors during pagination.
*   **Required Explicit Width and Height:** Absolute determinism, but terrible developer ergonomics (manual aspect ratio calculation).
*   **Explicit Constraint + Calculated Aspect Ratio:** Developer provides one constraint (`width`, `height`, or a bounding box `fit: {w, h}`), and the engine calculates the missing dimension using the image's intrinsic aspect ratio.

**Recommendation:** Boundary Parsing & Constraint-Based Layout.
1. Extract Intrinsic Bounds at Registration: When `Document.register_image/2` is called, Rendro parses the image header (using pure Elixir binary pattern matching) to determine its intrinsic width and height, storing them in the `AssetRegistry`.
2. Require Constraint: The `Rendro.Image` struct should require either `width`, `height`, or `fit` bounding box constraint.
3. Pure Measurement: During the `measure` phase, the engine reads the constraint from the `Image` struct, looks up the intrinsic aspect ratio from the `AssetRegistry`, and deterministically calculates the final `Block` box dimensions in microseconds.