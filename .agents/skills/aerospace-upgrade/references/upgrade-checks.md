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
| Configuration | `docs/config-examples/default-config.toml`, guide, parser, config-version, live keys, callbacks, bindings and shell quoting | Offline target-parser test before deployment; target `aerospace reload-config --dry-run --no-gui --warnings-as-errors` after cutover |
| Commands | Breaking commits, changed flags/exit codes, fork `--dfs-order` and external scripts | Target CLI help/tests and representative read-only commands |
| Socket clients | Companion READMEs/releases and source against target protocol; do not assume latest is backward-compatible | Companion `info`/version or smoke command against *running* target |
| Nix | `flake.nix` refs, `flake.lock` revisions and each locked input's actual `packages.<system>.default` version, plus cask declaration and local diff | Update only those inputs with `nix flake update aerospace-marks aerospace-scratchpad`; confirm only `aerospace-*` lock nodes changed, then `nix build .#darwinConfigurations.<host>.system --no-link` before switch |
| Deployment | Fork release artifact, cask SHA, app/CLI backup, currently running server | App and CLI same tag; `aerospace --version`; config dry-run, companions and binding smoke checks |

Check the companion source at the **locked revision** as well as at the desired
revision. The two `nightly` refs can move independently; record both SHAs and
the default package versions and target AeroSpace compatibility stated by each
project. A lock may already point to a newer incompatible package even while
the machine still runs an older binary. If a latest version
is incompatible with the installed server, arrange a coordinated cutover.
Never update every flake input for a two-input upgrade. The Nix preparation
does not require fetching the checkout's Git origin: update the two flake
inputs in the isolated worktree and verify the resulting `flake.lock` diff
before building. Do not edit `flake.nix` or unrelated Homebrew roles as part
of this preparation.

When validating the config offline with `AppBundle.parseConfig` under XCTest,
note that its unit-test environment substitutes a minimal `testEnv` without
`HOME` or `USER`. A temporary test can supply the values observed in the
running app's `list-exec-env-vars`; restore all test-only edits afterward.
Record the assumption and still run a full target-server dry-run at cutover.
For local release builds, verify Swift, Ruby, fish, and Xcode availability
before starting; on a Nix-managed Homebrew host prefer ephemeral tool paths
and preserve `mise` on PATH when the build setup sanitizes it.

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
 old hunks. Do not fetch the encrypted Nix Git origin for the lock-update/build
 workflow; remote operations belong to a separate publishing decision.

For a Nix-managed macOS host, evaluate/build its `darwinConfigurations` output
and deploy via the repo's documented `nh darwin switch -v .` workflow from the
Nix checkout, using the selected host if needed. Do not mix a manual binary
swap with a later brew switch without verifying which source owns both paths.
Restart AeroSpace only after validated config and matching companion binaries
are ready; after switch, check server and CLI versions again. Keep an
installation rollback (cask/app/CLI and prior lockfile) until smoke checks pass.
