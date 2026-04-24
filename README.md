# Rendro

Pure-Elixir PDF generation.

## Usage

```elixir
doc = Rendro.flow([
  Rendro.block(Rendro.text("Hello World"))
])

{:ok, pdf} = Rendro.render(doc)
```

## Deterministic Mode

```elixir
doc = Rendro.flow([Rendro.block(Rendro.text("Hello"))])
{:ok, pdf} = Rendro.render(doc, deterministic: true)
```
