import SwiftUI
import SwiftData

/// App 入口。经 App Group 与小组件共享 SwiftData 容器，
/// 数据 100% 在设备，不上传云端。
@main
struct NoteAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // UI 截图测试用 launch argument 跳过系统通知弹窗，保证流程可重复
                    guard !ProcessInfo.processInfo.arguments.contains("UITestSkipPermissions") else { return }
                    // 先请求通知权限，再按开关安排每日回顾
                    _ = await RecapScheduler.requestAuthorization()
                    RecapScheduler.scheduleDailyRecap()
                }
        }
        .modelContainer(SharedStore.sharedModelContainer)
    }
}
