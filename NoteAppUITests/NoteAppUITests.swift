import XCTest

/// UI 截图测试：跑一遍"新建灵感"主流程，每一步截图存到 /tmp/shots，
/// CI 用 upload-artifact 把截图传上来，用户不用花钱就能看到真实界面。
final class NoteAppUITests: XCTestCase {

    private let shotsDir = "/tmp/shots"
    private let sampleText = "在咖啡馆看到一只猫在晒太阳"

    override func setUpWithError() throws {
        continueAfterFailure = false
        try? FileManager.default.createDirectory(
            atPath: shotsDir,
            withIntermediateDirectories: true
        )
    }

    func testCaptureScreenshots() throws {
        let app = XCUIApplication()
        // 跳过通知权限系统弹窗，保证流程可重复
        app.launchArguments = ["UITestSkipPermissions"]
        app.launch()

        // 先确认 App 真的进入前台，并把启动瞬间截下来（诊断用）
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 30),
            "App 未进入前台"
        )
        shot(app, name: "shot0-launch-state")

        // 等主界面出现（记一笔按钮在底部工具栏）
        let newButton = app.buttons["newNoteButton"]
        XCTAssertTrue(
            newButton.waitForExistence(timeout: 30),
            "主界面未出现：记一笔按钮找不到"
        )
        // 截图1：列表页空态
        shot(app, name: "shot1-list-empty")

        // 点"记一笔"进编辑器
        newButton.tap()

        // 输入一段中文灵感
        let editor = app.textViews["noteTextEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 30))
        editor.tap()
        editor.typeText(sampleText)

        // 保存回到列表
        let saveButton = app.buttons["saveNoteButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 10))
        saveButton.tap()

        // 截图2：列表有一条笔记
        let rowText = app.staticTexts[sampleText]
        XCTAssertTrue(rowText.waitForExistence(timeout: 10))
        shot(app, name: "shot2-list-one-note")

        // 点进这条笔记
        rowText.tap()

        // 截图3：编辑器（已有内容）
        let editorAgain = app.textViews["noteTextEditor"]
        XCTAssertTrue(editorAgain.waitForExistence(timeout: 10))
        XCTAssertTrue(editorAgain.value as? String == sampleText)
        shot(app, name: "shot3-editor")
    }

    private func shot(_ app: XCUIApplication, name: String) {
        let png = app.screenshot().pngRepresentation
        try? png.write(to: URL(fileURLWithPath: "\(shotsDir)/\(name).png"))
    }
}
