# Ticket — Domain Anatomy

Domain-research notes for the ticket example family. This document captures the
language, readers, reading situations, and layout conventions that a faithful
ticket must honor. It is cited by rubric-scored demos (SHOW-01) so that scoring
is anchored to how tickets are actually read and used — not to generic
document-formatting taste.

## Domain Language

The vocabulary a reader expects a ticket to speak. Missing or renamed terms
make a document read as "not really a ticket."

**Nouns (the things on the page)**

- **Ticket** — the document itself; an admission credential that grants a named holder
  entry to an event, a journey, or a venue.
- **Issuer** — the party granting admission: a venue, promoter, or carrier.
- **Event / title** — what the ticket admits to, e.g. a show, a match, or a flight.
- **Subtitle** — supporting detail: doors/show times, date, or route.
- **Placement** — the ordered locator that tells the holder where they go: Section /
  Row / Seat for an event, or Gate / Seat / Group for a boarding pass. The anchor.
- **Reference / code** — the unique, scannable-or-quotable identifier that validates the
  ticket at the point of entry.
- **Stub** — the tear-off or bordered portion carrying the code and placement, retained
  or scanned at the gate.
- **Terms** — the fine print: non-transferable, no refunds, ID may be required.

**Verbs and events (the lifecycle)**

- **Issue** — the issuer sells or grants the ticket to the holder.
- **Present** — the holder shows the ticket at the point of entry.
- **Scan / validate** — the gate confirms the reference is genuine and unused.
- **Admit** — the holder is let in and directed to their placement.
- **Void / expire** — the ticket is used, cancelled, or its event passes.

## Personas & Jobs-to-be-Done

Who reads a ticket, why, and — critically — the ONE fact each reader needs first.

- **Ticket holder — primary reader.** Uses the ticket to get in and find their place.
  Their job is: get through the gate and to my spot. The ONE fact they need first is
  their **placement** (seat / gate / section) — where do I go? — with the event title and
  time as immediate orientation.

- **Gate agent / scanner — secondary reader.** Validates the ticket at entry, often in a
  fast-moving line. Their job is: confirm this ticket is valid, now. They need the
  **reference / code** to be immediately locatable and machine- or eye-readable, and the
  event and date to confirm the holder is at the right place at the right time.

- **Purchaser / gift recipient — tertiary reader.** Reads the ticket ahead of the event
  to plan. Their job is: know what, where, and when. They lean on the **title**,
  **subtitle** (date and times), and **placement** to prepare for the day.

## Reading Context

The situations in which tickets are actually read — which drive what must survive.

- The **critical read happens at the gate, in seconds, often in a crowd**: the holder
  finds their placement and the agent finds the code under time pressure.
- Tickets are **small-format and physical as often as on-screen** (A6 slips, phone
  screens), so everything essential must fit a small page and survive both.
- A **planning read** happens well before the event, when the holder checks the date,
  time, and location, so those must be legible calmly and in advance.
- Tickets must **read correctly without color or interactivity** — a printed or
  screenshotted ticket at a dim gate must still surface the placement and code.

## Layout & Typographic Conventions

The visual grammar that makes a document read as a trustworthy ticket.

- **The placement is the single most visually prominent element** — Section/Row/Seat (or
  Gate/Seat/Group) rendered in the largest type, laid out as an ordered grid so the
  holder finds their spot in the first glance.
- **The event title and time sit clearly at the top**, orienting the holder to what and
  when before they reach the placement.
- **The reference / code lives in a bordered code area on the stub**, always shown as a
  human-readable string even when a scannable image is present — never a faux barcode.
- **A visible seam or perforation separates the main body from the stub**, so the ticket
  reads as a ticket and the stub is clearly the part retained or scanned.
- **The ticket occupies a fixed band anchored at the top of the page**, a compact
  landscape shape echoing physical tickets, with optional terms flowing below.
- **The fine-print terms are set small and subordinate**, present for validity but never
  competing with the placement or the code for the reader's attention.
