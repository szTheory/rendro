---
phase: 82-1-0-0-consolidation-and-publish
plan: 03
type: execute
status: completed
---

<summary>
The irreversible `v1.0.0` Hex publish sequence was successfully executed. The `v1.0.0` tag was pushed, triggering the GitHub Actions CI pipeline which ran the preflight checks and completed the Hex publish.
</summary>

<results>
- `rendro 1.0.0` is published to Hex and permanently live.
- Fixed a CI hang issue by correctly passing the `HEX_API_KEY` to the `mix release.preflight` step.
- Fixed a deps audit issue by passing the `.mix_audit.ignore` file to the audit command in the preflight checks.
</results>
