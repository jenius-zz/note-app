import SwiftUI

/// 「温暖手账风」主题：奶油底 + 马卡龙卡片 + 胶囊标签 + 暖橙主按钮。
/// 只做浅色；深色模式暂不处理。
enum AppTheme {
    static let cornerRadius: CGFloat = 20
    static let cardPadding: CGFloat = 16
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    /// 奶油暖白底
    static let creamBackground = Color(hex: 0xFFF9F0)
    /// 灵感卡片：蜜桃粉
    static let cardPeach = Color(hex: 0xFFE3C2)
    /// 摘句卡片：雾蓝
    static let cardBlue = Color(hex: 0xD6E9F8)
    /// 默认卡片：薄荷绿
    static let cardMint = Color(hex: 0xDFF2D8)
    /// 灵感标签 / 主按钮：暖橙
    static let tagOrange = Color(hex: 0xF97316)
    /// 摘句标签：雾蓝（加深以保证白字可读）
    static let tagBlue = Color(hex: 0x6AA5DC)
    static let accentOrange = Color(hex: 0xF97316)
    /// 正文：深棕灰
    static let inkBrown = Color(hex: 0x4A3728)
    /// 次要文字：暖灰
    static let inkSoft = Color(hex: 0x9A8A76)

    /// 按笔记类型取卡片底色
    static func cardColor(for kind: NoteKind) -> Color {
        switch kind {
        case .inspiration: return .cardPeach
        case .quote: return .cardBlue
        }
    }

    /// 按笔记类型取标签底色
    static func tagColor(for kind: NoteKind) -> Color {
        switch kind {
        case .inspiration: return .tagOrange
        case .quote: return .tagBlue
        }
    }
}

extension Font {
    /// 圆体感字体（中文回退到系统默认字体）
    static var journalTitle: Font { .system(.largeTitle, design: .rounded).weight(.bold) }
    static var journalHeadline: Font { .system(.headline, design: .rounded).weight(.semibold) }
    static var journalBody: Font { .system(.body, design: .rounded) }
    static var journalCaption: Font { .system(.caption, design: .rounded) }
}
