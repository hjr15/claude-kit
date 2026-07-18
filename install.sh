#!/usr/bin/env bash
#
# claude-kit installer.
#
# Symlinks this repo's skills and agents into ~/.claude/ so Claude Code finds
# them. That is all it does: no settings merge, no memory, no hooks.
#
# Usage:
#   bash install.sh                    # install (idempotent — safe to re-run)
#   bash install.sh --check            # report drift, write nothing, exit 1 if drifted
#   bash install.sh --list             # print available bundles, write nothing
#   bash install.sh --bundle a,b       # install only items in bundle a or b
#
# Symlinks, not copies: `git pull` then takes effect immediately, with no
# reinstall step.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
AGENTS_SRC="$REPO_DIR/agents"
SKILLS_TARGET="$HOME/.claude/skills"
AGENTS_TARGET="$HOME/.claude/agents"
MANIFEST="$REPO_DIR/bundles.tsv"

# ── Argument parsing (order-independent) ────────────────────────────────
#
# --check          report drift, write nothing
# --list           print available bundles, write nothing
# --bundle a,b     restrict to items whose bundle set intersects the request
#
# A real while-loop over "$@" so any combination/order works — e.g.
# `--bundle git --check` and `--check --bundle git` are equivalent, and
# `--bundle` filters `--check` no matter which flag comes first.
CHECK_MODE=0
LIST_MODE=0
BUNDLE_FILTER=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      CHECK_MODE=1
      shift
      ;;
    --list)
      LIST_MODE=1
      shift
      ;;
    --bundle)
      [[ -n "${2:-}" ]] || { echo "--bundle needs a comma-separated list" >&2; exit 2; }
      BUNDLE_FILTER="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1 (supported: --check, --list, --bundle <name>[,<name>])" >&2
      exit 2
      ;;
  esac
done

if [[ -n "$BUNDLE_FILTER" ]]; then
  [[ -f "$MANIFEST" ]] || { echo "no bundles.tsv in this kit" >&2; exit 2; }
  # validate every requested bundle exists
  valid=$(cut -f3 "$MANIFEST" | tr ',' '\n' | sed '/^$/d' | sort -u)
  IFS=',' read -ra req <<< "$BUNDLE_FILTER"
  for r in "${req[@]}"; do
    grep -qx "$r" <<< "$valid" || { echo "unknown bundle: $r" >&2; echo "valid: $(tr '\n' ' ' <<< "$valid")" >&2; exit 2; }
  done
fi

if [[ $LIST_MODE -eq 1 ]]; then
  [[ -f "$MANIFEST" ]] || { echo "no bundles.tsv in this kit" >&2; exit 2; }
  echo "Available bundles (install with: bash install.sh --bundle <name>[,<name>]):"
  cut -f3 "$MANIFEST" | tr ',' '\n' | sed '/^$/d' | sort -u | while read -r b; do
    n=$(awk -F'\t' -v b="$b" '{split($3,a,","); for(i in a) if(a[i]==b) c++} END{print c+0}' "$MANIFEST")
    printf '  %-14s %s item(s)\n' "$b" "$n"
  done
  exit 0
fi

# in_selected_bundle NAME — true when no --bundle filter is active, or NAME
# shares at least one bundle with the request.
in_selected_bundle() {
  [[ -z "$BUNDLE_FILTER" ]] && return 0
  local row; row=$(awk -F'\t' -v n="$1" '$1==n{print $3}' "$MANIFEST")
  IFS=',' read -ra want <<< "$BUNDLE_FILTER"
  IFS=',' read -ra have <<< "$row"
  for w in "${want[@]}"; do for h in "${have[@]}"; do [[ "$w" == "$h" ]] && return 0; done; done
  return 1
}

drift=0
note() {
  echo "  drift: $1"
  drift=1
}

# Is $1 already the symlink we would create for source $2?
is_linked() {
  local target="$1" src="$2"
  [[ -L "$target" ]] || return 1
  [[ "$(readlink -f "$target" 2>/dev/null || true)" == "$(readlink -f "$src")" ]]
}

