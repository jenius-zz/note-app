import WidgetKit
import SwiftUI
import SwiftData

/// 锁屏 / 桌面速记小组件：
/// - 显示今日已记条数（从共享 SwiftData 只读）
/// - 「记一笔」按钮经 URL Scheme 打开 App 直达新建灵感页
/// - 中尺寸显示「今日回顾」（App 每天选好后写入 App Group）
struct QuickNoteEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
    let recapPreview: String?
}

struct QuickNoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickNoteEntry {
        QuickNoteEntry(date: Date(), todayCount: 3, recapPreview: "示例回顾第一行\n示例回顾第二行")
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickNoteEntry) -> Void) {
        completion(QuickNoteEntry(
            date: Date(),
            todayCount: todayNoteCount(),
            recapPreview: RecapScheduler.todayRecapPreview()
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickNoteEntry>) -> Void) {
        let entry = QuickNoteEntry(
            date: Date(),
            todayCount: todayNoteCount(),
            recapPreview: RecapScheduler.todayRecapPreview()
        )
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
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("本地笔记")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.inkSoft)
                Spacer()
                Text("✦")
                    .font(.caption2)
                    .foregroundStyle(Color.tagOrange.opacity(0.6))
            }
            Text("今日已记 \(entry.todayCount) 条")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.inkBrown)
                .minimumScaleFactor(0.8)
            if family == .systemMedium {
                VStack(alignment: .leading, spacing: 2) {
                    Text("今日回顾")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Color.inkSoft)
                    if let recap = entry.recapPreview {
                        Text(recap)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(Color.inkBrown)
                            .lineLimit(2)
                    } else {
                        Text("今天还没有回顾，去记一笔吧")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(Color.inkSoft)
                    }
                }
            }
            Spacer()
            Link(destination: URL(string: "noteapp://new?kind=inspiration")!) {
                Label("记一笔", systemImage: "square.and.pencil")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentOrange)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .containerBackground(Color.creamBackground, for: .widget)
    }
}

struct QuickNoteWidget: Widget {
    let kind: String = "QuickNoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickNoteProvider()) { entry in
            QuickNoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("速记")
        .description("一键新建灵感，查看今日已记条数与今日回顾。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
