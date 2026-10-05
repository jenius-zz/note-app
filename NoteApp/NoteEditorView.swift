import SwiftUI
import SwiftData

/// 新建 / 编辑一条笔记。
/// 摘句场景下「原文 / 批注」分离存储；灵感场景只用正文。
struct NoteEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Book.title) private var books: [Book]

    let existingNote: Note?
    @State private var kind: NoteKind
    @State private var text: String
    @State private var annotation: String
    @State private var selectedBook: Book?

    init(note: Note?, initialKind: NoteKind = .inspiration) {
        self.existingNote = note
        _kind = State(initialValue: note?.kind ?? initialKind)
        _text = State(initialValue: note?.text ?? "")
        _annotation = State(initialValue: note?.annotation ?? "")
        _selectedBook = State(initialValue: note?.book)
    }

    var body: some View {
        Form {
            Picker("类型", selection: $kind) {
                ForEach(NoteKind.allCases) { k in
                    Text(k.title).tag(k)
                }
            }
            .pickerStyle(.segmented)

            Section(kind == .quote ? "原文" : "内容") {
                TextEditor(text: $text)
                    .frame(minHeight: 160)
            }

            if kind == .quote {
                Section("批注") {
                    TextEditor(text: $annotation)
                        .frame(minHeight: 80)
                }

                Section("归属书籍") {
                    Picker("书籍", selection: $selectedBook) {
                        Text("不归属").tag(nil as Book?)
                        ForEach(books) { book in
                            Text(book.title).tag(book as Book?)
                        }
                    }
                }
            }
        }
        .navigationTitle(existingNote == nil ? "记一笔" : "编辑")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存", action: save)
            }
        }
    }

    private func save() {
        if let note = existingNote {
            note.kind = kind
            note.text = text
            note.annotation = annotation
            note.book = (kind == .quote) ? selectedBook : nil
            note.updatedAt = Date()
        } else {
            let note = Note(
                kind: kind,
                text: text,
                annotation: annotation,
                book: (kind == .quote) ? selectedBook : nil
            )
            modelContext.insert(note)
        }
        dismiss()
    }
}
