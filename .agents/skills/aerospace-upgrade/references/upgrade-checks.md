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
| Configuration | Live TOML against target version: root/options, modes and keymaps, every binding/command, callbacks, all `on-window-detected` rules, gaps/assignments and exec-env interpolation | Exact live-file target-parser sweep; zero errors/warnings. Save counts and command/result. Target server dry-run is a separate cutover gate. |
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

## Live configuration sweep

For a version upgrade, enumerate the live TOML structurally without printing
values, then check each category against the target parser/docs. Include:

1. Version and every top-level/nested option (unknown keys are errors).
2. Key-mapping, every mode and binding, and every command string/list. The
   target config parser uses the target command/shell parser for these values.
3. All callbacks and every `on-window-detected` entry; check target-required
   predicates and deprecated/removed forms.
4. Gaps, monitor assignments, and `exec.env-vars`, including variable
   interpolation using the actual app environment.
5. External consumers of changed commands/flags/output (for example
   Sketchybar and companion scripts).

Run `AppBundle.parseConfig` on the **exact live file** in a target-version test
harness and require zero errors and warnings. When an XCTest substitutes a
minimal environment, supply only the live app's required `HOME`/`USER` values;
record that test-only accommodation. This proves offline parser compatibility,
not server/runtime compatibility. At cutover, run the target server's
`aerospace reload-config --dry-run --no-gui --warnings-as-errors` and record
that as a separate result. Summarize the sweep in a small table with category,
coverage count, result and evidence; list only exceptions below it.

When validating the config offline with `AppBundle.parseConfig` under XCTest,
note that its unit-test environment substitutes a minimal `testEnv` without
`HOME` or `USER`. A temporary test can supply the values observed in the
running app's `list-exec-env-vars`; restore all test-only edits afterward.
Record the assumption and still run a full target-server dry-run at cutover.
For local release builds, verify Swift, Ruby, fish, and Xcode availability
before starting; on a Nix-managed Homebrew host prefer ephemeral tool paths
and preserve `mise` on PATH when the build setup sanitizes it.

## Gate and progression

Write a short brief *before* a rebase, release, or switch. Prefer this shape:

```text
Target: <upstream tag> | Installed: <CLI/server> | Scope: <prep/deploy>
Status: <READY / HOLD> — <one sentence>
| Gate | Result | Evidence | Next |
| Config sweep | PASS / HOLD | <test and coverage counts> | <dry-run at cutover> |
| Fork | PASS / HOLD | <commit, tests, CI link> | <release/tag> |
| Nix/companions | PASS / HOLD | <lock SHA, versions, build> | <switch later> |
Blockers: <only actionable blockers; otherwise “None for this stage”>
Next: <one safe action>
```

Save the brief under `runs/<upstream-tag>.md`; resume it rather than restarting.
Keep the summary to about one screen. Retain a compact evidence table with
observed SHAs, branch/worktree, exact decisive checks and results, plus links
to upstream docs/CI. Record changed paths/commits, actual blockers and owners,
and rollback/next action. Move low-value chronology and full logs elsewhere;
never paste private config values or secrets. Separate PASS, DEFERRED and
BLOCKED. Recheck refs, installed versions and worktree status before resuming.

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
