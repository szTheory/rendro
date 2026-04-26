---
phase: 05
slug: early-ecosystem-recipes
status: verified
threats_open: 0
threats_closed: 13
asvs_level: 1
created: 2026-04-26
---

# Phase 05 — Early Ecosystem Recipes — Security Audit

**Phase:** 05 — early-ecosystem-recipes
**ASVS Level:** L1
**Block on:** high
**Threats Closed:** 13 / 13
**Threats Open:** 0
**Audit Date:** 2026-04-26

---

## Summary

All 13 declared threats across the four sub-plans (05-01, 05-02, 05-03, 05-04)
are **CLOSED**. Nine `mitigate`-disposition threats were verified by locating
the specific code/text artifact implementing the mitigation in the cited
implementation file. Four `accept`-disposition threats were validated as
plausible — i.e. the implementation behavior is consistent with the accepted
risk description.

No new attack surface (`unregistered_flag`) was reported in any of the four
SUMMARY files (`## Threat Flags` sections all read "None").

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Rendro → Threadline | Telemetry-driven audit handler emits `track_render/2` calls | Render metadata (allowlisted keys: `:render_id`, `:status`, `:page_count`, `:byte_size`, `:duration`, etc.) — no document body, no binary |
| Rendro → Swoosh / Mailglass | `Rendro.Adapters.Mailglass.attach_pdf/3` attaches a rendered PDF binary to a caller-supplied email or message wrapper | Rendered PDF bytes (size-bounded by `Rendro.render/1` policies) |
| Caller → `Rendro.Adapters.Accrue` | Caller passes `%Accrue.Invoice{}` to `recipe/1`, which constructs a `%Rendro.Document{}` | Invoice fields (`:id`, `:issued_at`, `:customer.name`, `:line_items.*`, `:total`) |
| Caller → `Rendro.Adapters.Mailglass.attach_pdf/3` | Caller passes an email/message wrapper for attachment | Untrusted email-or-message struct, PDF binary |
| Rendro maintainer → public docs (`guides/integrations.md`) | Documentation claims become a contract for adapter behavior | Error-tuple atoms, audit-coverage statements, code samples |

---

## Threat Verification

### Mitigated threats (9)

| Threat ID    | Category               | Component                    | File:Line                                              | Evidence Excerpt |
|--------------|------------------------|------------------------------|--------------------------------------------------------|------------------|
| T-05-01      | Information Disclosure | Threadline Adapter           | lib/rendro/adapters/threadline.ex:101-115              | `build_audit_metadata/2` calls `Map.take([:render_id, :stage, :status, :page_count, :byte_size, :document_type, :deterministic, :kind, :reason])` then `Map.put(:duration, ...)` — fixed allowlist, no document body or binary forwarded. |
| T-05-02      | Denial of Service      | Mailglass Helper             | lib/rendro/adapters/mailglass.ex:62-68                 | `attach_pdf/3` invokes `Rendro.render(document)` (line 64); render-policy enforcement (`:max_pages`, `:max_bytes`, `:timeout`) lives in `Rendro.render/1` and is not bypassed — failures propagate via `{:error, _} = err -> err`. |
| T-05-02-01   | Tampering              | Accrue.recipe/1 input        | lib/rendro/adapters/accrue.ex:44, 58                   | Public clause `def recipe(%Accrue.Invoice{} = invoice)` (line 44) and fall-through `def recipe(other), do: {:error, {:invalid_invoice, other}}` (line 58). |
| T-05-02-03   | Denial of Service      | Large `:line_items` list     | lib/rendro/adapters/accrue.ex:44-56, moduledoc 33-39   | Recipe returns `{:ok, doc}` (line 55); does NOT call `Rendro.render/1`. Moduledoc states: "render-time policies (max pages/bytes/timeout) and error tuples flow through the normal pipeline." |
| T-05-03-01   | Tampering              | extract_swoosh/1 fallback    | lib/rendro/adapters/mailglass.ex:120-126               | `defp extract_swoosh(other) when is_struct(other), do: {:error, {:unrecognized_message_shape, other.__struct__}}` and the bare-other catchall both return `{:error, {:unrecognized_message_shape, _}}`. The previous `do: %Swoosh.Email{}` silent-fabrication clause is GONE. |
| T-05-03-02   | Denial of Service      | attach_binary/3 `true ->` arm | lib/rendro/adapters/mailglass.ex:80-83                 | `true -> {:error, Rendro.Error.from_stage(:render, {:invalid_email_target, email_or_message}, %{})}` — replaces the prior raising `Swoosh.Email.attachment(email_or_message, attachment)` call. |
| T-05-03-03   | Spoofing               | mailglass_message?/1         | lib/rendro/adapters/mailglass.ex:93-104                | Narrowed: explicit `defp mailglass_message?(%Mailglass.Message{}), do: true`, then `is_struct(value)` check requiring `String.ends_with?(".Message")` AND `function_exported?(mod, :update_swoosh, 2)`. The over-broad `String.starts_with?(mod_str, "Elixir.Mailglass.")` test is removed. |
| T-05-04-01   | Repudiation            | Doc audit-coverage overstate | guides/integrations.md:122                             | Verbatim sentence present: "Render timeouts enforced by `Rendro.Pipeline.run/1` are NOT currently audited by `Rendro.Adapters.Threadline`." Heading "Known limitation: pipeline timeouts are not audited" at line 120. |
| T-05-04-02   | Tampering              | Doc/source drift             | guides/integrations.md:244, 245, 337                   | `{:invalid_email_target,` (line 244), `{:unrecognized_message_shape,` (line 245), `{:invalid_invoice,` (line 337) — all three required atoms are present in the integration guide and match the implementation. |

