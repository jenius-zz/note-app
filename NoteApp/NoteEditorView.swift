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
    @StateObject private var transcriber = VoiceTranscriber()
    /// 开始录音时正文的快照，转写文字追加在其后
    @State private var recordingBase: String = ""
    @State private var showSpeechError: Bool = false
    @State private var pulse: Bool = false

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

            Section {
                TextEditor(text: $text)
                    .frame(minHeight: 160)
                    .accessibilityIdentifier("noteTextEditor")
            } header: {
                HStack {
                    Text(kind == .quote ? "原文" : "内容")
                    Spacer()
                    micButton
                }
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
                    .accessibilityIdentifier("saveNoteButton")
            }
        }
        .onChange(of: transcriber.transcript) { _, newValue in
            guard transcriber.isRecording else { return }
            text = recordingBase + newValue
        }
        .onChange(of: transcriber.isRecording) { _, recording in
            if recording {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            } else {
                pulse = false
            }
        }
        .alert("语音转写", isPresented: $showSpeechError) {
            Button("好", role: .cancel) {}
        } message: {
            Text(transcriber.errorMessage ?? "")
        }
        .onDisappear {
            transcriber.stop()
        }
    }

    /// 麦克风按钮：点按开始/停止端侧语音转写，识别文字实时追加到正文。
    private var micButton: some View {
        Button {
            Task { await toggleRecording() }
        } label: {
            HStack(spacing: 4) {
                if transcriber.isRecording {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .opacity(pulse ? 0.25 : 1.0)
                    Text("正在听…")
                } else {
                    Image(systemName: "mic")
                }
            }
            .font(.caption)
            .foregroundStyle(transcriber.isRecording ? .red : .blue)
        }
    }

    private func toggleRecording() async {
        if transcriber.isRecording {
            transcriber.stop()
            return
        }
        recordingBase = text.isEmpty ? "" : text + "\n"
        if let message = await transcriber.ensurePermissions() {
            transcriber.errorMessage = message
            showSpeechError = true
            return
        }
        transcriber.start()
        if transcriber.errorMessage != nil {
            showSpeechError = true
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
