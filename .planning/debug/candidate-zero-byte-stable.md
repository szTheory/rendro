---
status: investigating
trigger: "authorize-candidate-zero-byte-stable-investigation-and-fix"
created: 2026-08-20
updated: 2026-08-20
---

# Debug Session: Candidate Zero Byte-Stable Cells

## Symptoms

### Expected behavior

The Plan 130-04 candidate manifest partitions all 32 fixed catalog IDs by actual identity: changed scored cells require review, changed unscored cells remain unscored, and genuinely unchanged/no-theme cells remain `byte_stable` and are never rebound.

### Actual behavior

The independently verified exact-source, pinned-PDFium candidate manifest has a complete 32-ID partition but classifies all cells as changed: 12 `changed_scored`, 20 `changed_unscored`, and 0 `byte_stable`. This violates the plan's no-theme/byte-stability acceptance criterion.

### Error messages

No runtime error. The semantic gate failed because `.diff.byte_stable` is empty while `.diff.changed_scored + .diff.changed_unscored + .diff.byte_stable` contains all 32 IDs.

### Timeline

Observed on 2026-08-20 after successful candidate-only run `32417257428`/job `96581121473`, independently verified route/source/PDFium provenance, and restoration of the exact candidate artifacts into the fixed Plan 130-04 temp roots.

### Reproduction

Inspect `tmp/phase130-candidate/candidate-manifest.json` from candidate artifact `9424562803` and compare every candidate PNG/PDF identity with the committed `assets/rendro/catalog.json` baseline and relevant source/no-theme identity contracts. The manifest reports counts `12/20/0`.

## Scope Constraints

- Preserve the verified candidate bytes and canonical baseline while investigating; do not regenerate, download substitutes, rewrite hashes, or reclassify by expectation.
- Build a 32-row evidence matrix covering ID, recipe/preset/theme mode, baseline vs candidate PNG SHA, baseline vs candidate source-PDF SHA, renderer kind/version/pin, review status, and current classification.
- Determine whether zero stability is caused by comparison/classification logic, baseline identity provenance/toolchain mismatch, candidate source-PDF drift, or genuine full-catalog output drift.
- Explicitly test no-theme and stable-control identities, and distinguish PDF/source change from raster-only change.
- Fix only a demonstrated contract/implementation bug, with regression tests and unchanged canonical/reviewer-owned bytes.
- If all-cell drift is genuine or requires baseline/reference policy changes, stop with evidence and recommendation; do not mutate baselines, scores, SIGN-OFF, launch staging, or publication state.
- Do not push, launch CI, merge diagnostic routes, regenerate, or accept new artifacts. Any corrected candidate commit must return to a fresh exact-SHA gate.

## Current Focus

hypothesis: confirmed genuine full-catalog drift: the 17-August canonical catalog predates intentional Phase 130 changes to every recipe family's supplied-theme path, while the catalog renders `Theme.default()` rather than `nil` for its six default rows.
test: the six existing nil/no-theme byte-identity suites were run, and the artifact matrix plus fresh rendering already confirm candidate equality and baseline divergence.
expecting: all nil/no-theme byte-identity suites pass, separating that contract from the catalog's explicit-default path.
next_action: stop without mutation; obtain a policy decision on authorized canonical rebind/review or an explicitly redesigned catalog no-theme control contract
bug_class: bohrbug
reasoning_checkpoint:
tdd_checkpoint:

## Evidence

- timestamp: 2026-08-20
  checked: debug-session protocol, project skill discovery, and semantic knowledge-base availability
  found: The session has no prior evidence or eliminated hypotheses. No project-local skills were found and no debugger-specific configured skills were emitted. This is a deterministic artifact comparison; no runnable failing/pass test spectrum has yet been identified.
  implication: Route as a Bohrbug to deterministic reproduction and source/predicate tracing; SBFL will be logged as skipped if no per-test failure spectrum exists.

- timestamp: 2026-08-20
  checked: restored candidate manifest against committed catalog manifest, joined by all 32 literal catalog IDs
  found: Every one of 32 IDs has both PNG SHA-256 and source-PDF SHA-256 unequal to the canonical baseline. The candidate distribution is 12 `review_required` (the 12 scored baseline dispositions), 20 `changed_unscored`, and 0 `byte_stable`; no row is raster-only drift.
  implication: The classifier's outcome follows the observed bytes, not a PNG-path comparison error or a reviewer disposition mismatch.

