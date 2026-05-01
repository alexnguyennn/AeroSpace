---
name: aerospace-upstream-rebase
description: >-
  Rebase the rr/customise fork branch onto a new upstream AeroSpace release tag,
  resolve conflicts using known-patch awareness, tag a release, and push. Use for
  upstream sync, rebase on upstream, bump aerospace, update fork, sync upstream,
  merge upstream, pull upstream changes, new aerospace release.
---

<objective>
Rebase `rr/customise` onto a new upstream tag, preserve fork patches, tag, push, update brew.
</objective>

## When to Use

- New upstream AeroSpace release available
- User asks to sync, bump, or update the fork

## Not For

- Implementing new fork patches (do that first, then rebase)
- Upstream PRs or contributions

## Default Path

Treat as a `workflow` skill. Assume `upstream` remote is `nikitabobko/AeroSpace`, `origin`
is the fork. Ask user for target tag only if ambiguous.

## Execution

**Pre-flight** — verify clean worktree, fetch upstream with tags, identify target tag
(latest stable `v*`, skip `-Beta` unless user opts in), compare against current base via
`git merge-base main rr/customise`

**Reset main** — `git checkout main && git reset --hard upstream/<tag> && git push origin main --force-with-lease`

**Rebase** — `git checkout rr/customise && git rebase main`

**Resolve conflicts** — follow `references/known-patches.md` for patch-aware resolution;
cap at 3 attempts per file then escalate to user

**Verify** — build succeeds, `git diff main..rr/customise` shows expected patches,
`git log --oneline main..rr/customise` shows all fork commits

**Tag and push** — `git tag <upstream-ver>-$(git rev-parse --short HEAD)-alex`,
push branch + tags with `--force-with-lease`, monitor CI via `gh run list`

**Update brew** — download release artifact, update `aerospace.rb` in tap repo (`alexnguyennn/tap`) with
release URL, push tap, `nh darwin switch -v .`

## Companion Files

- `references/known-patches.md` — fork patch inventory and conflict resolution strategies
- `sync-with-upstream.org` (repo root) — human-readable sync steps, bundle ID config, build process notes

## Constraints

- **DO** use `--force-with-lease` for all force pushes
- **DO** verify build before tagging
- **DO** stop and ask on non-trivial conflicts
- **DO** keep fork-specific code in **additive new files** where possible (new test files, new source files) to avoid merge conflicts with upstream modifications to existing files
- **DO NOT** skip conflict resolution or bypass hooks

## Success Criteria

- `rr/customise` rebased on target tag with all fork patches intact
- Build passes
- Tagged release pushed, CI green
- Brew formula updated (or user informed to do so)

## Self-Improvement

When a rebase introduces a new conflict pattern, add it to `references/known-patches.md`
so the next run resolves it automatically.
