# API Coverage — Hex and GitHub read-only adoption snapshot

> Full coverage by default within Phase 131's bounded, read-only snapshot surface. Opt-outs are explicit, reasoned decisions.

| capability | decision | reason |
|---|---|---|
| hex-package-metadata | INTEGRATE | |
| hex-download-totals | INTEGRATE | |
| hex-release-version-list | INTEGRATE | |
| hex-package-contents-inspection | INTEGRATE | |
| hexdocs-version-and-source-verification | INTEGRATE | |
| hex-registry-mutation-from-snapshot | OPT-OUT | The snapshot is read-only; publication remains exclusively in the protected tag-driven release workflow after explicit approval. |
| github-issue-list-and-search | INTEGRATE | |
| github-merged-pr-list-and-search | INTEGRATE | |
| github-bounded-candidate-metadata | INTEGRATE | |
| github-issue-or-pr-body-retention | OPT-OUT | Bounded evidence retains metadata, URLs, digests, and classification reasons but excludes raw bodies and unnecessary reporter content. |
| github-label-comment-or-record-mutation | OPT-OUT | Phase 131 forbids GitHub mutation, labeling, outreach, and analytics. |
| recurring-pagination-or-polling | OPT-OUT | The phase takes one explicitly bounded snapshot with recorded query and page limit, not a recurring observer. |

