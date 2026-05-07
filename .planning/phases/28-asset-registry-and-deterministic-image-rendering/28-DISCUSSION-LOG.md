# Phase 28 Discussion & Decisions

**Goal**: Add first-class bounded asset support for logos and document imagery without introducing runtime fetch policy into core.

## Alignment Achieved

Based on deep ecosystem research and Rendro's pure-core, deterministic DNA, we have aligned on the following cohesive architectural direction for Asset Registration and Rendering.

### 1. Asset Registration (The `AssetRegistry`)
**Decision:** Assets will be registered directly onto the `Rendro.Document` struct via a dedicated `Rendro.AssetRegistry`.
**Rationale:** This preserves the document as an immutable, portable state container (akin to `Plug.Conn`), avoiding global state (anti-pattern) and pipeline-opts fragmentation. By registering at the document boundary, Rendro validates binaries, extracts metadata (intrinsic dimensions), and caches them upfront before layout begins.

### 2. Authoring API (`Rendro.image/2`)
**Decision:** Developers will author images via a semantic `Rendro.image(logical_name, opts)` function, which produces a `Rendro.Block` containing `%Rendro.Image{logical_name: logical_name, width: w, height: h, fit: fit}`.
**Rationale:** This reuses the existing robust box-model (keep/break semantics, positioning) and keeps the AST small by not duplicating raw image binaries in the tree. The AST declares *intent*, while the registry holds the *payload*.

### 3. Image Sizing and Deterministic Bounds
**Decision:** Image registration will proactively extract intrinsic bounds via pure binary parsing. The authoring API will allow an explicit `width`, `height`, or a `fit: {w, h}` constraint. The `measure` phase will calculate the final box using the pre-computed intrinsic aspect ratio.
**Decision:** If no sizing constraints are provided, we will require at least one constraint (fail fast), or default to intrinsic if requested, but requiring at least one constraint guarantees deterministic bounds suitable for branded business documents without CLS equivalents.
**Rationale:** Prevents layout jumps or nondeterminism. The `measure` and `paginate` phases remain pure math and operate in microseconds without needing to parse image binaries or perform I/O during layout execution.

### 4. Runtime Fetch Policy
**Decision:** Only local or in-memory (binary) assets are supported in core (as per `ASSET-01`). Remote URL fetching is an adapter-level concern and will not be introduced into the pure core layout engine.
**Rationale:** Preserves the hard architectural boundary of deterministic execution and avoids introducing runtime HTTP policy into the PDF generation pipeline.

---
_Decisions synthesized autonomously based on preferred GSD guidance and deep ecosystem research. The discussion tree is complete and fully resolved._