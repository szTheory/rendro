#!/bin/bash
branch=$(git branch --show-current)
test -n "$branch" || { echo "Detached HEAD is not supported for review-fix (#2686)"; exit 1; }

phase_dir=".planning/phases/109-caching-setup-beam"
padded_phase="109"

sentinel="$phase_dir/.review-fix-recovery-pending.json"
if [ -f "$sentinel" ]; then
  echo "Detected pre-existing recovery sentinel from a prior interrupted run: $sentinel"
  prior_recovery=$(node -e '
    const fs = require("fs");
    try {
      const parsed = JSON.parse(fs.readFileSync(process.argv[1], "utf-8"));
      process.stdout.write((parsed.worktree_path || "") + "\n" + (parsed.reviewfix_branch || ""));
    } catch (err) {
      process.stderr.write("Warning: malformed recovery sentinel " + process.argv[1] + ": " + err.message + "\n");
      process.stdout.write("\n");
    }
  ' "$sentinel")
  prior_wt=$(printf '%s' "$prior_recovery" | sed -n '1p')
  prior_branch=$(printf '%s' "$prior_recovery" | sed -n '2p')
  if [ -n "$prior_wt" ] && git worktree list --porcelain | grep -q "^worktree $prior_wt$"; then
    echo "Removing orphan worktree from prior run: $prior_wt"
    git worktree remove "$prior_wt" --force || true
  fi
  if [ -n "$prior_branch" ]; then
    echo "Removing orphan reviewfix branch from prior run: $prior_branch"
    git branch -D "$prior_branch" 2>/dev/null || true
  fi
  rm -f "$sentinel"
fi

wt=$(mktemp -d "/tmp/sv-$padded_phase-reviewfix-XXXXXX")

reviewfix_branch="gsd-reviewfix/$padded_phase-$$"
git worktree add -b "$reviewfix_branch" "$wt" "$branch"

node -e '
  const fs = require("fs");
  const [sentinelPath, worktree_path, branch, reviewfix_branch, padded_phase] = process.argv.slice(1);
  fs.writeFileSync(sentinelPath, JSON.stringify({
    worktree_path,
    branch,
    reviewfix_branch,
    padded_phase,
    started_at: new Date().toISOString()
  }, null, 2));
' "$sentinel" "$wt" "$branch" "$reviewfix_branch" "$padded_phase"

echo "WORKTREE_DIR=$wt"
