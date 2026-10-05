import SwiftData
import Foundation

/// App 与 Widget Extension 共享的 SwiftData 容器。
/// 数据经由 App Group 落在共享目录，两端都只走本地，不上传云端。
enum SharedStore {
    static let appGroupID = "group.com.localnote.NoteApp"

    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([Note.self, Book.self])
        let configuration: ModelConfiguration
        if ProcessInfo.processInfo.arguments.contains("UITestSkipPermissions") {
            // UI 截图测试：用 App 私有容器，不依赖 App Group 系统服务。
            // 小组件的数据共享在截图测试中不需要，且 App Group 容器在 CI
            // 模拟器上曾导致启动阶段主线程阻塞，UI 迟迟不渲染。
            configuration = ModelConfiguration(schema: schema)
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                groupContainer: .identifier(appGroupID)
            )
        }
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("无法创建共享数据容器: \(error)")
        }
    }()
}
