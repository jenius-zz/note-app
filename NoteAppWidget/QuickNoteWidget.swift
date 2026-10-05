import WidgetKit
import SwiftUI
import SwiftData

/// 锁屏 / 桌面速记小组件：
/// - 显示今日已记条数（从共享 SwiftData 只读）
/// - 「记一笔」按钮经 URL Scheme 打开 App 直达新建灵感页
struct QuickNoteEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
}

struct QuickNoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickNoteEntry {
        QuickNoteEntry(date: Date(), todayCount: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickNoteEntry) -> Void) {
        completion(QuickNoteEntry(date: Date(), todayCount: todayNoteCount()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickNoteEntry>) -> Void) {
        let entry = QuickNoteEntry(date: Date(), todayCount: todayNoteCount())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    /// 只读：统计今天创建的笔记条数
    private func todayNoteCount() -> Int {
        let context = ModelContext(SharedStore.sharedModelContainer)
        let descriptor = FetchDescriptor<Note>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let notes = (try? context.fetch(descriptor)) ?? []
        return notes.filter { Calendar.current.isDateInToday($0.createdAt) }.count
    }
}

struct QuickNoteWidgetEntryView: View {
    var entry: QuickNoteProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("本地笔记")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("今日已记 \(entry.todayCount) 条")
                .font(.headline)
                .minimumScaleFactor(0.8)
            Spacer()
            Link(destination: URL(string: "noteapp://new?kind=inspiration")!) {
                Label("记一笔", systemImage: "square.and.pencil")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }
}

struct QuickNoteWidget: Widget {
    let kind: String = "QuickNoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickNoteProvider()) { entry in
            QuickNoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("速记")
        .description("一键新建灵感，并查看今日已记条数。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
