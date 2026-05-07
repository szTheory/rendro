---
phase: 29
plan: 06
type: execute
wave: 3
depends_on: [05]
files_modified:
  - test/docs_contract/branding_contract_test.exs
  - test/docs_contract/branding_claims_test.exs
autonomous: true
requirements: [QUAL-07]
requirements_addressed: [QUAL-07]

must_haves:
  truths:
    - "branding_contract_test.exs mirrors integrations_contract_test.exs structurally; uses ExUnit.Case async: false; aliases Rendro.Test.DocsContract"
    - "branding_contract_test.exs asserts Enum.map(fences, & &1.id) == [\"branding-register-assets\", \"branding-tiered-document\", \"branding-tiered-template\", \"branding-missing-asset-diagnostic\"] — exact order (D-21)"
    - "branding_contract_test.exs evaluates each fence via DocsContract.evaluate!/2; refutes `...` ellipsis and `%{...}` skeletons in fence bodies"
    - "branding_claims_test.exs asserts File.exists?(\"NOTICE\") AND NOTICE content contains \"SIL OPEN FONT LICENSE Version 1.1\", \"Copyright 2012 The B612 Project Authors\", \"http://scripts.sil.org/OFL\" (D-13)"
    - "branding_claims_test.exs asserts byte_size(File.read!(\"priv/branded/fonts/B612-Regular.ttf\")) == 153_192 — EXACT equality (Pitfall 5; D-08 corrected by RESEARCH.md)"
    - "branding_claims_test.exs asserts byte_size(File.read!(\"priv/branded/images/rendro-logo.png\")) < 2_000 (D-09)"
    - "branding_claims_test.exs asserts File.read!(\"README.md\") =~ \"Branded Documents\" (D-24 README pointer claim)"
    - "branding_claims_test.exs asserts File.read!(\"mix.exs\") =~ \"guides/branding.md\" (D-20 :extras claim — Plan 08 will satisfy this)"
    - "branding_claims_test.exs has tarball-presence test that runs `mix hex.build` and asserts the produced .tar contains priv/branded/fonts/B612-Regular.ttf, priv/branded/images/rendro-logo.png, NOTICE — Pitfall 1 mitigation; Plan 08 will make :files enumerate these"
    - "branding_claims_test.exs structural %Rendro.Error{} test pattern-matches on stage + reason for an unregistered logical name; never asserts on .what/.why/.next/.where strings (D-26)"
    - "Both test files compose only existing public test helpers (Rendro.Test.DocsContract.verified_fences/1 + evaluate!/2); no new helpers introduced"
  artifacts:
    - path: "test/docs_contract/branding_contract_test.exs"
      provides: "Verifies the four guides/branding.md fences are discoverable + evaluable"
      contains: ["defmodule Rendro.DocsContract.BrandingContractTest", "alias Rendro.Test.DocsContract", "branding-register-assets", "branding-tiered-document", "branding-tiered-template", "branding-missing-asset-diagnostic", "DocsContract.evaluate!", "refute String.contains?(code, \"...\")"]
    - path: "test/docs_contract/branding_claims_test.exs"
      provides: "Asserts presence + structural shape of phase-29 surfaces: NOTICE, B612 byte size, logo byte size, README pointer, mix.exs :extras, tarball whitelist, %Rendro.Error{} structural shape"
      contains: ["defmodule Rendro.DocsContract.BrandingClaimsTest", "File.exists?(\"NOTICE\")", "SIL OPEN FONT LICENSE Version 1.1", "153_192", "rendro-logo.png", "Branded Documents", "guides/branding.md", "mix hex.build", "priv/branded/fonts/B612-Regular.ttf", "%Rendro.Error{stage:"]
  key_links:
    - from: "test/docs_contract/branding_contract_test.exs"
      to: "guides/branding.md (Plan 05)"
      via: "Rendro.Test.DocsContract.verified_fences(\"guides/branding.md\") + evaluate!/2"
      pattern: "verified_fences|evaluate!"
    - from: "test/docs_contract/branding_claims_test.exs"
      to: "Plans 01 (NOTICE, B612, logo) + 05 (branding.md) + 08 (mix.exs :extras + :files) + README.md"
      via: "File.exists?/File.read! + grep substring assertions; mix hex.build subprocess for tarball-presence"
      pattern: "File\\.(exists\\?|read!)|hex\\.build"
