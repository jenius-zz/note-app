import XCTest

/// UI 截图测试：只做启动截图，不做任何点击交互（模拟器里点按不稳定）。
/// 两张截图存到 /tmp/shots，CI 用 upload-artifact 传上来，
/// 用户不用花钱就能看到真实界面。
final class NoteAppUITests: XCTestCase {

    private let shotsDir = "/tmp/shots"

    override func setUpWithError() throws {
        continueAfterFailure = false
        try? FileManager.default.createDirectory(
            atPath: shotsDir,
            withIntermediateDirectories: true
        )
    }

    func testCaptureScreenshots() throws {
        // 第一张：空态列表（不带播种参数启动）
        let emptyApp = XCUIApplication()
        emptyApp.launchArguments = ["UITestSkipPermissions"]
        emptyApp.launch()
        XCTAssertTrue(
            emptyApp.wait(for: .runningForeground, timeout: 30),
            "App 未进入前台"
        )
        // 诊断截图：看清进入前台瞬间到底显示了什么
        shot(emptyApp, name: "shot0-foreground-state")
        waitFor(emptyApp.buttons["newNoteButton"], timeout: 30, message: "主界面未出现")
        shot(emptyApp, name: "shot_empty")
        emptyApp.terminate()

        // 第二张：有数据的列表（播种两条演示数据后启动）
        let seededApp = XCUIApplication()
        seededApp.launchArguments = ["UITestSkipPermissions", "-seedDemoNote"]
        seededApp.launch()
        XCTAssertTrue(
            seededApp.wait(for: .runningForeground, timeout: 30),
            "App 未进入前台"
        )
        waitFor(
            seededApp.staticTexts["在咖啡馆看到一只猫在晒太阳"],
            timeout: 30,
            message: "演示数据未出现在列表"
        )
        shot(seededApp, name: "shot_list")
    }

    private func waitFor(
        _ element: XCUIElement,
        timeout: TimeInterval,
        message: String
    ) {
        let exp = expectation(
            for: NSPredicate(format: "exists == true"),
            evaluatedWith: element,
            handler: nil
        )
        let result = XCTWaiter.wait(for: [exp], timeout: timeout)
        XCTAssertEqual(result, .completed, message)
    }

    private func shot(_ app: XCUIApplication, name: String) {
        let png = app.screenshot().pngRepresentation
        try? png.write(to: URL(fileURLWithPath: "\(shotsDir)/\(name).png"))
    }
}
