# AeroSpace Fork — Agent Instructions

This is a fork of [nikitabobko/AeroSpace](https://github.com/nikitabobko/AeroSpace) maintained at `alexnguyennn/AeroSpace` on branch `rr/customise`.

## Key Context

- `sync-with-upstream.org` — manual sync steps, bundle ID configuration, build process
- `FLOATING_WINDOW_FOCUS_BUG.md` — analysis and implementation plan for `--dfs-order` flag
- `windowlist.patch` — reference patch for the sort removal change

## Skills

- `.agents/skills/aerospace-upstream-rebase/` — rebase fork onto new upstream release, resolve conflicts, tag, push, update brew. Triggers: upstream sync, bump aerospace, update fork.
- `.opencode/skills/aerospace-release-ops/` — end-to-end release lifecycle: tag, CI monitoring, failure fan-out, brew tap update, local artifact install, branch build verification. Triggers: release, cut release, tag build, watch build, brew tap update, install aerospace, deploy build, ship it, download build, local install.

## Agents

- `.opencode/agents/release.md` — orchestrates the release pipeline using `github-copilot/gpt-5.4-mini`, fans out `github-copilot/claude-sonnet-4.6` subtasks for build failure diagnosis and fixes. Invoke with `@release`.

## Build

- `./build-release.sh` builds the release artifact
- `./generate.sh` regenerates the Xcode project from `project.yml` (do not edit `.xcodeproj` directly)
- CI: `.github/workflows/build.yml` (manual trigger)

## Fork Patch Policy

Keep patches minimal — every changed line is a future merge conflict. See `.agents/skills/aerospace-upstream-rebase/references/known-patches.md` for the current patch inventory.
