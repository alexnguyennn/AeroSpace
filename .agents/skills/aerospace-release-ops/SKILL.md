---
name: aerospace-release-ops
description: >-
  AeroSpace fork release lifecycle: tag releases, monitor CI via gh, fan out
  failure fixes to subtasks, update brew cask at alexnguyennn/tap, download
  and locally install release or branch build artifacts with backup.
  Triggers: release, cut release, tag build, watch build, monitor CI,
  brew tap update, install aerospace, deploy build, ship it, download build,
  local install, branch build, verify build, artifact URL.
---

# Skill: aerospace-release-ops

## Purpose

End-to-end release ops for `alexnguyennn/AeroSpace` fork.

## When to Use

- Cutting a release from `rr/customise` or `rr/customise-update`
- Watching a CI build (branch or tag) to green
- Fixing a broken CI build
- Updating `alexnguyennn/tap` brew cask after release
- Downloading and installing artifacts locally
- Verifying a branch build before tagging

**Not for**: upstream syncs (use `aerospace-upstream-rebase`), unrelated code changes.

## Default Path

- Confirm intent via question tool
- For releases: verify green branch build → tag → push → monitor → brew tap
- For local install: download artifact → confirm backup plan → execute swap
- For failures: fan out subtask to diagnose/fix → re-monitor

## Execution

**Auth gate** — Run `gh auth status` before any `gh` command. If auth fails,
prompt user. Exceptions: direct-URL install (curl), brew tap push (git).

**Confirm** — Question tool: full release pipeline | branch build + watch |
brew tap update only | local install only.

**Tag and release** — `references/release-workflow.md`

**Fix failures** — Fetch logs with `gh run view <id> --repo alexnguyennn/AeroSpace --log-failed`,
diagnose, apply minimal fix, push, re-monitor. Fan out to subtask for code fixes.

**Update brew** — `references/brew-tap-update.md` (tap: `alexnguyennn/tap`)

**Local install** — `references/local-install.md` (accepts tag, run ID, or direct URL).
Always confirm before executing.

**Branch build** — Push branch, watch, retrieve artifact URL from `gh run view`.

## Success Criteria

- Release builds pass all matrix jobs (macos-14, macos-15, macos-26)
- GitHub release has `.zip` and `aerospace.rb` assets
- Brew tap `Casks/aerospace.rb` updated and pushed to `alexnguyennn/tap`
- Local install: apps replaced, `.bk` backup exists
- User informed with URLs and paths

## Companion Files

- `references/release-workflow.md` — tagging, CI monitoring, verification
- `references/brew-tap-update.md` — cask update for `alexnguyennn/tap`
- `references/local-install.md` — download, backup, install

## Constraints

- **DO** confirm destructive ops (app replace, tag overwrite) with user
- **DO** verify builds green before next phase
- **DO** use `--force-with-lease` for branch pushes after rebase
- **DO NOT** force-push `main` or upstream branches
- **DO NOT** skip CI verification before tagging
- **DO NOT** replace local binaries without `.bk` backups

## Output Format

```
Release: v{version}
CI: {run_url} — {status}
Brew: alexnguyennn/tap@{commit_sha}
Install: /Applications/AeroSpace.app (backup: .bk)
```

## Self-Improvement

After each release, note failure modes, CI matrix changes, or artifact structure shifts:

```
[YYYY-MM-DD] operation — discovery — context
```
