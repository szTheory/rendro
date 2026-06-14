# Rendro Voice System

> Render the document. Respect the system. Explain the failure.

This is the operating manual for how Rendro sounds — in docs, errors, the README, release notes, the landing page, and every issue reply. It refines and consolidates the brand book (sections 4, 15, 16, 17, 18, 19, 22). When this file and the brand book agree, follow the brand book. When this file is more specific, follow this file.

Personality formula: **70% senior open-source maintainer, 20% typographer, 10% SRE.**

---

## 1. Voice principles

Each principle has a one-line rule and the reason it earns its place.

1. **Lead with the concrete.**
   Name the thing — a region, a block, a page, a byte count — before any adjective. *Why:* our readers are engineers debugging real documents; specificity is the value, vagueness is noise.

2. **Be honest about limits, in the same breath as the capability.**
   If we say what Rendro does, we say where it stops. *Why:* the name collides with a commercial PDF SDK and the category is full of overclaiming. Stated limits are the most credible thing we can publish.

3. **Explain the failure; never just flag it.**
   Every error answers what / where / why / what next. *Why:* "Layout failed." costs the developer an hour. "Row 47 needs 42pt, 18pt remain — allow row splitting" costs them a minute.

4. **Sound like a maintainer, not a marketer.**
   Calm, declarative, no exclamation points outside genuine success states. *Why:* the audience trusts peers over pitches. Confidence comes from precision, not volume.

5. **Show the code next to the claim.**
   Prefer a working snippet over an adjective. *Why:* "composable" means nothing until they see a `|>` pipeline return a `%Rendro.Document{}`.

6. **Respect the reader's time and intelligence.**
   Short sentences, task-shaped headings, no throat-clearing. Assume they know Elixir. *Why:* condescension and filler both waste the one resource a senior dev guards.

7. **Stay observable.**
   Talk about production the way an SRE does: telemetry, duration, page count, byte size, document hash, warnings. *Why:* "Production is a feature." Day-2 operations are a differentiator, so we name them.

8. **No magic, ever.**
   Nothing "just works," nothing is "seamless," nothing happens "under the hood." Describe the mechanism instead. *Why:* magic is the opposite of inspectable, and inspectable is the whole pitch.

---

## 2. Tone sliders

Where Rendro sits on each axis, and why.

```
Formal        |---------●-----------|  Casual
              (slightly toward formal: precise, but a peer, not a vendor)

Terse         |------●--------------|  Expansive
              (toward terse: short by default; expand only for tradeoffs)

Serious       |--------●------------|  Playful
              (mostly serious; dry wit allowed in prose, NEVER in errors)

Plain         |--------------●------|  Technical
              (toward technical: uses real Elixir/PDF vocabulary, unapologetically)

Reassuring    |-----------●---------|  Blunt
              (toward blunt: states limits and failures plainly; warmth is in usefulness, not softness)

Humble        |--------●------------|  Confident
              (confident about what's verified; humble about what isn't)
```

Rule of thumb: when in doubt, move one notch toward terse, technical, and honest.

---

## 3. Tone by context

| Context | Tone | What it means in practice |
|---|---|---|
| Landing page | Confident, concise | Lead with the tagline and a real snippet. One claim per section, each provable. |
| Docs | Direct, example-led | Every guide: working code → rendered result → primitives → common failure → production note. |
| Error messages | Specific, calm, actionable | What / where / why / what next. No jokes, no blame, no "oops." |
| Release notes | Transparent, factual | Past tense, grouped by Added / Changed / Fixed. Name breaking changes first. |
| GitHub issues | Respectful, maintainer-aware | Thank the reporter, restate the problem, give a next step or an honest "won't fix, here's why." |
| Admin / LiveView UI | Operational, low-noise | Labels over sentences: `A4 · Page 2 of 5`, `Render duration: 38ms`. Inspection over decoration. |
| Community (Discord, forum) | Warm, practical, open | Plain help, no gatekeeping. Point to docs, then to the relevant module. |
| Changelog one-liners | Factual, scannable | `Added repeating table headers for paginated reports.` Verb first, no fluff. |

---

## 4. Vocabulary

### Use

**Identity:** native, pure-Elixir, open-source, PDF layout library, document components, Phoenix-first, BEAM.

**Mechanism:** composable, deterministic, explicit, structured, region, frame, block, section, page template, flow, fixed-position, pagination, page break, render plan, layout engine, document AST.

**Operations:** telemetry, diagnostics, render duration, page count, byte size, document hash, warning, policy, bounded, validation, fixture, snapshot test.

**Action verbs:** render, build, compose, measure, paginate, embed, inspect, validate, emit, return, fail when, try.

### Avoid

**Hype / magic:** magic, magical, seamless, effortless, just works, blazing-fast, revolutionary, game-changing, simply, easily, instantly.

**Wrong category (the CHILI/SDK collision):** SDK, viewer, prepress, high-res rendering, online PDF rendering, browser-based, headless, screenshot, print pipeline, chili, pepper, spice, 3D, hot-sauce.

