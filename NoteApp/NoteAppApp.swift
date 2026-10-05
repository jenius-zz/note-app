import SwiftUI
import SwiftData

/// App 入口。经 App Group 与小组件共享 SwiftData 容器，
/// 数据 100% 在设备，不上传云端。
@main
struct NoteAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(SharedStore.sharedModelContainer)
    }
}