# Enumerate (target_name, source_path) pairs, NUL-safe.
#
# Skills land FLAT in ~/.claude/skills/<name>: the category folders
# (skills/workflow/, skills/meta/, …) are a repo-side filing concern, while
# Claude Code's skill namespace is flat.
each_skill() {
  [[ -d "$SKILLS_SRC" ]] || return 0
  find "$SKILLS_SRC" -mindepth 2 -maxdepth 3 -name SKILL.md -type f -print0 |
    while IFS= read -r -d '' skill_md; do
      local dir
      dir="$(dirname "$skill_md")"
      printf '%s\t%s\n' "$(basename "$dir")" "$dir"
    done
}

each_agent() {
  [[ -d "$AGENTS_SRC" ]] || return 0
  find "$AGENTS_SRC" -mindepth 1 -maxdepth 1 -name '*.md' -type f -print0 |
    while IFS= read -r -d '' agent; do
      printf '%s\t%s\n' "$(basename "$agent")" "$agent"
    done
}

run_check() {
  local name src
  while IFS=$'\t' read -r name src; do
    in_selected_bundle "$name" || continue
    is_linked "$SKILLS_TARGET/$name" "$src" || note "skill '$name' not linked in $SKILLS_TARGET"
  done < <(each_skill)

  while IFS=$'\t' read -r name src; do
    in_selected_bundle "${name%.md}" || continue
    is_linked "$AGENTS_TARGET/$name" "$src" || note "agent '$name' not linked in $AGENTS_TARGET"
  done < <(each_agent)

  if [[ $drift -eq 0 ]]; then
    echo "install.sh --check: no drift — live deployment matches the repo."
  else
    echo "install.sh --check: drift detected — re-run: bash install.sh" >&2
  fi
  return $drift
}

if [[ $CHECK_MODE -eq 1 ]]; then
  run_check
  exit $?
fi

# ── Pre-flight: refuse to clobber anything that isn't ours ────────────────────
#
# `ln -sfn SRC DIR` does NOT replace a real directory — it silently creates
# DIR/<name> *inside* it and exits 0. So a stranger with their own hand-written
# ~/.claude/skills/foo/ would see "linked N skills", get no skill installed, and
# find a stray nested symlink in their work. Exit 0 on a silent no-op is the
# worst outcome here, so scan first and refuse as a whole rather than
# half-installing.
conflicts=()
check_conflict() {
  local target="$1"
  # A symlink (ours, stale, or dangling) is ours to replace. Anything else is theirs.
  if [[ -e "$target" && ! -L "$target" ]]; then
    conflicts+=("$target")
  fi
}

while IFS=$'\t' read -r name _src; do
  in_selected_bundle "$name" || continue
  check_conflict "$SKILLS_TARGET/$name"
done < <(each_skill)
while IFS=$'\t' read -r name _src; do
  in_selected_bundle "${name%.md}" || continue
  check_conflict "$AGENTS_TARGET/$name"
done < <(each_agent)

if ((${#conflicts[@]})); then
  echo "install.sh: refusing to overwrite existing files that are not claude-kit symlinks:" >&2
  printf '  %s\n' "${conflicts[@]}" >&2
  echo >&2
  echo "Move or remove them, then re-run. Nothing has been changed." >&2
  exit 1
fi

mkdir -p "$SKILLS_TARGET" "$AGENTS_TARGET"

skills_n=0
while IFS=$'\t' read -r name src; do
  in_selected_bundle "$name" || continue
  # -n so an existing symlink-to-a-directory is REPLACED rather than being
  # followed and nested inside itself; -f so a stale link is overwritten.
  ln -sfn "$src" "$SKILLS_TARGET/$name"
  skills_n=$((skills_n + 1))
done < <(each_skill)

agents_n=0
while IFS=$'\t' read -r name src; do
  in_selected_bundle "${name%.md}" || continue
  ln -sfn "$src" "$AGENTS_TARGET/$name"
  agents_n=$((agents_n + 1))
done < <(each_agent)

echo "claude-kit: linked $skills_n skill(s) → $SKILLS_TARGET"
echo "claude-kit: linked $agents_n agent(s) → $AGENTS_TARGET"
echo
echo "Start (or restart) Claude Code and they will be available."
