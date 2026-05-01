# Floating Window Focus Order — Design & Behavior

## Problem (original)

When on workspace 7 with windows `[vim (tiled)] [BrainTool (tiled)] [scratchpad (floating)]`,
running `focus dfs-prev` from the focused floating scratchpad window lands on `vim` instead of
`BrainTool`. Sketchybar shows a different order than the actual focus cycle.

Two sub-problems emerged during implementation:

1. **Position instability** — `makeFloatingWindowsSeenAsTiling()` queries live AX coordinates
   and inserts floating windows into the tiling tree by screen center. When a floating window
   straddles two tiled windows, the `>=` comparison flips unpredictably, causing the floating
   window to jump left/right in the list on each poll.

2. **Navigation/display mismatch** — `focus dfs-next/prev` and `list-windows` must agree on
   order, otherwise sketchybar shows one thing and keyboard navigation does another.

## Solution: append-at-end ordering

Both `list-windows --dfs-order` and `focus dfs-next/prev` now append floating windows
after all tiled windows in stable workspace-child order (creation/float order). No AX
coordinate queries. Directional focus (`left`/`right`/`up`/`down`) is unchanged — it still
uses position-based insertion since spatial adjacency matters there.

## Behavior diagrams

### Workspace tree structure

```
workspace 7
├── rootTilingContainer (h_tiles)
│   ├── vim        [index 0]
│   ├── terminal   [index 1]
│   └── browser    [index 2]
│
└── floating children (workspace-child order)
    ├── scratchpad [floated first]
    └── notes      [floated second]
```

Screen layout:

```
┌──────────┬──────────┬──────────┐
│          │          │          │
│   vim    │ terminal │ browser  │
│          │  ┌────┐  │          │
│          │  │scr │  │          │
│          │  │pad │  │          │
│          │  └────┘  │          │
│          │     ┌────┤          │
│          │     │note│          │
│          │     └────┘          │
└──────────┴──────────┴──────────┘
```

### BEFORE: position-based insertion (old behavior)

`makeFloatingWindowsSeenAsTiling` queries each floating window's screen center,
finds which tiled window it overlaps, and inserts adjacent to it:

```
scratchpad center overlaps terminal → inserted after terminal
notes center overlaps terminal/browser boundary → inserted after browser? before? UNSTABLE

Call 1:  vim → terminal → scratchpad → notes → browser
Call 2:  vim → terminal → scratchpad → browser → notes
Call 3:  vim → terminal → browser → scratchpad → notes
                                    ↑ flipped!
```

`list-windows` (without `--dfs-order`) used flat traversal — floating always at end:

```
list-windows:   vim → terminal → browser → scratchpad → notes
focus dfs-next: vim → terminal → scratchpad → notes → browser  (DIFFERENT)
```

Sketchybar shows one order, navigation does another. And the navigation order
itself is non-deterministic.

### AFTER: append-at-end (current behavior)

```
tiled DFS:   vim → terminal → browser
floating:                               → scratchpad → notes
             ──────────────────────────────────────────────────
final:       vim → terminal → browser → scratchpad → notes
               0        1        2          3          4
```

Both `list-windows --dfs-order` and `focus dfs-next/prev` produce this order.
Always. Regardless of floating window screen position.

### Focus navigation walkthrough

```
                    ┌─────────────────────────────────┐
                    │         focus dfs-next           │
                    ▼                                  │
              ┌─────┐    ┌──────────┐    ┌─────────┐  │  ┌──────────┐    ┌───────┐
              │ vim ├───►│ terminal ├───►│ browser ├──┼─►│scratchpad├───►│ notes │
              └──▲──┘    └──────────┘    └─────────┘  │  └──────────┘    └───┬───┘
                 │         tiled          tiled        │    floating       floating
                 │                                     │                     │
                 └─────────────────────────────────────┴─────────────────────┘
                                   wrap around
```

```
focus dfs-next from terminal   → browser     (always)
focus dfs-next from browser    → scratchpad   (always)
focus dfs-next from scratchpad → notes        (always)
focus dfs-next from notes      → vim          (wrap)
focus dfs-prev from scratchpad → browser      (always)
focus dfs-prev from vim        → notes        (wrap)
```

### Directional focus (UNCHANGED)

`focus left/right/up/down` still uses `makeFloatingWindowsSeenAsTiling` with
position-based insertion. This is correct — directional focus should respect
spatial adjacency:

```
makeFloatingWindowsSeenAsTiling runs → temporary tree:

rootTilingContainer (h_tiles)
├── vim
├── terminal
├── [scratchpad]  ← inserted by screen position
├── [notes]       ← inserted by screen position
└── browser

focus right from terminal → scratchpad (spatially correct)
focus right from scratchpad → notes or browser (spatially correct)
```

The instability here is acceptable for directional focus since it tracks actual
window position on screen — if you move the floating window, focus should follow.

## Behavior change summary

| Aspect                          | Before (position-based)         | After (append-at-end)          |
|---------------------------------|---------------------------------|--------------------------------|
| Floating position in DFS cycle  | Varies by screen position       | Always at end                  |
| Cycle is deterministic          | No (AX queries can flip)        | Yes                            |
| Matches sketchybar display      | No                              | Yes                            |
| Directional focus (left/right)  | Position-based                  | Position-based (unchanged)     |
| Multiple floating windows       | Each inserted independently     | All appended in creation order |

**Tradeoff**: if you relied on `dfs-next` cycling through windows in spatial
screen order with floating windows interleaved among tiled ones, that no longer
happens. But the old behavior was already non-deterministic — nobody could rely
on it being stable.

## Files changed

| File | Change |
|------|--------|
| `ListWindowsCmdArgs.swift` | `--dfs-order` flag definition + conflict rules |
| `ListWindowsCommand.swift` | Conditional branch: append floating at end |
| `FocusCommand.swift` | `needsPositionalFloating` guard skips position-based insertion for `dfsRelative`; `dfsRelative` case appends floating manually; visibility `private` → `internal` on helper functions |

## Rebase strategy

See `sync-with-upstream.org` (Fork Patch Diagram) and
`.agents/skills/aerospace-upstream-rebase/references/known-patches.md` for
conflict resolution guidance.
