import SwiftUI
import SwiftData

/// App 入口。SwiftData 本地容器 = 数据 100% 在设备。
@main
struct NoteAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Note.self, Book.self])
    }
}
