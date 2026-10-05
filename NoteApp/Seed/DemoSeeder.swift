import SwiftData
import Foundation

/// UI 截图测试用的演示数据播种器。
/// 仅当 launch argument 包含 "-seedDemoNote" 且数据库为空时插入，
/// 不污染用户真实数据。
enum DemoSeeder {
    static func seedIfNeeded() {
        let context = ModelContext(SharedStore.sharedModelContainer)
        let count = (try? context.fetchCount(FetchDescriptor<Note>())) ?? 0
        guard count == 0 else { return }

        let inspiration = Note(
            kind: .inspiration,
            text: "在咖啡馆看到一只猫在晒太阳"
        )

        let book = Book(title: "活着", author: "余华")
        let quote = Note(
            kind: .quote,
            text: "人是为了活着本身而活着，而不是为了活着之外的任何事物而活着。",
            annotation: "活着本身就是意义。",
            book: book
        )

        context.insert(inspiration)
        context.insert(book)
        context.insert(quote)
        try? context.save()
    }
}