- timestamp: 2026-08-20
  checked: `candidate_status/3` in `dev/rendro/catalog.ex:1008-1016` and candidate provenance
  found: `byte_stable` requires exact equality of both `png_sha256` and `source_pdf_sha256`; otherwise the status is selected solely from the existing rubric disposition. Candidate provenance reports PDFium v0.11.0 and pin SHA `b1e7f3…ae160a`; the committed baseline records the same renderer kind/version but not its executable-pin SHA.
  implication: Source-PDF drift precedes rasterization, so a renderer-version or pin mismatch cannot by itself explain zero stability; the predicate is exact and mechanically correct for the declared identity contract.

- timestamp: 2026-08-20
  checked: catalog rendering path at baseline asset binding `e86bc503` and candidate source `411cdca`
  found: Both versions call `theme_for/1`, and `theme_for(%{preset_atom: nil})` returns `Rendro.Theme.default()`; `source_document_for/1` always passes that value as `theme:`. The Phase 130 commit range modifies all six recipe families, while recipes' byte-identity contracts protect `theme: nil` paths rather than this catalog's explicit default-theme path.
  implication: The catalog's six `default` rows are not nil-theme controls, so existing nil-theme byte-identity tests do not establish their canonical catalog hashes should remain stable after themed recipe changes.

+
- timestamp: 2026-08-20
  checked: read-only `Rendro.Catalog.check/0` against the committed manifest
  found: The check reported exactly 32 source-PDF hash-drift errors—one per literal catalog ID—and no PNG artifact mismatch errors. A fresh in-memory deterministic render for every spec matched the restored candidate's source-PDF SHA 32/32.
  implication: The restored candidate represents the current source behavior exactly; this is genuine source plus raster drift from the 2026-08-17 canonical binding, not a candidate artifact corruption or a raster-only/toolchain discrepancy.

- timestamp: 2026-08-20
  checked: changes from baseline asset-binding commit `e86bc503` to candidate source `411cdca`
  found: No fixture/example input changes occurred. All six catalog recipe modules changed (156 additions, 32 deletions), including their supplied-theme hierarchy paths.
  implication: The code branch alone accounts for the all-family source-PDF divergence. The remaining question is policy: whether the 17-August canonical baseline may be superseded after the intentional Phase 130 changes.

- timestamp: 2026-08-20
  checked: six existing recipe byte-identity suites (invoice, statement, receipt, certificate, payslip, ticket)
  found: 15 tests passed with 0 failures. These tests exercise deterministic nil/no-theme paths and their frozen golden hashes.
  implication: The recipes continue to satisfy their protected no-theme byte-identity contracts; the catalog's `Theme.default()` invocation is a separate, intentionally supplied-theme contract.

## Artifact Matrix

The table records the requested complete 32-cell comparison. Source-PDF and PNG SHA values are exact; each row is source drift plus raster drift (never raster-only).

