@testable import AppBundle
import Common
import XCTest

@MainActor
final class DfsOrderListWindowsTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testListedOrderMatchesFocusCycleWithFloatingWindows() async {
        let workspace = Workspace.get(byName: "a")
        let first = TestWindow.new(id: 2, parent: workspace.rootTilingContainer)
        TestWindow.new(id: 1, parent: workspace.rootTilingContainer)
        TestWindow.new(id: 3, parent: workspace.floatingWindowsContainer)
        assertTrue(first.focusWindow())

        let listed = await parseCommand("list-windows --workspace a --dfs-order --format '%{window-id}'")
            .cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertEquals(listed.exitCode.rawValue, 0)
        assertEquals(listed.stdout, ["2", "1", "3"])

        for expected in [1, 3, 2] {
            let result = await parseCommand("focus dfs-next --boundaries-action wrap-around-the-workspace")
                .cmdOrDie.run(.defaultEnv, .emptyStdin)
            assertEquals(result.exitCode.rawValue, 0)
            XCTAssertEqual(focus.windowOrNil?.windowId, UInt32(expected))
        }
    }
}
