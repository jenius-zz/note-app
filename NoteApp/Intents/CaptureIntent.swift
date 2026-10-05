import AppIntents
import SwiftData

/// 快捷指令 / 锁屏按钮可调用的"记一条灵感"。
/// 系统会自动发现 AppIntent，无需手动注册。
struct QuickCaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "记一条灵感"
    static var description = IntentDescription("快速记一条灵感，不打开 App")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "内容", description: "要记下的灵感内容")
    var text: String

    static var parameterSummary: some ParameterSummary {
        Summary("记下 \(\.$text)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CaptureError.empty
        }
        let context = SharedStore.sharedModelContainer.mainContext
        context.insert(Note(kind: .inspiration, text: trimmed))
        try context.save()
        return .result(value: trimmed, dialog: "已记下")
    }
}

enum CaptureError: Error, CustomLocalizedStringResourceConvertible {
    case empty

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .empty:
            return "内容为空，没有记下来"
        }
    }
}
