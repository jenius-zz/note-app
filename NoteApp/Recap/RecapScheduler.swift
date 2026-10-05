import Foundation
import SwiftData
import UserNotifications

/// 每日回顾：每天早上 8:00 用本地通知推送一条历史笔记。
/// 选取规则：优先 7 天前同一天的笔记，没有则随机选一条在那一天之前创建的。
/// 选取、通知安排全部在本地完成，不联网、不上传。
enum RecapScheduler {
    // MARK: - 常量

    private static let appGroupID = "group.com.localnote.NoteApp"
    private static let enabledKey = "dailyRecapEnabled"
    private static let recapNoteIDKey = "todayRecapNoteID"
    private static let recapDateKey = "todayRecapDate"
    /// 提前安排的天数（含今天），保证每天内容新鲜
    private static let scheduledDays = 7

    // MARK: - 开关

    /// 每日回顾开关，存在 App 内 UserDefaults，默认开
    static var isEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: enabledKey) != nil else { return true }
            return UserDefaults.standard.bool(forKey: enabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    // MARK: - 权限与安排

    /// 请求通知权限（系统只会弹窗一次）
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// 安排未来 scheduledDays 天（含今天）早上 8:00 的回顾通知。
    /// 每次 App 启动调用一次即可：先清掉旧的再重新排，保证内容新鲜。
    /// 点击通知默认打开 App。
    static func scheduleDailyRecap() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (0..<scheduledDays).map(notificationID))
        guard isEnabled else { return }

        let calendar = Calendar.current
        let now = Date()
        for dayOffset in 0..<scheduledDays {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            // 今天：如果早上已选好且笔记还在，直接复用，保证和通知、小组件一致；
            // 否则重新选一条并写入 App Group（同一天只选一次）
            let note: Note?
            if dayOffset == 0, let stored = storedTodayRecapNote() {
                note = stored
            } else {
                note = pickRecapNote(before: day)
                if dayOffset == 0, let fresh = note {
                    writeTodayRecap(noteID: fresh.id)
                }
            }
            guard let note = note else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = 8
            components.minute = 0
            // 当天 8:00 已过就跳过（避免过期 trigger 立刻触发）
            guard let fireDate = calendar.date(from: components), fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "今日回顾"
            content.body = recapBody(for: note)
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: notificationID(dayOffset),
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    /// 取消所有待发送的回顾通知
    static func cancelDailyRecap() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (0..<scheduledDays).map(notificationID))
    }

    private static func notificationID(_ dayOffset: Int) -> String {
        "daily-recap-\(dayOffset)"
    }

    // MARK: - 选取逻辑

    /// 选某一天的回顾笔记：优先 7 天前同一天的笔记，
    /// 没有则随机选一条在那一天之前创建的笔记
    static func pickRecapNote(before date: Date) -> Note? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let candidates = fetchAllNotes().filter { note in
            note.createdAt < startOfDay
                && !note.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !candidates.isEmpty else { return nil }

        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: startOfDay),
           let sameDay = candidates.first(where: { calendar.isDate($0.createdAt, inSameDayAs: weekAgo) }) {
            return sameDay
        }
        return candidates.randomElement()
    }

    /// 通知正文：灵感取正文前 60 字；摘句取原文前 60 字 + 书名
    static func recapBody(for note: Note) -> String {
        let snippet = String(note.text.prefix(60))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        switch note.kind {
        case .inspiration:
            return snippet
        case .quote:
            if let book = note.book, !book.title.isEmpty {
                return "《\(book.title)》：\(snippet)"
            }
            return snippet
        }
    }

    // MARK: - App Group 共享（小组件读取今日回顾）

    private static var groupDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    private static var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    /// 把今天选好的回顾写入 App Group（note id + 日期）
    static func writeTodayRecap(noteID: UUID) {
        groupDefaults?.set(noteID.uuidString, forKey: recapNoteIDKey)
        groupDefaults?.set(todayString, forKey: recapDateKey)
    }

    /// 读出今天回顾的 note id（不是今天选的则返回 nil）
    static func todayRecapNoteID() -> UUID? {
        guard let defaults = groupDefaults,
              defaults.string(forKey: recapDateKey) == todayString,
              let idString = defaults.string(forKey: recapNoteIDKey) else { return nil }
        return UUID(uuidString: idString)
    }

    /// 小组件用：今天回顾笔记的前两行；没有则返回 nil
    static func todayRecapPreview() -> String? {
        guard let note = storedTodayRecapNote() else { return nil }
        let lines = note.text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let preview = lines.prefix(2).joined(separator: "\n")
        return preview.isEmpty ? nil : preview
    }

    /// 读出今天已选的回顾笔记（id 无效或笔记已删则返回 nil）
    private static func storedTodayRecapNote() -> Note? {
        guard let id = todayRecapNoteID() else { return nil }
        return fetchAllNotes().first(where: { $0.id == id })
    }

    private static func fetchAllNotes() -> [Note] {
        let context = ModelContext(SharedStore.sharedModelContainer)
        let descriptor = FetchDescriptor<Note>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }
}
