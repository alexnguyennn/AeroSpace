# Floating Window Focus Order Bug

## Problem

When on workspace 7 with windows `[vim (tiled)] [BrainTool (tiled)] [scratchpad (floating)]`,
running `focus dfs-prev` from the focused floating scratchpad window lands on `vim` instead of
`BrainTool` (the visually adjacent window). Sketchybar shows the order as
`[vim] [BrainTool] [scratchpad]` but AeroSpace's focus cycle has a different internal order.

## Root Cause

`list-windows` and `focus dfs-prev/next` use **different orderings** for floating windows:

| Command | Traversal | Floating window position |
|---------|-----------|------------------------|
| `list-windows` | `workspace.allLeafWindowsRecursive` | After all tiled windows |
| `focus dfs-prev/next` | `rootTilingContainer.allLeafWindowsRecursive` after `makeFloatingWindowsSeenAsTiling()` | Position-based: inserted into tiling tree by screen center point |

The position-based insertion (`FocusCommand.swift:118-159`) projects each floating window's
center onto the tiling tree and inserts it adjacent to whichever tiled window it overlaps.
If the scratchpad's center overlaps vim's region, focus cycling puts it next to vim, not BrainTool.

## Solution: `--dfs-order` flag on `list-windows`

Add a `--dfs-order` flag that makes `list-windows` return windows in the same order as
`focus dfs-prev/next`. Sketchybar uses this flag; normal `list-windows` calls are unaffected.

### Changes Required

**4 files, ~30 lines added:**

#### 1. `Sources/Common/cmdArgs/impl/ListWindowsCmdArgs.swift`

Add the flag to the parser and struct:

```swift
// In flags dict (~line 25):
"--dfs-order": trueBoolFlag(\.dfsOrder),

// In struct (~line 41):
public var dfsOrder: Bool = false
```

Add conflict: `--dfs-order` requires `--workspace` (makes no sense with `--all` or `--focused`).

#### 2. `Sources/AppBundle/command/impl/FocusCommand.swift`

Change visibility of `makeFloatingWindowsSeenAsTiling` and `restoreFloatingWindows` from
`private` to `package` (or `internal`). **No logic changes.** Both are in FocusCommand.swift
lines 118-170.

```diff
-@MainActor private func makeFloatingWindowsSeenAsTiling(...
+@MainActor func makeFloatingWindowsSeenAsTiling(...

-@MainActor private func restoreFloatingWindows(...
+@MainActor func restoreFloatingWindows(...

-private struct FloatingWindowData {
+struct FloatingWindowData {
```

#### 3. `Sources/AppBundle/command/impl/ListWindowsCommand.swift`

When `args.dfsOrder` is true, use the floating-as-tiling logic instead of plain traversal.
Must also snapshot which windows are floating **before** insertion so `%{window-layout}`
still reports `floating` correctly (since `isFloating` checks `parent is Workspace` which
becomes false after temporary insertion).

```swift
// Replace line 35:
// windows = workspaces.flatMap(\.allLeafWindowsRecursive)
// With:
if args.dfsOrder {
    for workspace in workspaces {
        let floatingIds = Set(workspace.floatingWindows.map(\.windowId))
        let floatingData = try await makeFloatingWindowsSeenAsTiling(workspace: workspace)
        windows.append(contentsOf: workspace.rootTilingContainer.allLeafWindowsRecursive)
        restoreFloatingWindows(floatingWindows: floatingData, workspace: workspace)
    }
} else {
    windows = workspaces.flatMap(\.allLeafWindowsRecursive)
}
```

The `floatingIds` set is passed through to format output to preserve `window-layout = floating`.

#### 4. `Sources/AppBundle/command/format.swift`

The `toLayoutResult` function (`format.swift:173`) checks the window's current parent to
determine layout. After `restoreFloatingWindows` runs, the parent is restored to Workspace,
so format output happens **after** restore. This means we need a different approach:

**Option A (simpler)**: Collect window list while temporarily bound, but format **after**
restore. The order is preserved since we captured `windows` array in dfs order. Format vars
read current parent which is restored to Workspace. `window-layout` reports `floating`. No
format.swift changes needed.

**Option B**: If we need to format during temporary binding (unlikely), pass a
`overrideFloatingIds: Set<UInt32>` to the format function.

