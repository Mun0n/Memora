#!/usr/bin/env bash
# One-command local MVP implementation. Creates local commits; never pushes or deploys.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
START_SLICE="${1:-3}"
MVP_SLICES=(3 4 5 6)

[[ "$START_SLICE" =~ ^[3-6]$ ]] || {
  echo "Usage: ./scripts/run_mvp.sh [3|4|5|6]" >&2
  exit 2
}

[[ -z "$(git status --porcelain)" ]] || {
  echo "ERROR: start the MVP run from a clean working tree" >&2
  exit 1
}

for slice in "${MVP_SLICES[@]}"; do
  spec="specs/SLICE_$(printf '%02d' "$slice").md"
  [[ -f "$spec" ]] || { echo "ERROR: missing $spec" >&2; exit 1; }
done

branch="$(git branch --show-current)"
case "$branch" in
  mvp/autonomous-*) ;;
  *)
    branch="mvp/autonomous-$(date +%Y%m%d-%H%M%S)"
    git switch -c "$branch"
    ;;
esac

echo "MEMORA AUTONOMOUS MVP"
echo "Branch: $branch"
echo "Slices: 3 → 4 → 5 → 6 (starting at $START_SLICE)"
echo "The run creates local checkpoint commits and never pushes or deploys."

./scripts/validate.sh

for slice in "${MVP_SLICES[@]}"; do
  [[ "$slice" -ge "$START_SLICE" ]] || continue
  echo "Starting Slice $slice"
  MEMORA_MVP_RUN=1 ./scripts/run_slice.sh "$slice" --auto-continue

  git add -A -- apps packages backend tool docs/current scripts/validate.sh
  if git diff --cached --quiet; then
    echo "ERROR: Slice $slice produced no checkpointable changes" >&2
    exit 1
  fi
  git commit -m "feat: complete autonomous MVP Slice $slice"
done

./scripts/validate.sh
echo "MVP_REVIEW"
echo "Branch $branch contains the integrated local MVP candidate. Nothing was pushed or deployed."
