#!/usr/bin/env bash
set -e

echo "Running Repository Hygiene Check..."

# 1. Check for uncommitted changes
if ! git diff --quiet; then
  echo "❌ Error: Working tree has unstaged changes."
  git status -s
  exit 1
fi

if ! git diff --cached --quiet; then
  echo "❌ Error: Working tree has staged but uncommitted changes."
  git status -s
  exit 1
fi

# 2. Check for untracked files
untracked_files=$(git ls-files --others --exclude-standard)
if [ -n "$untracked_files" ]; then
  echo "❌ Error: Untracked files found in working tree."
  echo "$untracked_files"
  exit 1
fi

# 3. Check for orphaned GSD handoff/debug files
found_orphans=0
for file in .planning/HANDOFF.json .planning/continue-here.md; do
  if [ -f "$file" ]; then
    echo "❌ Error: Orphaned file found: $file"
    found_orphans=1
  fi
done

for file in .planning/phases/*/.continue-here.md .planning/phases/*/*HANDOFF*.md; do
  # Check if the glob actually expanded to a real file
  if [ -f "$file" ]; then
     echo "❌ Error: Orphaned file found: $file"
     found_orphans=1
  fi
done

if [ "$found_orphans" -eq 1 ]; then
  exit 1
fi

# 4. Check CI / Specs (this runs the gauntlet defined in mix.exs)
echo "Running mix ci gauntlet..."
if ! mix ci; then
    echo "❌ Error: 'mix ci' failed. The repository is not in a clean state."
    exit 1
fi

echo "✅ Repository Hygiene Check Passed! Repo is clean."
