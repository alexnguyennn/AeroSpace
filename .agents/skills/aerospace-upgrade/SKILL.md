---
name: aerospace-upgrade
description: >-
  Assesses and executes an AeroSpace fork upgrade against the latest fetched
  upstream release tag. Compares breaking changes and config syntax with the
  live chezmoi-managed aerospace.toml, checks aerospace-marks and
  aerospace-scratchpad socket compatibility, updates their nix-config flake
  locks, rebuilds nix-darwin, and verifies installed and running versions.
  Use for upgrade AeroSpace, check latest upstream tag, version drift, config
  migration, upgrade gaps or blockers, sync companion tools, or end-to-end bump.
---

# AeroSpace upgrade

**Purpose** — Take the fork, live configuration, companion tools, and running
app through one compatible upgrade. For rebase details use
`aerospace-upstream-rebase`; for release/installation details use
`aerospace-release-ops`. This skill owns the cross-repository readiness gates.

**Discover** — Read [references/upgrade-checks.md](references/upgrade-checks.md).
Record repo/worktree status and local changes first. Fetch upstream tags, then
choose the latest applicable release tag (include Beta when already on Beta).
Determine the actual fork base, installed CLI and app, running server, live
config path/source, Nix input locks, and host flake target; never infer any of
these from a previous run or a sample config.

**Record** — Create or resume `runs/<upstream-tag>.md` using the fields in the
reference. Lead with a short status and a compact gate table; keep one row per
area, link or name the decisive evidence, and call out deferred checks. Put only
material blockers, changes and the next safe action in the summary. Keep long
logs and repeated command output out of the run note. Commit the record after
material gates so later sessions can resume from evidence and refresh stale facts.

**Assess** — Compare *every intervening release* and relevant upstream commits,
especially `BREAKING CHANGE`, config version/parser/defaults, CLI flags and
exit codes, socket protocol, and fork patch touchpoints. Compare affected
keys, callbacks, bindings, external scripts, and integrations with the live
config and its source. Check both companion projects' compatibility guides,
locked revisions, current upstream refs, and Nix package buildability.
Publish a brief with evidence, actionable gaps, blockers, owner, and next
verification before changing versions.

**Resolve** — Fix blockers in dependency order: source-managed config and
scripts; fork rebase/build and release; update only the `aerospace-*` entries
in the Nix flake lock, then evaluate/build the host without switching; finally,
deployment. Reassess after each fix, limiting failed
attempts per issue to three. Preserve unrelated work; use a worktree for fork
rebases or isolate Nix changes when the existing checkout is dirty. Get the
required confirmation for release and local replacement via the release skill.
Do not bypass a blocked authentication prompt or silently install a mismatched
combination.

**Deploy and verify** — Install both CLI and app from the same fork release,
update the Nix-owned brew cask and companion inputs, rebuild the correct
darwinConfiguration, restart the app, and verify CLI/server version alignment.
Run the target version's config dry-run and companion compatibility checks;
exercise relevant bindings and integrations. Keep backups and a rollback path.
Report hashes, versions, test evidence, remaining blockers and next action.

**Success** — Target fork release builds; live config validates under that
version; companion tools are compatible and Nix-pinned; deployed CLI and
running server agree; no blocker remains. For prepare-only runs, leave a
versioned record that clearly marks release/deployment as pending and names
their prerequisites.

**Test** — Replay a 0.20→0.21 upgrade with a managed TOML, a dirty Nix checkout,
and a socket-protocol change. Confirm that the first actions are fetch,
inventory, and compatibility brief, with deployment gated on validation.
If a replay skips a gate, tighten this skill and retest.

**Self-improvement** — Record any missed compatibility class or misleading
command in the reference after verifying it against the real upstream source.
