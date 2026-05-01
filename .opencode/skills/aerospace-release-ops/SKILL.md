---
name: aerospace-release-ops
description: >-
  AeroSpace fork release operations: tag and push releases, monitor CI
  builds via gh, fix failures with subtask fan-out, update brew cask tap
  at alexnguyennn/tap, download and locally install release or branch
  build artifacts with backup. Triggers on: release, cut release, tag
  build, watch build, monitor CI, brew tap update, install aerospace,
  deploy build, ship it, download build, local install, branch build,
  verify build, artifact URL.
---

# Skill: aerospace-release-ops

## Purpose

End-to-end release operations for the `alexnguyennn/AeroSpace` fork.
Covers tagging, CI monitoring, failure recovery, brew cask updates,
branch build verification, and local artifact installation.

## When to Use

- Cutting a release from `rr/customise` or `rr/customise-update`
- Watching a CI build (branch or tag) to green
- Fixing a broken CI build
- Updating the `alexnguyennn/tap` brew cask after a release
- Downloading and installing a release or branch build artifact locally
- Verifying a branch build before tagging a release

**Not for**: upstream syncs or rebase operations (use `aerospace-upstream-rebase`),
code changes unrelated to the release pipeline.

## Default Path

- Confirm user intent via the question tool
- For releases: verify green branch build, tag, push tag, monitor release build, update brew tap
- For local install: download artifact, confirm backup plan with user, execute swap
- For failures: fan out a subtask to diagnose and fix, then re-monitor

## Execution

**Check gh auth** -- Before any `gh` command, verify authentication:
```bash
gh auth status
```
If not authenticated or the token lacks access to `alexnguyennn/AeroSpace`,
prompt the user to run `gh auth login` or set `GH_TOKEN` with a token that
has repo access. Do NOT proceed with gh-dependent operations until auth is confirmed.

**Exceptions (no gh auth needed):**
- Local install from a direct artifact URL -- uses `curl`
- Brew tap update -- uses `git push` on the local tap repo

**Confirm** -- Use the question tool to determine which operation the user wants.
Offer: full release pipeline, branch build + watch, brew tap update only,
local install only.

**Verify pre-release** -- Before tagging, confirm the branch build is green.
If no recent passing build exists, push the branch and monitor first.

**Tag and release** -- Follow `references/release-workflow.md` for the exact
command sequence: determine version tag, `git tag`, `git push origin <tag>`,
`gh run watch`, verify release assets.

**Fix failures** -- If any CI job fails, fetch logs with
`gh run view <id> --repo alexnguyennn/AeroSpace --log-failed`, diagnose the
error, apply a minimal fix, push, and re-monitor. The release agent should
fan this out to a `github-copilot/claude-sonnet-4.6` subtask for code fixes.

**Update brew** -- Follow `references/brew-tap-update.md` to update the cask
version and sha256 in `alexnguyennn/tap`.

**Local install** -- Follow `references/local-install.md` to download, extract,
back up, and replace the local AeroSpace installation. Accepts a release tag,
a run ID, or a direct artifact URL
(e.g. `https://github.com/alexnguyennn/AeroSpace/actions/runs/<id>/artifacts/<id>`).
Always confirm the plan with the user before executing.

**Branch build** -- Push branch, watch build, retrieve artifact URL from
`gh run view` output. Report the URL for manual download/verification.

## Success Criteria

- Release builds pass on all matrix jobs (macos-14, macos-15, macos-26)
- GitHub release exists with `.zip` and `aerospace.rb` assets
- Brew tap `Casks/aerospace.rb` is updated and pushed
- For local install: `/Applications/AeroSpace.app` and `/opt/homebrew/bin/aerospace` replaced, `.bk` backup exists
- User is informed of all outcomes with URLs and paths

## Companion Files

- `references/release-workflow.md` -- step-by-step release tagging, CI monitoring, and release verification
- `references/brew-tap-update.md` -- brew cask update procedure for `alexnguyennn/tap`
- `references/local-install.md` -- download, backup, and install artifacts locally

## Constraints

- **DO** confirm destructive operations (app replacement, tag overwrite) with user
- **DO** verify builds are green before proceeding to next phase
- **DO** use `--force-with-lease` for branch pushes after rebase
- **DO NOT** force-push to `main` or upstream branches
- **DO NOT** skip CI verification before tagging a release
- **DO NOT** replace local binaries without creating `.bk` backups first

## Output Format

```
Release: v{version}
CI: {run_url} -- {status}
Brew: alexnguyennn/tap@{commit_sha}
Install: /Applications/AeroSpace.app (backup: .bk)
```

## Self-Improvement

After each release, note any new failure modes, changed CI matrix runners,
or artifact structure changes here:

```
[YYYY-MM-DD] operation - discovery - context
```