---

<objective>
Ship the two docs-contract test files mandated by D-25 + Pitfall 1:

1. **`test/docs_contract/branding_contract_test.exs`** — verifies the four `guides/branding.md` verified fences (D-21) are discoverable by `Rendro.Test.DocsContract.verified_fences/1` AND each evaluates without raising via `DocsContract.evaluate!/2`. Mirror of `test/docs_contract/integrations_contract_test.exs`.

2. **`test/docs_contract/branding_claims_test.exs`** — asserts on filesystem presence + structural shapes:
   - `NOTICE` exists with verbatim B612 OFL 1.1 substrings (D-13)
   - `priv/branded/fonts/B612-Regular.ttf` byte size is EXACTLY 153,192 (Pitfall 5; corrects D-08)
   - `priv/branded/images/rendro-logo.png` byte size < 2,000 (D-09)
   - `README.md` contains "Branded Documents" pointer text (D-24 — satisfied by Plan 08)
   - `mix.exs` :extras enumerates `"guides/branding.md"` (D-20 — satisfied by Plan 08)
   - `mix hex.build` tarball includes `priv/branded/fonts/B612-Regular.ttf`, `priv/branded/images/rendro-logo.png`, and `NOTICE` (Pitfall 1 mitigation; Plan 08 satisfies the :files enumeration)
   - `Rendro.render` of a doc with an unregistered image logical name returns `{:error, %Rendro.Error{stage: ..., reason: ...}}` — structural fields only, never `.what`/`.why`/`.next` (D-26)

Mirror of `test/docs_contract/integrations_claims_test.exs`.

This plan implements D-13, D-21, D-24, D-25, D-26 (test side), and Pitfall 1 (tarball whitelist). Plan 08 provides the README pointer + mix.exs :extras + :files enumeration that several of these claims assert against.

Output: Two test files, ~150 LOC total.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/REQUIREMENTS.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-CONTEXT.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-RESEARCH.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-PATTERNS.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-VALIDATION.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-05-PLAN.md

# Mirror analogs:
@test/docs_contract/integrations_contract_test.exs
@test/docs_contract/integrations_claims_test.exs

# Harness:
@test/support/docs_contract.ex

# Files asserted against:
@guides/branding.md
@lib/rendro/error.ex
@lib/rendro/recipes/branded_invoice.ex

<interfaces>
From test/support/docs_contract.ex:
```elixir
def verified_fences(path) :: [%{id: String.t(), code: String.t(), file: String.t()}]
def evaluate!(code, file) :: any()  # Code.eval_string with import ExUnit.Assertions prepended
```

From mix hex.build (subprocess):
- Produces `rendro-X.Y.Z.tar` in the project root.
- `tar -tzf rendro-X.Y.Z.tar` lists package contents.
- Inside the tarball is `contents.tar.gz` which contains the actual source files.
- The simpler check: `mix hex.build` then read the produced tarball and grep for paths.

