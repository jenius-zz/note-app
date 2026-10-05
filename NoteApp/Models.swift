import SwiftData
import Foundation

/// 笔记类型：灵感 / 读书摘句
enum NoteKind: String, Codable, CaseIterable, Identifiable {
    case inspiration
    case quote

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inspiration: return "灵感"
        case .quote: return "摘句"
        }
    }
}

/// 一条笔记。本地优先：全部字段只存设备，不上传云端。
@Model
final class Note {
    var id: UUID
    var kindRaw: String
    var text: String          // 灵感正文 / 摘句原文
    var annotation: String    // 批注（摘句场景使用，灵感可留空）
    var createdAt: Date
    var updatedAt: Date
    var latitude: Double?
    var longitude: Double?
    var placeName: String?
    @Relationship(deleteRule: .nullify) var book: Book?

    init(
        kind: NoteKind = .inspiration,
        text: String = "",
        annotation: String = "",
        book: Book? = nil
    ) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.text = text
        self.annotation = annotation
        self.createdAt = Date()
        self.updatedAt = Date()
        self.book = book
    }

    var kind: NoteKind {
        get { NoteKind(rawValue: kindRaw) ?? .inspiration }
        set { kindRaw = newValue.rawValue }
    }

    /// 列表页显示的摘要行
    var preview: String {
        let firstLine = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .first ?? ""
        return firstLine.isEmpty ? "（空）" : firstLine
    }
}

/// 书架上的一本书（ISBN 建书目）
@Model
final class Book {
    var id: UUID
    var title: String
    var author: String
    var isbn: String
    var coverURL: String?
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Note.book) var notes: [Note]?

    init(title: String, author: String = "", isbn: String = "", coverURL: String? = nil) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.isbn = isbn
        self.coverURL = coverURL
        self.createdAt = Date()
    }
}
