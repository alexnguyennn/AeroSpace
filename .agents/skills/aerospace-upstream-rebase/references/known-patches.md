# Known Fork Patches

Conflict resolution reference for `rr/customise` branch. When rebasing onto
upstream, preserve these patches by re-applying our minimal diff on top of
upstream's new code.

## Patch Inventory

**Sort removal** (`4ef4f9cb`)
- File: `Sources/AppBundle/command/impl/ListWindowsCommand.swift`
- Change: delete the `_list = _list.sortedBy(...)` line
- Context: upstream sorts `list-windows` output by app name; we remove it so
  window order matches the tiling tree (needed for sketchybar)
- Resolution: if upstream changed surrounding lines, find the `sortedBy` call
  and delete it; if upstream removed it too, no conflict

**DFS-order flag** (`0e29bf81`)
- Files: `ListWindowsCmdArgs.swift`, `ListWindowsCommand.swift`, `FocusCommand.swift`
- Change: add `--dfs-order` bool flag; make `makeFloatingWindowsSeenAsTiling`,
  `restoreFloatingWindows`, and `FloatingWindowData` internal (was `private`);
  add conditional branch in `ListWindowsCommand.run()`
- Resolution: re-apply the flag definition and conditional branch; if upstream
  refactored `FocusCommand`, find the renamed functions and adjust visibility

**Unbound window guard in makeFloatingWindowsSeenAsTiling** (`1306ab55`)
- File: `FocusCommand.swift`
- Change: add `isBound` guards after `await` suspension points to prevent
  crash when concurrent MainActor tasks unbind windows mid-iteration
- Resolution: re-apply guards after any `await` calls in the function

**Custom CI** (`ad81ee93`, `c05553ac`, `b6dcb5b3`)
- File: `.github/workflows/build.yml`
- Change: our entire CI workflow (manual trigger, artifact upload)
- Resolution: always keep ours — `git checkout --ours .github/workflows/build.yml`

**Docs** (`d3d9c60f`)
- File: `sync-with-upstream.org`
- Change: fork-only documentation
- Resolution: ours only, never conflicts with upstream

## Adding New Patches

When a new fork patch lands on `rr/customise`:
- Add an entry here with commit hash, file(s), change summary, and resolution strategy
- Keep entries ordered by file path for fast lookup during rebase
- Prefer **additive new files** (new test files, new source files) over modifying upstream files — new files never conflict

## Additive Files (zero conflict risk)

These are fork-only files that don't exist upstream. They never conflict during rebase:

- `Sources/AppBundleTests/command/DfsOrderListWindowsTest.swift` — unit tests for `--dfs-order` flag
- `sync-with-upstream.org` — fork sync documentation
- `windowlist.patch` — reference patch file
- `FLOATING_WINDOW_FOCUS_BUG.md` — bug analysis and implementation plan
- `.agents/` — agent skills and instructions
- `AGENTS.md` — agent discovery