**Option A works — no changes to format.swift needed.** The sequence is:
1. Temporarily bind floating windows into tiling tree
2. Capture `rootTilingContainer.allLeafWindowsRecursive` → ordered `[Window]`
3. Restore floating windows to workspace
4. Format the captured array (parents are restored, `window-layout` correct)

### Sketchybar Change

Update `~/.config/sketchybar/lua/items/windows.lua:1700-1702`:

```lua
-- Before:
'aerospace list-windows --workspace %s --json --format "%%{window-id} ..."'
-- After:
'aerospace list-windows --workspace %s --dfs-order --json --format "%%{window-id} ..."'
```

### Files Modified Summary

| File | Lines changed | Nature |
|------|--------------|--------|
| `ListWindowsCmdArgs.swift` | +3 | New flag + conflict rule |
| `FocusCommand.swift` | 3 lines: `private` → `internal` | Visibility only |
| `ListWindowsCommand.swift` | +10 | Conditional dfs-order branch |
| `windows.lua` | 1 | Add `--dfs-order` to query |

**Total: ~16 lines of new code across 3 Swift files + 1 Lua file.**

### Merge Conflict Risk

- `ListWindowsCmdArgs.swift`: Low risk — adding a flag to a dict is additive
- `FocusCommand.swift`: Minimal — only changing `private` to `internal`, any upstream refactor of these functions would conflict but the resolution is trivial
- `ListWindowsCommand.swift`: Medium — this file already has our sort-removal patch (`4ef4f9cb`). Upstream changes to window listing logic would conflict here. Keep the patch small.
- Existing fork patches (`windowlist.patch` sort removal) are orthogonal — the sort removal and dfs-order are independent concerns

### Post-Implementation: Update Rebase Skill

After implementing, add entries to `.agents/skills/aerospace-upstream-rebase/references/known-patches.md`:

- **`--dfs-order` flag** — `ListWindowsCmdArgs.swift` (flag def), `ListWindowsCommand.swift` (conditional branch), `FocusCommand.swift` (visibility `private` → `internal` on `makeFloatingWindowsSeenAsTiling`, `restoreFloatingWindows`, `FloatingWindowData`)
- Resolution strategy: re-apply flag and conditional; if upstream refactors focus command functions, find renamed equivalents and adjust visibility

### TDD: Unit Tests (implement first)

New file: `Sources/AppBundleTests/command/DfsOrderListWindowsTest.swift`

This is a **fork-only additive file** — no merge conflicts with upstream since it doesn't
modify any existing test files. Run with `./run-swift-test.sh`.

Tests to write using existing test infrastructure (`TestWindow`, `setUpWorkspacesForTests`,
etc.). Pattern follows `FocusCommandTest.testFocusOverFloatingWindows` and
`FocusCommandTest.testFocusDfsRelative`:

**Test: `testListWindowsDfsOrderMatchesFocusCycle`**
- Create workspace with 2 tiled windows in rootTilingContainer (id: 1, 2)
- Add 1 floating window on workspace with rect overlapping window 1's region (id: 3)
- Run `list-windows --workspace <name> --dfs-order` and capture window ID order
- Run `focus dfs-next` repeatedly from window 1, recording focus order
- Assert both orders are identical

**Test: `testListWindowsDfsOrderFloatingReportsCorrectLayout`**
- Create workspace with 1 tiled window and 1 floating window
- Run `list-windows --workspace <name> --dfs-order --format "%{window-id} %{window-layout}"`
- Assert floating window's layout is reported as `floating` (not `h_tiles`/`v_tiles`)

**Test: `testListWindowsWithoutDfsOrderUnchanged`**
- Create workspace with tiled + floating windows
- Run `list-windows --workspace <name>` (no `--dfs-order`)
- Assert floating windows appear after all tiled windows (existing behavior preserved)

**Test: `testDfsOrderFlagParsing`**
- `list-windows --workspace M --dfs-order` → parses successfully
- `list-windows --focused --dfs-order` → error (incompatible)
- `list-windows --all --dfs-order` → error (incompatible)

### Integration Test Plan

After unit tests pass, build and verify end-to-end:

- Build AeroSpace from `rr/customise` branch
- Open workspace with tiled + floating windows
- `aerospace list-windows --workspace 7 --json` → floating windows at end (old behavior)
- `aerospace list-windows --workspace 7 --dfs-order --json` → floating windows at position-based DFS location
- Verify order matches `focus dfs-next` cycling order
- Verify `window-layout` still reports `floating` for floating windows in both modes
- Update sketchybar query, verify bar order matches focus cycling
