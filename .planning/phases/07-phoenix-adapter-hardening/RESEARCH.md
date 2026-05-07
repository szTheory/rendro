# Phase 07: Phoenix Adapter Hardening + Example Skeleton - Research & Assumptions

## Architectural Decisions & Recommendations

Based on deep ecosystem research and the goal of maximizing Developer Experience (DX), adhering to the principle of least surprise, and following Elixir/Phoenix idiomatic practices, we have resolved the following gray areas for Phase 07:

### 1. Dependency Guarding for the Phoenix Adapter
**Decision:** Conditional compilation with a fallback stub.
**Rationale:** We will wrap the real adapter implementation in `if Code.ensure_loaded?(Plug.Conn) do`. If `:plug` is not loaded, we compile a stub module that raises a highly descriptive `RuntimeError` when its functions are called.
**Why this is best:** Implicit compilation (the current state) leads to confusing `CompileError`s. Standard conditional compilation leads to `UndefinedFunctionError`s. A descriptive runtime error explicitly bridges the gap, telling the developer exactly what dependency is missing (`:plug` and `:phoenix`), which is a pattern successfully used in libraries like Oban and Swoosh.

### 2. Error Formatting in the HTTP Response
**Decision:** Implement the `String.Chars` protocol for `Rendro.Error` and return `text/plain`.
**Rationale:** We want to return a great DX in the Phoenix adapter without forcing a JSON library (like `jason`) into Rendro's core dependencies. By implementing `String.Chars` (`to_string/1`) for `%Rendro.Error{}`, we can seamlessly convert the structured error into a beautifully formatted, multi-line string.
**Why this is best:** It requires zero external dependencies. Plain text is perfectly readable by both humans (in the browser or via cURL) and loggers. When a developer breaks the pipeline, the browser will immediately display the actionable `what/where/why/next` context in plain, readable text.

### 3. Example App Server (`examples/phoenix_example`)
**Decision:** Use `bandit` as the web server.
**Rationale:** The skeleton app will use Bandit instead of Cowboy.
**Why this is best:** Bandit is a modern, pure-Elixir HTTP server and the official default web server for Phoenix >= 1.7.2. It avoids Erlang/C compilation steps, reducing friction for developers exploring the example app. It signals that Rendro is a modern, actively maintained library aligned with the current ecosystem.

## Next Steps
These decisions provide a cohesive, idiomatic, and user-friendly foundation for Phase 07. The discuss phase is now complete. 

Proceed to planning via `/gsd-plan-phase 07`.