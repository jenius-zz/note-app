import SwiftUI
import UniformTypeIdentifiers

/// 纯文本文件包装，用于 fileExporter 导出 md / txt。
struct TextFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: text.data(using: .utf8) ?? Data())
    }
}

/// 把笔记导出为 Markdown / 纯文本。
enum MarkdownExporter {
    static func export(notes: [Note]) -> String {
        var lines: [String] = ["# 本地笔记导出", ""]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        for note in notes {
            lines.append("## \(note.kind.title) · \(formatter.string(from: note.createdAt))")
            if let book = note.book {
                let author = book.author.isEmpty ? "" : " · \(book.author)"
                lines.append("> 出自《\(book.title)》\(author)")
            }
            lines.append("")
            lines.append(note.text)
            if !note.annotation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lines.append("")
                lines.append("**批注**：\(note.annotation)")
            }
            lines.append("")
            lines.append("---")
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}