| ID | recipe/preset/theme/mode | baseline PNG SHA | candidate PNG SHA | baseline source-PDF SHA | candidate source-PDF SHA | renderer/version/pin | baseline review | candidate classification |
|---|---|---|---|---|---|---|---|---|
| invoice--default--default--light | default / light | cac89b6464af4bb6f55c0bf150618616d49b0d9507af59f3dac45959bb073a7d | e592870f68abc9e0591973eb68725ba656651421e143f8df9d9c424f752ce69a | 629cc0d135684b119d81dfa93352dcb99319b6f47e648a76d48c04972f745c69 | 640b58c123cb9ba876606a159feadb2b0aff28d99e91ce3b38d8e3713b8a62a2 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| invoice--northline-logistics--swiss--light | preset:swiss / light | cea9d97b5d3a77ef8f2b086a93f2944925b5c543fb635ba02deb8364e1a680cc | 0840f21faf8c56f7b703471e7787211d8e10f35cef3ef83b122bbbc1b2b0d147 | dc423bf221f158478bd68e6fc142f3a6fb144ca7e1f5fc61b437ad33ca67f7fd | 1c02186c1f80e4e56cc47e9f385ba25e9f480cdb8f9f64b684c50d884893024c | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| invoice--northline-logistics--swiss--dark | preset:swiss / dark | f70282b3d2aebdfc77db40926b40d85cb28a714b57a51a9311745245fe8f52ae | 227a54446b315fcf3c1d76d9d5b56cb5f02c55be2582dd0ed0aac395a23458fa | 7fab33da639788475fb61010a0866c42833de8b9912bee1d77404275177b755e | d8f9504692bedef4c3c0b292f7c830221985a50e7e88c231c8ae3ff1a971ab41 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| invoice--cedar-mutual--corporate-classic--light | preset:corporate-classic / light | a7965f9a6f6e7c12708c076572caea7bd5ae17119c51fed2663d4cc60ca98e97 | aa6245724dfb8c7a5ff63dcddf4033504f6484e893aa6908b2d199dc91b33f8d | d1e941912528445363d24587dd81de96f45900387abd44d93dfec7ce06d7c370 | 09d1d39d49912fd2dcb33f0a55e55bc3903cf233dc6e8abe66e16cc0db1483a3 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | needs_work | review_required |
| invoice--cedar-mutual--corporate-classic--dark | preset:corporate-classic / dark | 46d2570623bbc94d25a9e0970b13166abb3cd80ec93b1e3f86069ad3b3590d20 | 7a8fd547fdab8314b3d5c092aa231b1c93432ddbb0371f7180c871866c81d3b2 | 28350fccb2d26bee35f563e900f7645dfd0d99789ad33ba6e8feaf6c8248fd57 | 50a4515a7ba347900a3ec784d98db27a58880c01f13a23c35dd1de093664ceef | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | needs_work | review_required |
| statement--default--default--light | default / light | cec9499b70e9ab82064b7edac9703ccf223119eb7899160968918fec667ae5fb | de1e53c5397454a453fa6723d424befb5a72327009677a1d0e46d1aadf4b34f1 | b2a1dcaa5fed37376690516e8f0ce824ea3bc7d5f760f62f9f2de35e16e7f883 | d035e901fb5d17800242b1c6e8ede3383444d09451cc997d935ac37435b462d4 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| statement--signal-ledger--minimal-mono--light | preset:minimal-mono / light | 93d064d726f2535e941d58f40c3e607d2fc64ac53059844f96dc4f602727cea8 | 526f0891bab69935419f7039d3dd4d5e20a21ad4b5e37efd70102ee3f0c38017 | de2f5c6abc58131b94e702fc85ad752921c643a3bf0bd67ea5138910fa420ef8 | 79f6fe32659321db254670bbbdcd9db392cdfe323125e98905d6df2e9bfa44b9 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | needs_work | review_required |
| statement--signal-ledger--minimal-mono--dark | preset:minimal-mono / dark | 9188234602e0fecf689e21bfc021df6efe59751f61d9c7f1daf543b610c1d7ed | 63d945425634be00fb4b655f408795fd8558f01f44b8d286760fb76777a73815 | 79a1b48d3e19babcd25b9bda2e7cd0cdc5d3339980e78fd017e87f9108b9a968 | c0ee94af4cb7faa19e5a7b68152a65db20e4fd944a9101ec9ace64576b0c229d | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | needs_work | review_required |
| statement--aster-research-fund--editorial--light | preset:editorial / light | a237a039f441fc6bb4a09bb0fb0af958e05450cbf075856404729fa0ce5e0e7e | 4ec741f91d0436486de1805403449182de05ecca695e3152bd23af9b34673b1f | 027efb827aa27558c79b63ca968dc80a8797fc6a4901330210c829726215cec9 | 793eefdc918519e50ec3310a2ffa36f88ef034f7dcab046e8d28ca731e29e7ab | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| statement--aster-research-fund--editorial--dark | preset:editorial / dark | 233d74295b2e39f8cd575154bd68dd714f9b9ec4e49e45f9bb02dfb5c5473429 | 17332c04a1d507f326bf296e16e79699d5acf37f6fe9723a40169c2d4ec76795 | f7af4230ee7c2bf4b583308819fb021e6d853f4c4efb1b0da53069233e5b1859 | 8a5514348386f48d1b6c0a1b222a394d8b4c44dee355ac93dea9e64117848eef | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| receipt--default--default--light | default / light | 4e99d1d1b2201774bb7c8e00d4ff576a95e3b4d1a7a01faa250a015e1f15e3ce | 2ee376b4024f0f38ed9fb5099f7a806f3e7069148400b9f827e5fb06449b514b | 3d39c22f42df06db019333fa6bc3e2dc6fe10bff70ad0f06417313b2d83456ec | 2dde87ab329ad4cd53e0b27273536f3f3b3d6d30a21889e9ce97b67a222a7f5f | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| receipt--poppy-and-grain--humanist--light | preset:humanist / light | ababe224fdcef94235c783de6b16802b15bcddcaccdf14b8a67b813a130fae86 | 8ee9808a5d2edd9e292941ef01b63c16cc3488a816f7a206815ecd5c7a0a719e | 99e9394a5503b82a73b2a02578d21d5bc08c7a707007c3784109edf9280202c7 | 940a09cf42373afa043727508a6e1e0bd84f673d7ce92a69131cfac8ff791a4b | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | needs_work | review_required |
| receipt--poppy-and-grain--humanist--dark | preset:humanist / dark | fe1ca525eb3d81cc6c3aad6c7723b3a8683b4496429e174ddbbf81de5f4b0804 | 9431349b4908cbe3e38b5649ffc1a67c3bb9b2261ccb9f89b22e976f676b84ac | 5743bb956bf0a52279d8f6867e4c8180368d922a44552b5ae0894dcf25cd0ae0 | 4612d45d09df7d1b8aa9f8dddf288cc8c8ca2058d8fddcf7f518cfdd0d6171ae | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | needs_work | review_required |
| receipt--circuit-supply-co--minimal-mono--light | preset:minimal-mono / light | 3fa9478a1f2c98c55adaf0d211e17b55cb47460b76707beecf47598990ac48bb | 382a70c40af4c5c4498166d2d85834011bc8b0f91bd404e79cfded4671de5efa | 0c3d2422e6a2ebd215ea04515ec8351c586b0cdc4cd7765c6c9f7a6bc2f6720e | 43fb2489643f8ec945e08073aee63b845f4a0eac19a97f9795dae6cf2855cfa9 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| receipt--circuit-supply-co--minimal-mono--dark | preset:minimal-mono / dark | f45b9c326dc3f2de548965f15abe155f2ac4c2968ad1bd1814de5fb77f2a7fe6 | 46e0721e16970430c3d35083c4a266682eeca0a9c3370dde2d67e9d5f8376924 | 2fda91de3bd10c8cfb110e573fd51d0a739bddd7dae26efd25ee69c2c1682055 | 3ebb88c4c4184dbd1e6a1e7c08d9578dd4d8c480344b706031c3ebdee711d103 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| certificate--default--default--light | default / light | bad0ac50e83d74fdcc5aeba2131b5bcd79841a6271a40db5ffdc3831f50be3a5 | 66adb7fe66d66d6d7e0d231929613c4f8478fc5c628c09d28024826d6867cfde | d537429112527b10510c404bdb3e8666b81b8362e363f233a293568f493e94d3 | e55b71ff1a40792450bb9c577e72e578047e38f12b31176def52f6679434777d | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| certificate--aster-institute--swiss--light | preset:swiss / light | dcbbc0fcd5d65d3da6900e4cb27f4f73cdab1b12de1364538e2173fed07713b8 | c999546de58d5d3c9293cbd121fd51de8a2e68cb351fe086e34f56e48ef235bc | 0806d7a99e61f68629f856a604b48807d16c6eab371df1118fb416053730e0fa | 34ff3bfec4d064d30079df7ae0c078f5c8ffba3693be6d37a9b6128b3c3b56ec | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| certificate--aster-institute--swiss--dark | preset:swiss / dark | d1c1678c4a315c0e2a4cce884b61f71d91ec2993703bcf2e1646d1cf6cb036e0 | fe344823abe3b621500c18462d8c2728efd66d28b6ade7da52ff9d77cfdc4225 | bd5280e0a608ec178d4810f233391152912fabcf1ff38bbb2a0708f02e707adc | 31b1788a73ab11a82689ed12cbe89634cea567bd44bb6e3bb555dde0ad7b7d74 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| certificate--meridian-arts-fellowship--editorial--light | preset:editorial / light | 6080b2f2fab7af111328f61f54f16439656a13076fccbaac7259caa506727c5a | 4db36148da0951f38062ceafbe506f7c0044dc69351a5e186b4fd9ca98e9d066 | 2ff095bdb7de0ccc7f7dd076ace047f9ccc42b2ed36ffb42b3ea0cea8e0271d9 | 3171693135a99bf63583f61fff72c8b67f2e98cdef164d5c5ad4d8c96fc17e7b | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | needs_work | review_required |
| certificate--meridian-arts-fellowship--editorial--dark | preset:editorial / dark | 7ef31ce0db29fd92d0dd32df2e3bdaaaaa8f852642eb1abc4793f47011420f72 | c8e33580ef93c5c27b128a490a9b5799ee0256f1e1500a48db692e825c437d52 | 74419f42fcb37fc2f125c066b64f505389dbe01b7a19059fcff567915daafad1 | c0ac38e0024857c528bbeddc3733f5d7fdbb24daeeb795e8110b931ad21f8634 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | needs_work | review_required |
| payslip--default--default--light | default / light | e56136b7f24d7da25c18e3de2dd4e25a52aacdc69d0263144990e8615e8c3e84 | bf764cd92cc9775fdd9f03901dba47de0c2108769dbaf4e02dcbc699586f4274 | 5aa06d26d40e9ab8a9c06c1fef595c7f3adfa94d900e2eac92f2c1b803b0c1e3 | fe6943472202526c46647eb65275a3385e570b6d0fd8aee05d3ade4b5620425a | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| payslip--northline-logistics--swiss--light | preset:swiss / light | bbc2c8988f39e33224b70b3eb2e6a1059bd3e5d1024c090eca4b765d35a3cf56 | ccaa718c49a3a9cddc3f9923b6310cb4c225481ba6d10353849f1e90d19f7be8 | 4223e712212959fcbe0a7d65aba35f43aeebaa587d028f27d8802522fcfa0746 | a88be1778ffec799223b147566151ab86d4b8b37871fbe8c739329b73519004e | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | needs_work | review_required |
| payslip--northline-logistics--swiss--dark | preset:swiss / dark | bd154733910fecb46694c1333e6ee4f7ff1795b3979b4a1dbc8a489ee14a02c5 | 7e49c55c2f72b47c01dd0e98f6b9094ad3772a6c1cdb3118e303ede299783184 | c62440f65657e9500cb82cf3aa13e3a1912dcd2c2d70ae42aa0334f7164c4d70 | f3bc9896b4491a2f9168aa62e7ea7fbbbf3eead99fbb154f16011cd5e73b2dd0 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | needs_work | review_required |
| payslip--cedar-mutual--corporate-classic--light | preset:corporate-classic / light | 88576f8fc9603a245ba01fecb7138dc832dd1b50a1c83bc290ef70d743789da1 | 1ed16549e63d8f52bfd99d87a58718d3151ba8457970694dfcf0a57d12cbb44c | 9fde67a201fbc117ad303cdcfe5e7911c2f81087ebd263a0925ab0ffddfe55f4 | 9ddd82cf25dae5afd6e42cdb1b873fb81244f440ab436c5efb8749cd657179fb | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| payslip--cedar-mutual--corporate-classic--dark | preset:corporate-classic / dark | 4f47f554be1731ba0a464292a6b658975885547eb4319e14df67b98dd8c9c1f4 | efe59c0c36d755c866349dbc05f8a4815a59f7fba346079c434709cdc29d76a1 | 92ed1da6c00b32b21f7f262fd6f1361332787b89148751f9ca609d01033c0ff2 | faebde994c4e768ceb168112999783501b68134459ee27db64fad9761c14756c | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| ticket--default--default--light | default / light | 88d277a6e2054f3b4605157fed54c1aee00089614ddd21cefbd0daac0fdee1ed | be472db142b956d98b0b79882c6d535d8edf8ec63512ca4256933c4e2d90b784 | 3b9ba2d9a14f836a15a15fee52cc0be7f3f75fcae17dcc370ed4bca7d91a7663 | 9e2da79e6e544abe48315b910e139f098c10997bf7eb2d2127e6f5b8461b3574 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| ticket--field-notes-conference--minimal-mono--light | preset:minimal-mono / light | 7e9b5ef1fbe7709a77ba8b2d46ba941270cc347093355bf6aaad84790d2bb0d9 | de83805beaaa7442149a6a82a16b0731d532afd9f6e4cf17622f36fc68d17c8e | 88d81e455065fe11e83daa8a0a2ebdb4aaf52435c998ee34f74493c824e014e8 | 3df8ef93c864b7dfa84c06419f434544a30006c3e4754e028571d78198277e26 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| ticket--field-notes-conference--minimal-mono--dark | preset:minimal-mono / dark | 5eb80ee3a2609f147f100c42169e11986407674698d1d5809a15dfba41433dd0 | 0bb27b3982962ea6577a9a154f4b40785274ad5b9de49709e9a1c3ff30228fd8 | fe990ba5de8ea933ec7b72a306cdbdb5a0a2b1ebe86c469efd452d4848674fed | 42057a0c92c5cdb6b36a6267063cb189411bef178a2ed6a6e1881b1339aad919 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| ticket--the-letterpress-hall--editorial--light | preset:editorial / light | 0b948759d6cb4eb7b6ee1d2b26923d649059bd334f12473cd66e2bb1dbdaec9d | 65a8d0a03fdfbf79c801f91126c9f000371eca63a1a2a92c30b2e2ee48d467b8 | 05cc08275daf09af482bbf7fdcfca4601b6e019bf7e268bba7f70fb5d3c347e8 | c81e638e4caaa83d80daccb4ef910ae1f7d6c888e93f05c32722e2413ac0cab2 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| ticket--the-letterpress-hall--editorial--dark | preset:editorial / dark | 54f49efc48f40f6ac195370316dec1e1e1950108f006eeeef8757c9d816191c5 | 51d9b2c76e3b6cbc2c162be38b05216ac44692acc8027e17438cb9702f4dc78b | 9801e69a9f721f982f46a09e7fa94cee2a6253f23b06f6450918033b4493286a | f5af9327fabe223160a92a51afc83d1b0e1a1d4bec59843df8e448a0f0142427 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | unscored | changed_unscored |
| ticket--aurora-live--brutalist--light | preset:brutalist / light | 183d2f489bd2d26a191a37189ab18b98769d824cd7ca8aea0799b582103064d3 | d75ab8b5cfabc26cb93f724353dacb3710c7fc5d191efc1655a428b6a56d4170 | 477e5ed853160ce2257a6e035e1d647d1d82d540c6318497e6641d80bfaec016 | c3d1baf2d32881534aafdbb41ee931ef1d67dbe3647f084c4221c56bea7139f9 | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | needs_work | review_required |
| ticket--aurora-live--brutalist--dark | preset:brutalist / dark | 3f2421ca1f8c0353ee7ac04f7318cceb77eb5354f0f64f1817dcbd232e0d5a94 | 69184d72986d30ce089484f83b0b92397c51716e10c6c6d52b8ea4fbfe1669e6 | 4ffcba4c3e18f1a350aa76dcafcaf267e9aee7fae8c0be9f7bb8415947265b14 | a6e49f1477d9394b16cab1045da47fc433e1459a1ac3c2e33cdc900785c4ee9a | baseline: pdfium-render/v0.11.0/pin-unrecorded; candidate: pdfium-render/v0.11.0/b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a | needs_work | review_required |