### Accepted threats (4)

| Threat ID    | Category               | Component                                | Evidence consistent with accept disposition |
|--------------|------------------------|------------------------------------------|---------------------------------------------|
| T-05-02-02   | Information Disclosure | Accrue.Invoice fields rendered           | lib/rendro/adapters/accrue.ex:60-99 — recipe reads only `:id`, `:issued_at`, `:customer.name`, `:line_items.{description, quantity, unit_amount, subtotal}`, `:total`. Each value is stringified through `to_string/1` (lines 72-75) or interpolation (lines 62-64, 86, 91). No keys outside the documented set are read. Caller-supplied invoice — opt-in render decision. |
| T-05-02-04   | Repudiation            | Audit trail for Accrue renders           | lib/rendro/adapters/threadline.ex:44-47, 73-82 — Threadline handler subscribes to `[:rendro, :render, :stop]` and `[:rendro, :render, :exception]` regardless of recipe origin. Accrue-driven renders flow through the same `Rendro.render/1` path and are audited identically. |
| T-05-03-04   | Information Disclosure | Error tuple includes user term           | lib/rendro/adapters/mailglass.ex:80-83 — `{:invalid_email_target, email_or_message}` echoes the caller's input. Caller already possesses the value; echo is intentional debugging aid. Documented in moduledoc lines 29-33 ("`value` echoes back the caller's input"). |
| T-05-04-03   | Information Disclosure | Code samples in guide                    | guides/integrations.md:184 (`"customer@example.test"`), 312 (`"INV-001"`), 314 (`"Acme Corp"`), 316 (`"Widget"`) — all synthetic. No real customer addresses, real invoice ids, API keys, secrets, tokens, or PII. |

---

## Unregistered Flags

None.

All four phase SUMMARY files explicitly state `## Threat Flags: None` (or
equivalent). No new attack surface emerged during implementation that lacks
threat-register coverage.

- 05-01-SUMMARY.md `## Threat Surface Recap` — both T-05-01 and T-05-02 mitigated; "No new threat surface emerged outside the plan's threat model."
- 05-02-SUMMARY.md `## Threat Surface Scan` — "No new security-relevant surface introduced beyond what the plan's threat model documented."
- 05-03-SUMMARY.md `## Threat Flags` — "None. All threat register items (T-05-03-01 through T-05-03-04) from the plan were mitigated as designed."
- 05-04-SUMMARY.md `## Threat Flags` — "None. All three threat register items from the plan were addressed."

---

## Accepted Risks Log

The four `accept`-disposition threats above constitute the recorded accepted
risks for Phase 05. They are accepted because:

1. **T-05-02-02** — Caller-controlled opt-in. The Accrue recipe does not exfiltrate; it transforms a caller-supplied invoice into a document the caller asked to be built. Field set is documented and minimal.
2. **T-05-02-04** — Existing Threadline adapter audits at the render boundary, not at the recipe boundary; no per-recipe audit hook is needed.
3. **T-05-03-04** — Echoing the caller's own input back to them in an error tuple does not disclose anything they don't already have.
4. **T-05-04-03** — All code samples in `guides/integrations.md` use synthetic identifiers and `*.test` TLD addresses (RFC 6761 reserved); no real-world secret-shaped data is present.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-26 | 13 | 13 | 0 | gsd-security-auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log (4 risks: T-05-02-02, T-05-02-04, T-05-03-04, T-05-04-03)
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-26

---

## Audit Methodology

For each `mitigate` threat, the audit:

1. Identified the cited implementation file from the threat's mitigation plan.
2. Read the relevant code region.
3. Located the specific construct (function clause, `cond` arm, `Map.take`, allowlist, etc.) implementing the mitigation.
4. Quoted the file path and line number with a short evidence excerpt above.

For each `accept` threat, the audit verified that the implementation behavior
is consistent with the accept disposition's claim (e.g. the echo really
happens; only documented fields are read; synthetic data is really used).

Implementation files were treated as READ-ONLY. No source code was modified
during this audit.

---

## Files Inspected

- lib/rendro/audit.ex
- lib/rendro/adapters/threadline.ex
- lib/rendro/adapters/mailglass.ex
- lib/rendro/adapters/accrue.ex
- guides/integrations.md
- mix.exs
- README.md
- .planning/phases/05-early-ecosystem-recipes/05-01-PLAN.md
- .planning/phases/05-early-ecosystem-recipes/05-02-PLAN.md
- .planning/phases/05-early-ecosystem-recipes/05-03-PLAN.md
- .planning/phases/05-early-ecosystem-recipes/05-04-PLAN.md
- .planning/phases/05-early-ecosystem-recipes/05-01-SUMMARY.md
- .planning/phases/05-early-ecosystem-recipes/05-02-SUMMARY.md
- .planning/phases/05-early-ecosystem-recipes/05-03-SUMMARY.md
- .planning/phases/05-early-ecosystem-recipes/05-04-SUMMARY.md
