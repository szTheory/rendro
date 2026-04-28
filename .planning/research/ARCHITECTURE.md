# Research: Architecture for v1.1 Layout Authoring Maturity

## Existing Architecture Truth

Rendro already has the correct high-level pipeline:

`build -> compose -> measure -> paginate -> render -> validate`

The architectural issue is not the pipeline order. The issue is that the layout data flowing through it is still too thin and too dependent on fixed assumptions.

## Recommended Architecture Direction

### 1. Strengthen the Authoring Model

Expand the document/layout structs so authored intent is explicit:

- flow page templates
- anchored page regions
- sections or bounded layout regions
- keep/break directives
- table split policy

This should be modeled as data consumed by the existing pipeline, not as side-channel options.

### 2. Separate Measured Layout From Authored Input

`Measure` should produce deterministic measured-layout results that `Paginate` can consume directly. Avoid mixing authored input, calculated dimensions, and page-assignment logic in one step.

### 3. Keep One Engine For Fixed and Flow APIs

Fixed-position and flow documents should continue to share the same core pipeline. v1.1 should make fit validation truthful for fixed pages while improving flow semantics, not create separate rendering behavior.

### 4. Treat Diagnostics As Engine Output

Break reasons, overflow reasons, and fit failures should be preserved as stable structured metadata so later async and trust milestones can expose them without reverse-engineering raw PDF output.

## Build Order Recommendation

1. Document/page/region contract
2. Measurement contract
3. Break semantics
4. Table behavior
5. Diagnostics and proof surface
6. Recipes/examples uplift