## Eliminated

- hypothesis: candidate classification incorrectly declares unchanged cells as changed due to a faulty identity predicate
  evidence: `candidate_status/3` requires both exact PNG and source-PDF equality, and every one of 32 rows differs on both fields; fresh in-memory source renders match the candidate 32/32.
  timestamp: 2026-08-20

- hypothesis: PDFium pin/version mismatch causes raster-only catalog drift
  evidence: all 32 source-PDF hashes differ before PDFium rendering; candidate PDFium v0.11.0/pin is independently recorded, and no row has equal source-PDF but different PNG.
  timestamp: 2026-08-20

## Resolution

root_cause:
  The zero `byte_stable` cells are genuine. The canonical catalog and its 32 bound source-PDF/PNG identities were last generated on 2026-08-17; source commit `411cdca` contains intentional Phase 130 supplied-theme changes in every catalog recipe family, while catalog default rows call `Rendro.Theme.default()` rather than the recipes' nil/no-theme path. Every fresh deterministic source render exactly matches the restored candidate and differs from the canonical source-PDF; every resulting PNG also differs. The exact two-hash classifier therefore correctly places all cells in changed buckets.
fix:
  No implementation fix applied: changing the predicate, reclassifying the rows, regenerating/rebinding canonical assets, or redefining default rows as nil-theme controls would conceal genuine drift or require an authorized product/baseline policy change.
verification:
  - `mix run -e 'IO.inspect(Rendro.Catalog.check())'`: 32/32 committed catalog source-PDF identities are stale; no PNG artifact mismatch was reported.
  - fresh in-memory deterministic `Rendro.Catalog.render_source_pdf/1`: 32/32 hashes exactly equal the restored candidate source-PDF hashes.
  - candidate/canonical matrix: 32/32 source-PDF drift plus 32/32 PNG drift; 0 raster-only rows; 0 unchanged rows.
  - `mix test` six recipe byte-identity suites: 15 tests, 0 failures.
files_changed: []
