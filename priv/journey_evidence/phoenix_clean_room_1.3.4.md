# Phoenix clean-room advisory success — Rendro 1.3.4

The refreshed accepted advisory run resolved exact public Rendro `1.3.4`, bound
to candidate `f03c78bab54efe1cd1596d51cf3f28193232e2a3` and current prerequisite
SHA `eba7b5003ad35830a44723d6e3e6ec4adfb59ce9586b17f67c4c5c1cc39f84b8`.
That prerequisite records the successful HexDocs `workflow_dispatch` run
`32898926521`, control SHA `f9b63246029396f76c443c5750aad42a3004081b`, and
its candidate binding.

The isolated consumer installed Phoenix `1.8.13`, Plug `1.20.3`, Bandit
`1.12.5`, and Phoenix installer `1.8.5` in run-scoped state. It generated the
formatter-owned Invoice / Swiss / `#2C6BED` / light document and served it
through `Rendro.Adapters.Phoenix`. The stages were installer acquisition,
Phoenix generation, dependency resolution, ConnCase, compilation, endpoint
start, and loopback HTTP probe. ConnCase ran first; both paths observed HTTP
200, `application/pdf`, attachment `invoice.pdf`, nonempty content, and PDF
magic. The disposable application, dependency/cache/build state, process
state, lock, and payload were removed after the bounded result projection.

The launcher was invoked through the harness's public `main/1` entrypoint so
the proof executes even when `mix run` has an ExUnit server. Retained failed
attempts remain under explicit `*_failed_attempt` names. If a future live run
cannot resolve the exact public package, validate its prerequisite, or produce
both matching HTTP facts, retain a bounded failed attempt and do not replace
this advisory success. No paths, ports, PIDs, bodies, caches, headers, tokens,
secrets, or generated payloads are retained.
