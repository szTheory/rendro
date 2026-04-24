<!-- gsd-project-start source:PROJECT.md -->
## Project

Rendro is a pure-Elixir, Phoenix-first PDF/document generation library focused on deterministic layout and pagination, production-grade observability, and truthful scope boundaries.

Core value: Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components with clear pagination behavior and operational trust.
<!-- gsd-project-end -->

<!-- gsd-stack-start source:STACK.md -->
## Technology Stack

- Elixir 1.19.5 + OTP 28 for core runtime
- Optional adapters: Phoenix 1.8.5, Oban 2.21.1
- Telemetry 1.4.1 for lifecycle instrumentation
- Quality tooling: stream_data 1.3.0, credo 1.7.17, dialyxir 1.4.7, ex_doc 0.40.1
<!-- gsd-stack-end -->

<!-- gsd-conventions-start source:CONVENTIONS.md -->
## Conventions

- Keep `rendro` core pure: no hard dependency on Phoenix, Oban, or admin tooling.
- Preserve deterministic and advisory verification lane separation in CI and docs.
- Treat documentation claims as contracts; do not claim unsupported capabilities.
- Prefer optional dependency guards (`optional: true` + compile/runtime checks) for integrations.
<!-- gsd-conventions-end -->

<!-- gsd-architecture-start source:ARCHITECTURE.md -->
## Architecture

- Data-first pipeline: `build -> compose -> measure -> paginate -> render -> validate`.
- Two APIs, one engine: fixed-position API and flow API both normalize into one render core.
- Optional adapter packages consume core APIs; core never depends on adapter packages.
- Errors and telemetry are part of product behavior, not post-hoc instrumentation.
<!-- gsd-architecture-end -->

<!-- gsd-skills-start source:skills/ -->
## Project Skills

No project-local custom skills yet.
<!-- gsd-skills-end -->

<!-- gsd-workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using file-changing tools, start through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes and ad-hoc updates
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly requests bypass.
<!-- gsd-workflow-end -->

<!-- gsd-profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` and should not be edited manually.
<!-- gsd-profile-end -->