**Scope we don't own:** pixel-perfect, HTML-to-PDF, CSS cascade, browser automation, wkhtmltopdf-compatible.

**Overclaims:** PDF/A compliant, PDF/UA accessible, digitally signed, certified, guaranteed — unless a specific validated capability backs the exact word, in which case state the validation.

**Filler:** under the hood, behind the scenes, you might want to maybe, it should probably, robust, powerful, cutting-edge, leverage, utilize (say "use").

---

## 5. Writing rules

1. **Lead with the verb.** "Render an invoice in 15 minutes," not "It is possible to render…".
2. **Name the failure and the fix together.** Never describe a problem without a next step.
3. **One claim per sentence; each claim provable.** If you can't link a snippet, test, or telemetry event to it, cut it.
4. **State the limit beside the feature.** "Tables repeat headers across pages. Rows do not split — a row taller than the region raises a layout error."
5. **Use real identifiers.** Write `%Rendro.Document{}`, `Rendro.flow/2`, `:body` region — not "the document object."
6. **Past tense for errors and release notes; imperative for instructions.** "Row overflowed the body frame." / "Allow row splitting."
7. **Numbers over adjectives.** "18pt available, 42pt required," not "not enough room."
8. **Cut every "simply," "just," and "easily."** They lie about difficulty and patronize the reader.
9. **No exclamation points** except in a genuine success state, and even then sparingly.
10. **Title case the brand in prose (`Rendro`); lowercase for package, config, and module-prefix technical refs (`rendro`).**

---

## 6. Say this / not this

**Marketing**

| Say this | Not this |
|---|---|
| Native PDF layout for Elixir. Build documents as composable data and render them without Chrome. | Generate perfect PDFs instantly with magical browserless rendering. |
| Same input, same bytes — deterministic output you can snapshot-test. | Pixel-perfect PDFs, every time. |
| Telemetry for every render: duration, page count, byte size, warnings. | Powerful production-grade observability built right in. |

**Docs**

| Say this | Not this |
|---|---|
| `Rendro.render/1` returns `{:ok, pdf}` or `{:error, reason}`. It does not raise on layout overflow. | This call magically handles all your rendering needs. |
| Tables require explicit `columns:` rules. There is no content-based auto-sizing. | Tables just figure out the right widths for you. |

**Errors**

| Say this | Not this |
|---|---|
| Table row could not fit the remaining body space. Allow row splitting or start the row on a new page. | Layout failed. |
| Rendro does not render arbitrary HTML/CSS. Use document components, or choose an HTML-to-PDF renderer when CSS fidelity is the goal. | Rendro replaces every PDF tool you'll ever need. |

---

## 7. Microcopy system

### 7.1 Error message pattern

Every developer-facing error answers four questions, in order:

1. **What happened** — one declarative sentence, past tense.
2. **Where** — template / region / block path, and the measurements involved.
3. **Why** — the rule or constraint that was violated.
4. **What to try next** — one or more concrete fixes, imperative.

**Worked example A — row overflow**

```
Table row could not fit the remaining body space.
  Template: MyApp.PDF.Invoice
  Region:   :body
  Block:    document.body.table[2].row[47]
  Available height: 18pt
  Required height:  42pt
Rendro table rows are atomic and do not split across pages.
Try one of: start the row on a new page, reduce cell padding,
or shorten the cell content.
```

**Worked example B — unsupported input**

```
Cannot render arbitrary HTML/CSS.
  Call:  Rendro.render/1
  Input: a string beginning with "<html>"
Rendro builds PDFs from document components, not from HTML or CSS.
Try one of: compose the document with Rendro.flow/2 and Rendro.block/2,
or use an HTML-to-PDF renderer when CSS fidelity is the goal.
```

### 7.2 Empty-state pattern

**Pattern:** Name what is absent → say what creates it → (optional) the one action that gets there.

- **No render artifacts yet.** Generate a sample PDF to inspect page count, byte size, document hash, and warnings. → *Generate sample*
- **No validation report.** Run validation to check document structure and common output issues before you ship. → *Run validation*

### 7.3 Success-state pattern

**Pattern:** Confirm the outcome → attach the operational facts (duration, pages, bytes, hash) → next step if there is one.

- **Render complete.** 5 pages · 48.2 KB · 38ms · `sha256:a9f1a2…dc94`. → *Download PDF*
- **Validation passed.** No structural issues found across 5 pages. 2 layout warnings — review before publishing. → *View warnings*

### 7.4 Status messages

Present continuous, one per pipeline stage, no ellipsis-as-personality:

```
Building document
Measuring layout
Paginating pages
Embedding fonts
Decoding image
Rendering PDF
Validating output
Uploading artifact
Render complete
```

Warning and error labels for inline UI: `Layout warning`, `Overflow`, `Missing font`, `Asset not found`, `Policy exceeded`.
