import SwiftData
import Foundation

/// App 与 Widget Extension 共享的 SwiftData 容器。
/// 数据经由 App Group 落在共享目录，两端都只走本地，不上传云端。
enum SharedStore {
    static let appGroupID = "group.com.localnote.NoteApp"

    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([Note.self, Book.self])
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(appGroupID)
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("无法创建共享数据容器: \(error)")
        }
    }()
}