Per RESEARCH.md "Pitfall 1": once `mix.exs :files` is set explicitly, default priv/ auto-include is dropped. Test must verify the BUILT tarball, not just the source tree.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Author test/docs_contract/branding_contract_test.exs</name>
  <read_first>
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-CONTEXT.md (D-21)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-PATTERNS.md (`test/docs_contract/branding_contract_test.exs` analog section, lines 330-378)
    - test/docs_contract/integrations_contract_test.exs (mirror target — read entire file)
    - test/support/docs_contract.ex (verified_fences/1 + evaluate!/2 mechanics)
    - guides/branding.md (Plan 05 output — confirms 4 fence IDs are discoverable)
  </read_first>
  <files>
    - test/docs_contract/branding_contract_test.exs (NEW)
  </files>
  <action>
    Author the file mirroring `integrations_contract_test.exs`:

    ```elixir
    defmodule Rendro.DocsContract.BrandingContractTest do
      use ExUnit.Case, async: false

      alias Rendro.Test.DocsContract

      test "guides/branding.md ships exactly the four expected verified fence IDs in order" do
        fences = DocsContract.verified_fences("guides/branding.md")

        assert Enum.map(fences, & &1.id) == [
                 "branding-register-assets",
                 "branding-tiered-document",
                 "branding-tiered-template",
                 "branding-missing-asset-diagnostic"
               ]
      end

      test "every guides/branding.md fence body is evaluable and free of skeleton placeholders" do
        fences = DocsContract.verified_fences("guides/branding.md")
        assert length(fences) == 4

        Enum.each(fences, fn %{id: _id, code: code} ->
          refute String.contains?(code, "..."), "fence body must not contain `...` ellipsis (Code.eval_string cannot evaluate it)"
          refute String.contains?(code, "%{...}"), "fence body must not contain `%{...}` skeleton placeholders"
        end)

        Enum.each(fences, fn %{id: _id, code: code} ->
          DocsContract.evaluate!(code, "guides/branding.md")
        end)
      end
    end
    ```

    Concrete requirements:
    - Module name `Rendro.DocsContract.BrandingContractTest`.
    - `use ExUnit.Case, async: false` (mirrors integrations_contract_test.exs precedent — fences may set process state).
    - No `Mocks.reset_*` setup needed (branded fences do not exercise adapter mocks).
    - The first test asserts EXACT order + EXACT IDs (set membership AND order — drift in either fails CI).
    - The second test runs `evaluate!/2` on EVERY fence — a single failure surfaces an actionable error.
    - The `refute String.contains?` guards mirror integrations_contract_test.exs lines 25-26.
    - DO NOT add fence-id-specific case branches in the second test; iterate uniformly. (Per integrations_contract_test.exs: the `case id do _ -> ... end` block exists for adapter-specific setup which branded fences don't need.)
    - DO NOT special-case fence 4 here; its structural assertion lives INSIDE the fence body itself (D-26 is enforced in the fence text in Plan 05).

    Verify:
    ```bash
    mix test test/docs_contract/branding_contract_test.exs
    ```

    Both tests MUST pass.

    If `evaluate!/2` raises on fence 4 because the actual `%Rendro.Error{stage: ...}` returned by an unregistered-image render has a stage NOT in the defensive set `[:asset_resolve, :build, :compose, :measure, :render, :pipeline]`, the executor MUST run a one-line iex probe:
    ```bash
    mix run -e '
      template = Rendro.Recipes.BrandedInvoice.page_template()
      doc = Rendro.Document.new()
            |> Rendro.Document.add_template(template)
            |> Rendro.Document.set_template(:branded_invoice)
            |> Rendro.Document.add_section(Rendro.section(name: :branded_invoice_logo, region: :logo, content: [Rendro.block(Rendro.image(:unregistered_logo, width: 64, height: 64))]))
      Rendro.render(doc) |> IO.inspect()
    '
    ```

    Then update `guides/branding.md` Fence 4 to use the OBSERVED stage in `assert stage in [...]` (tightened from defensive multi-atom set to actual atom) — this is part of Plan 05 already, but if it landed before the iex probe, this test will catch the drift.
  </action>
  <acceptance_criteria>
    - `test -f test/docs_contract/branding_contract_test.exs` exits 0
    - `grep -Eq '^defmodule Rendro\.DocsContract\.BrandingContractTest do$' test/docs_contract/branding_contract_test.exs` exits 0
    - `grep -Fq 'use ExUnit.Case, async: false' test/docs_contract/branding_contract_test.exs` exits 0
    - `grep -Fq 'alias Rendro.Test.DocsContract' test/docs_contract/branding_contract_test.exs` exits 0
    - `grep -Fq '"branding-register-assets"' test/docs_contract/branding_contract_test.exs` exits 0
    - `grep -Fq '"branding-tiered-document"' test/docs_contract/branding_contract_test.exs` exits 0
    - `grep -Fq '"branding-tiered-template"' test/docs_contract/branding_contract_test.exs` exits 0
    - `grep -Fq '"branding-missing-asset-diagnostic"' test/docs_contract/branding_contract_test.exs` exits 0
    - `grep -Fq 'DocsContract.evaluate!' test/docs_contract/branding_contract_test.exs` exits 0
    - `grep -Fq 'refute String.contains?(code, "...")' test/docs_contract/branding_contract_test.exs` exits 0
    - `mix test test/docs_contract/branding_contract_test.exs` exits 0 (both tests pass)
  </acceptance_criteria>
  <verify>
    <automated>mix test test/docs_contract/branding_contract_test.exs && grep -Fq '"branding-register-assets"' test/docs_contract/branding_contract_test.exs && grep -Fq '"branding-missing-asset-diagnostic"' test/docs_contract/branding_contract_test.exs && grep -Fq 'DocsContract.evaluate!' test/docs_contract/branding_contract_test.exs && grep -Fq 'refute String.contains?(code, "...")' test/docs_contract/branding_contract_test.exs</automated>
  </verify>
  <done>
    test/docs_contract/branding_contract_test.exs exists, mirrors the integrations_contract_test.exs structure, asserts the four guides/branding.md fence IDs in exact order, evaluates every fence via DocsContract.evaluate!/2, and refutes `...`/`%{...}` skeleton placeholders. Both tests pass under `mix test`.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Author test/docs_contract/branding_claims_test.exs</name>
  <read_first>
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-CONTEXT.md (D-13, D-20, D-24, D-25, D-26; Pitfall 1 from RESEARCH.md)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-RESEARCH.md (Pitfall 1 lines 418-428; Pitfall 5 lines 490-501; "NOTICE file" lines 622-646)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-PATTERNS.md (`test/docs_contract/branding_claims_test.exs` analog section, lines 381-446)
    - test/docs_contract/integrations_claims_test.exs (mirror target — read entire file for File.read! + assert =~ pattern, structural %Rendro.Error{} pattern)
    - lib/rendro/error.ex (confirms %Rendro.Error{} field shape)
  </read_first>
  <files>
    - test/docs_contract/branding_claims_test.exs (NEW)
  </files>
  <action>
    Author the claims test file mirroring integrations_claims_test.exs structure:

    ```elixir
    defmodule Rendro.DocsContract.BrandingClaimsTest do
      use ExUnit.Case, async: false

      describe "NOTICE file (D-13)" do
        test "exists at top level" do
          assert File.exists?("NOTICE"), "expected top-level NOTICE file (B612 OFL 1.1 attribution)"
        end

        test "contains verbatim SIL OPEN FONT LICENSE Version 1.1 substrings" do
          content = File.read!("NOTICE")
          assert content =~ "SIL OPEN FONT LICENSE Version 1.1"
          assert content =~ "Copyright 2012 The B612 Project Authors"
          assert content =~ "http://scripts.sil.org/OFL"
        end
      end

      describe "shipped brand assets (D-08 corrected by RESEARCH.md Pitfall 5; D-09)" do
        test "B612-Regular.ttf is exactly 153_192 bytes" do
          path = "priv/branded/fonts/B612-Regular.ttf"
          assert File.exists?(path)
          assert byte_size(File.read!(path)) == 153_192
        end

        test "rendro-logo.png exists and is under 2_000 bytes" do
          path = "priv/branded/images/rendro-logo.png"
          assert File.exists?(path)
          size = byte_size(File.read!(path))
          assert size < 2_000
          assert size > 100
        end
      end

      describe "README pointer (D-24)" do
        test "README.md contains a Branded Documents pointer subsection" do
          content = File.read!("README.md")
          assert content =~ "Branded Documents"
          assert content =~ "Rendro.Recipes.BrandedInvoice"
          assert content =~ "guides/branding.md"
        end
      end

      describe "mix.exs :extras (D-20)" do
        test "mix.exs enumerates guides/branding.md in :extras" do
          content = File.read!("mix.exs")
          assert content =~ "guides/branding.md"
        end
      end

      describe "Hex tarball whitelist (Pitfall 1 — :files must enumerate priv/branded + NOTICE)" do
        @tag :hex_build
        test "mix hex.build tarball includes priv/branded/** and NOTICE" do
          # Pre-emptively clean any prior tarball
          for path <- Path.wildcard("rendro-*.tar"), do: File.rm!(path)

          {output, status} = System.cmd("mix", ["hex.build"], stderr_to_stdout: true)
          assert status == 0, "mix hex.build failed:\n#{output}"

          [tarball] = Path.wildcard("rendro-*.tar")
          {entries_output, 0} = System.cmd("tar", ["-tf", tarball])

          # The outer tarball contains a contents.tar.gz; the actual files live there.
          assert entries_output =~ "contents.tar.gz",
                 "expected outer hex tarball to contain contents.tar.gz; got entries:\n#{entries_output}"

          # Extract contents.tar.gz to a temp dir and list its contents
          tmp = Path.join(System.tmp_dir!(), "rendro_hex_build_check_#{System.unique_integer([:positive])}")
          File.mkdir_p!(tmp)

          try do
            {_, 0} = System.cmd("tar", ["-xf", tarball, "-C", tmp, "contents.tar.gz"])
            {inner_entries, 0} = System.cmd("tar", ["-tzf", Path.join(tmp, "contents.tar.gz")])

            assert inner_entries =~ "priv/branded/fonts/B612-Regular.ttf",
                   "expected priv/branded/fonts/B612-Regular.ttf in tarball; got:\n#{inner_entries}"
            assert inner_entries =~ "priv/branded/images/rendro-logo.png",
                   "expected priv/branded/images/rendro-logo.png in tarball; got:\n#{inner_entries}"
            assert inner_entries =~ "NOTICE",
                   "expected NOTICE in tarball; got:\n#{inner_entries}"
          after
            File.rm_rf!(tmp)
            File.rm(tarball)
          end
        end
      end

      describe "structural %Rendro.Error{} on missing asset (D-26)" do
        test "unregistered image logical name surfaces typed error with stage + reason" do
          template = Rendro.Recipes.BrandedInvoice.page_template()

          doc =
            Rendro.Document.new()
            |> Rendro.Document.add_template(template)
            |> Rendro.Document.set_template(:branded_invoice)
            |> Rendro.Document.add_section(
                 Rendro.section(
                   name: :branded_invoice_logo,
                   region: :logo,
                   content: [Rendro.block(Rendro.image(:unregistered_logo, width: 64, height: 64))]
                 )
               )

          assert {:error, %Rendro.Error{stage: stage, reason: reason}} = Rendro.render(doc)
          assert stage in [:asset_resolve, :build, :compose, :measure, :render, :pipeline]
          assert reason != nil
          # Structural only — never assert on .what / .why / .next message strings (D-26)
        end
      end
    end
    ```

    Concrete requirements:
    - Module name `Rendro.DocsContract.BrandingClaimsTest`.
    - `use ExUnit.Case, async: false` (matches integrations_claims_test.exs).
    - The B612 byte-size assertion uses `==` with EXACTLY `153_192` (NOT `<` or `<=`; not `≈`; not a tolerance). Pitfall 5 fix.
    - The hex.build tarball test uses `@tag :hex_build` so it can be skipped via `mix test --exclude hex_build` in fast iteration; default `mix test` runs it.
    - The hex.build test cleans up after itself (removes both the produced tarball AND the temp extraction dir).
    - The structural %Rendro.Error{} test uses `:unregistered_logo` (Pitfall 4 — unregistered name, not junk bytes).
    - The structural test asserts `stage in [...]` set membership (defensive set per A2 in Assumptions Log; tightens after iex probe).
    - The structural test pattern-matches on `:stage` and `:reason` ONLY — never `.what`, `.why`, `.next`, `.where`.
    - DO NOT use `Mocks.threadline_calls()` or anything from `Rendro.Test.Mocks` — the branded path doesn't exercise adapters.
    - DO NOT introduce a property test (use simple unit-form assertions per D-25 Patterns analog line 437).
    - DO NOT add a byte-identical render assertion here — that lives in Plan 04 (`branded_invoice_test.exs`). This claims test is for filesystem + structural-error claims only.

    Verify:
    ```bash
    mix test test/docs_contract/branding_claims_test.exs
    ```

    All 7-8 tests across 6 describe blocks MUST pass. The `hex_build` describe block requires Plan 08's mix.exs :files enumeration AND Plan 01's NOTICE + B612 + logo bytes to be present; if any are missing, the test will fail with an actionable error message.

    Order of execution (Plans 01, 05, 08 must land before this test passes end-to-end):
    - Plans 01, 05 land first (assets + guide).
    - This Plan 06 lands.
    - The hex_build test will FAIL until Plan 08 modifies mix.exs to enumerate priv/branded/** and NOTICE in :files. That's expected; it's the dependency direction.
    - Plan 08 closes the loop.

    If running this test in isolation BEFORE Plan 08: the hex_build test will fail with a tarball-missing-NOTICE assertion. That's the correct dependency signal — DO NOT relax the test.
  </action>
  <acceptance_criteria>
    - `test -f test/docs_contract/branding_claims_test.exs` exits 0
    - `grep -Eq '^defmodule Rendro\.DocsContract\.BrandingClaimsTest do$' test/docs_contract/branding_claims_test.exs` exits 0
    - `grep -Fq 'File.exists?("NOTICE")' test/docs_contract/branding_claims_test.exs` exits 0
    - `grep -Fq 'SIL OPEN FONT LICENSE Version 1.1' test/docs_contract/branding_claims_test.exs` exits 0
    - `grep -Fq 'Copyright 2012 The B612 Project Authors' test/docs_contract/branding_claims_test.exs` exits 0
    - `grep -Fq 'http://scripts.sil.org/OFL' test/docs_contract/branding_claims_test.exs` exits 0
    - `grep -Fq '== 153_192' test/docs_contract/branding_claims_test.exs` exits 0  (Pitfall 5 — exact equality)
    - `grep -Fq 'rendro-logo.png' test/docs_contract/branding_claims_test.exs` exits 0
    - `grep -Fq '< 2_000' test/docs_contract/branding_claims_test.exs` exits 0
    - `grep -Fq 'Branded Documents' test/docs_contract/branding_claims_test.exs` exits 0
    - `grep -Fq 'guides/branding.md' test/docs_contract/branding_claims_test.exs` exits 0
    - `grep -Fq 'mix' test/docs_contract/branding_claims_test.exs && grep -Fq 'hex.build' test/docs_contract/branding_claims_test.exs` exits 0
    - `grep -Fq 'priv/branded/fonts/B612-Regular.ttf' test/docs_contract/branding_claims_test.exs` exits 0
    - `grep -Fq 'priv/branded/images/rendro-logo.png' test/docs_contract/branding_claims_test.exs` exits 0
    - `grep -Fq '%Rendro.Error{stage: stage, reason: reason}' test/docs_contract/branding_claims_test.exs` exits 0
    - `grep -Fq ':unregistered_logo' test/docs_contract/branding_claims_test.exs` exits 0
    - Anti-pattern absence: `! grep -Fq '%Rendro.Error{what:' test/docs_contract/branding_claims_test.exs` (D-26)
    - Anti-pattern absence: `! grep -Fq '%Rendro.Error{why:' test/docs_contract/branding_claims_test.exs` (D-26)
    - Anti-pattern absence: `! grep -Fq '%Rendro.Error{next:' test/docs_contract/branding_claims_test.exs` (D-26)
    - Anti-pattern absence: `! grep -Fq 'byte_size.*B612.*<' test/docs_contract/branding_claims_test.exs` (Pitfall 5 — must be `==`, not `<`)
    - Most tests pass under `mix test test/docs_contract/branding_claims_test.exs` (the hex_build test depends on Plan 08; expected to fail until then; document this expectation in Plan 08 instead of relaxing here)
  </acceptance_criteria>
  <verify>
    <automated>test -f test/docs_contract/branding_claims_test.exs && grep -Fq '== 153_192' test/docs_contract/branding_claims_test.exs && grep -Fq 'File.exists?("NOTICE")' test/docs_contract/branding_claims_test.exs && grep -Fq 'SIL OPEN FONT LICENSE Version 1.1' test/docs_contract/branding_claims_test.exs && grep -Fq 'Branded Documents' test/docs_contract/branding_claims_test.exs && grep -Fq 'guides/branding.md' test/docs_contract/branding_claims_test.exs && grep -Fq '%Rendro.Error{stage: stage, reason: reason}' test/docs_contract/branding_claims_test.exs && ! grep -Fq '%Rendro.Error{what:' test/docs_contract/branding_claims_test.exs</automated>
  </verify>
  <done>
    test/docs_contract/branding_claims_test.exs exists with 6 describe blocks asserting NOTICE existence + OFL substrings (D-13), B612 exact byte size 153_192 (Pitfall 5), logo size <2000 (D-09), README "Branded Documents" pointer (D-24), mix.exs :extras includes guides/branding.md (D-20), `mix hex.build` tarball whitelist includes priv/branded/** and NOTICE (Pitfall 1), structural %Rendro.Error{stage,reason} on unregistered logical name (D-26). All but hex_build test pass after Plans 01/05 land; hex_build closes after Plan 08.
  </done>
</task>

</tasks>

<verification>
- `mix test test/docs_contract/branding_contract_test.exs` exits 0 (after Plan 05 lands)
- `mix test test/docs_contract/branding_claims_test.exs` mostly passes (hex_build test depends on Plan 08; closes after Plan 08 runs)
- B612 byte-size assertion is `==` with literal `153_192` (RESEARCH.md Pitfall 5; D-08 corrected)
- No %Rendro.Error{} message-string assertions anywhere (D-26 enforced)
- Tarball-presence test uses `mix hex.build` subprocess + tar inspection (Pitfall 1 mitigation; not just source-tree check)
- Both test files compose only existing public test helpers
</verification>

<success_criteria>
- Two test files exist, mirroring integrations_*_test.exs precedent.
- branding_contract_test.exs verifies all four D-21 fence IDs are discoverable in exact order AND every fence body is evaluable without raising.
- branding_claims_test.exs proves NOTICE presence + OFL substrings (D-13), B612 exact size (Pitfall 5), logo size budget (D-09), README pointer (D-24), mix.exs :extras (D-20), tarball whitelist (Pitfall 1), structural %Rendro.Error{} on missing asset (D-26).
- The Pitfall 5 corrected assertion (== 153_192, not < 60_000) is in place.
- The Pitfall 4 mitigation (unregistered logical name, not junk bytes) is in the structural-error test.
- The D-26 enforcement (no .what/.why/.next/.where assertions) is invariant — guarded by grep gates.
- The hex_build tarball test is the Pitfall 1 mitigation — inspects the BUILT tarball, not just the source tree.
</success_criteria>

<output>
After completion, create `.planning/phases/29-branded-recipes-docs-and-proof-closure/29-06-SUMMARY.md` documenting:
- Total LOC of both test files
- Pass/fail count per `mix test test/docs_contract/branding_*_test.exs`
- The exact stage atom observed by the structural-%Rendro.Error{} test (post-Plan-08 + post-iex-probe)
- Confirmation that the hex_build test passes after Plan 08 (the loop closes)
- Confirmation that no .what/.why/.next/.where assertions exist in either file (D-26 enforcement)
</output>
</content>
</invoke>