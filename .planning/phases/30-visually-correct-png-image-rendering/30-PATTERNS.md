# Phase 30: Visually Correct PNG Image Rendering - Pattern Map

**Mapped:** 2024-05-02
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/pdf/writer.ex` | component | transform | `lib/rendro/pdf/writer.ex` (existing) | exact |
| `lib/rendro/pdf/png.ex` | utility/parser | transform | `lib/rendro/image_parser.ex` | role-match |
| `test/rendro/pdf/writer_test.exs` | test | N/A | `test/docs_contract/branding_claims_test.exs` | partial-match |

## Pattern Assignments

### `lib/rendro/pdf/writer.ex` (component, transform)

**Analog:** `lib/rendro/pdf/writer.ex`

**Core Image Object Pattern** (lines 253-266):
```elixir
  defp build_image_object(%{image: %{mime: "image/jpeg"} = image, obj_num: obj_num}, opts) do
    entries = [
      {"Type", {:name, "XObject"}},
      {"Subtype", {:name, "Image"}},
      {"Width", image.width},
      {"Height", image.height},
      {"ColorSpace", {:name, "DeviceRGB"}},
      {"BitsPerComponent", 8},
      {"Filter", {:name, "DCTDecode"}}
    ]

    stream = {:stream, entries, image.binary}
    [{obj_num, Object.indirect_object(obj_num, 0, Object.serialize(stream, opts))}]
  end
```

### `lib/rendro/pdf/png.ex` (utility/parser, transform)

**Analog:** `lib/rendro/image_parser.ex`

**Binary Pattern Matching (IHDR extraction)** (lines 19-33):
```elixir
  def parse(
        <<@png_signature, _length::32, "IHDR", width::32, height::32, bit_depth::8, color_type::8,
          _comp::8, _filter::8, interlace::8, _crc::32, _rest::binary>>
      ) do
    {:ok,
     %{
       width: width,
       height: height,
       mime: "image/png",
       bit_depth: bit_depth,
       color_type: color_type,
       interlace: interlace
     }}
  end
```

### `test/rendro/pdf/writer_test.exs` (test)

**Analog:** `test/docs_contract/branding_claims_test.exs`

**System Command Execution Pattern** (lines 46-51):
```elixir
      {output, 0} = System.cmd("mix", ["hex.build"], stderr_to_stdout: true)
      assert output =~ tarball
      assert File.exists?(tarball)

      list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
      {contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)
```

## Shared Patterns

### External Command Execution
**Source:** `test/docs_contract/branding_claims_test.exs`
**Apply to:** New rasterize-and-decode test regression class
```elixir
{output, exit_status} = System.cmd("command", ["arg1", "arg2"], stderr_to_stdout: true)
```

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | N/A | N/A | All requested patterns matched |

## Metadata

**Analog search scope:** `lib/rendro/**/*.ex`, `test/**/*.exs`
**Files scanned:** 3
**Pattern extraction date:** 2024-05-02
