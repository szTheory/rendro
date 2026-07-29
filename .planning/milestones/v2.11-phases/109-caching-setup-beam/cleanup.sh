#!/bin/bash
main_repo=$(git worktree list --porcelain | awk '/^worktree / { sub(/^worktree /, ""); print; exit }')
ff_status=0
if git -C "$main_repo" merge --ff-only "gsd-reviewfix/109-13765" 2>&1; then
  ff_status=0
else
  ff_status=$?
  echo "WARN: could not fast-forward to gsd-reviewfix/109-13765 (exit $ff_status)."
fi

git worktree remove "/tmp/sv-109-reviewfix-OLTSwi" --force

if [ "$ff_status" -eq 0 ]; then
  git -C "$main_repo" branch -D "gsd-reviewfix/109-13765" || true
fi

rm -f .planning/phases/109-caching-setup-beam/.review-fix-recovery-pending.json
