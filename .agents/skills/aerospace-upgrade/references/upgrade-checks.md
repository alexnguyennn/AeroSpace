# Upgrade checks and execution evidence

## Inventory and selection

- Use `CI=true` for git/gt operations. Inspect status in the AeroSpace fork and
  `~/bench/cfg/nix-config` before edits. Do not reset or stash user changes.
- Fetch tags from `upstream` (`nikitabobko/AeroSpace`) before sorting `v*` tags
  by version. Exclude fork `-alex` tags. Read upstream release notes with `gh`
  and inspect `git log` between the actual base tag and target, including
  intervening Beta releases. Determine base from ancestry, not `HEAD` or the
  name of a branch. Check whether current branch is a staging branch and
  whether `rr/customise` differs from it.
- Read versions from `aerospace --version` (both CLI and server), app Info.plist,
  `pgrep`, installed cask (`brew info`), and the fork release/tag. Check for
  multiple binaries/apps before replacing anything.
- Read the live path from `aerospace config --config-path` and resolve its
  source manager (for example `chezmoi source-path`). If chezmoi-managed, use
  the `chezmoi` skill to classify template/encryption and update its source;
  check rendered diff and live result. Search invoked scripts and other
  consumers (for example Sketchybar) for changed CLI flags/output.

## Compatibility matrix

| Area | Compare against target | Proof |
| --- | --- | --- |
| Configuration | `docs/config-examples/default-config.toml`, guide, parser, config-version, live keys, callbacks, bindings and shell quoting | Target `aerospace reload-config --dry-run --no-gui --warnings-as-errors`; version-specific flags only after checking help |
| Commands | Breaking commits, changed flags/exit codes, fork `--dfs-order` and external scripts | Target CLI help/tests and representative read-only commands; scope `--dfs-order` with e.g. `--workspace <workspace> --dfs-order` (`--all` conflicts with it) |
| Socket clients | Companion READMEs/releases and source against target protocol; do not assume latest is backward-compatible | Companion `info`/version or smoke command against *running* target |
| Nix | `flake.nix` refs and `flake.lock` revisions for `aerospace-marks` and `aerospace-scratchpad`; brew cask declaration and local diff | Update only those inputs with `nix flake update aerospace-marks aerospace-scratchpad` or supported `--update-input` syntax, evaluate/build the host derivation before switch |
| Deployment | Fork release artifact, cask SHA, app/CLI backup, currently running server | App and CLI same tag; `aerospace --version`; config dry-run, companions and binding smoke checks |

Check the companion source at the **locked revision** as well as at the desired
revision. Inspect `nix/package-default.nix` to confirm the package selected by
`packages.<system>.default`; the `nightly` ref name alone does not identify the
installed package. The two `nightly` refs can move independently; record both
SHAs and the target AeroSpace compatibility stated by each project. A new lock
does not mean the running companion binary has changed: verify installed
versions and socket compatibility before switching or restarting. If a latest
version is incompatible with the installed server, arrange a coordinated
cutover.
Never update every flake input for a two-input upgrade.

## Gate and progression

Write a brief *before* a rebase, release, or switch:

```text
Target: upstream tag, fork base/tag, installed CLI/app/running server
Gaps: changed behavior → live usage → proposed source edit and verification
Companions: locked → candidate marks/scratchpad SHAs, supported protocol
Blockers: concrete failure → resolution owner → next check
Sequence: config source → fork build/release → Nix locks/build → coordinated install/switch/restart → smoke
```

Save the brief under `runs/<upstream-tag>.md` in this skill. Resume that file
on subsequent sessions instead of starting over. Include a dated as-of line,
stage checklist, exact observed tag/SHAs, `git` branches/worktrees and dirty
state, documentation and upstream release URLs, config keys examined, commands
and exit statuses, changed paths/commits, unresolved blockers with owners and
attempt counts, safe next commands, and rollback notes. Distinguish observed
results from assumptions; never paste tokens, secrets, or private config
contents into the record. Check current refs, installed versions and checkout
status again before continuing. Commit the record after material progress so
it survives sessions.

Then fix each gap and update the brief/plan. Use the repo's
`aerospace-upstream-rebase` skill for fork conflict handling and
`aerospace-release-ops` for CI, cask and local installation. Verify fork
patches against the target's refactored code rather than mechanically applying
old hunks. The Nix origin may be encrypted (`git-remote-gcrypt`): a cancelled
GPG prompt blocks remote fetch but does not invalidate local inspection;
resolve interactively when a remote operation is actually required.

For a Nix-managed macOS host, evaluate/build its `darwinConfigurations` output
and deploy via the repo's documented `nh darwin switch -v .` workflow from the
Nix checkout, using the selected host if needed. Do not mix a manual binary
swap with a later brew switch without verifying which source owns both paths.
Restart AeroSpace only after validated config and matching companion binaries
are ready; after switch, check server and CLI versions again. If the new CLI is
installed but the server reports `Unknown` or does not respond, inspect
`xattr -lr /Applications/AeroSpace.app`; Homebrew can leave nested quarantine
attributes behind. Use the recursive removal in the release skill's
[local-install guide](../../aerospace-release-ops/references/local-install.md),
then relaunch and recheck the server. Keep an installation rollback
(cask/app/CLI and prior lockfile) until smoke checks pass.
