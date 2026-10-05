import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// 首页：笔记列表 + 本地全文搜索 + 导出
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    @State private var searchText = ""
    @State private var kindFilter: NoteKind? = nil
    @State private var showingExporter = false
    @State private var showQuickCapture = false
    @State private var quickCaptureKind: NoteKind = .inspiration

    private var filteredNotes: [Note] {
        notes.filter { note in
            let matchesKind = kindFilter == nil || note.kind == kindFilter
            guard !searchText.isEmpty else { return matchesKind }
            let haystack = (note.text + "\n" + note.annotation).localizedLowercase
            return matchesKind && haystack.contains(searchText.localizedLowercase)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredNotes) { note in
                    NavigationLink {
                        NoteEditorView(note: note)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(note.kind.title)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.15))
                                    .clipShape(Capsule())
                                if let book = note.book {
                                    Text(book.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Text(note.preview)
                                .lineLimit(2)
                            Text(note.createdAt, format: .dateTime.month().day().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .onDelete(perform: deleteNotes)
            }
            .navigationTitle("本地笔记")
            .searchable(text: $searchText, prompt: "搜索正文、批注")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("类型", selection: $kindFilter) {
                            Text("全部").tag(nil as NoteKind?)
                            ForEach(NoteKind.allCases) { kind in
                                Text(kind.title).tag(kind as NoteKind?)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section {
                            Toggle("每日回顾", isOn: dailyRecapBinding)
                        } footer: {
                            Text("每天早上 8:00 推送一条历史笔记")
                        }
                        Section("导出") {
                            Button("导出全部为 Markdown") { exportAll(asMarkdown: true) }
                            Button("导出全部为 TXT") { exportAll(asMarkdown: false) }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    NavigationLink {
                        NoteEditorView(note: nil)
                    } label: {
                        Label("记一笔", systemImage: "square.and.pencil")
                    }
                    .accessibilityIdentifier("newNoteButton")
                }
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .plainText,
            defaultFilename: exportFilename
        ) { _ in }
        // 小组件「记一笔」经 noteapp://new?kind=inspiration 跳转到新建页
        .navigationDestination(isPresented: $showQuickCapture) {
            NoteEditorView(note: nil, initialKind: quickCaptureKind)
        }
        .onOpenURL { url in
            guard url.scheme == "noteapp", url.host == "new" else { return }
            let kindParam = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "kind" })?.value
            quickCaptureKind = (kindParam == "quote") ? .quote : .inspiration
            showQuickCapture = true
        }
    }

    // MARK: - 导出

    @State private var exportDocument: TextFileDocument = TextFileDocument(text: "")
    @State private var exportFilename: String = "本地笔记.md"

    /// 每日回顾开关：值存在 UserDefaults，变化时安排 / 取消通知
    private var dailyRecapBinding: Binding<Bool> {
        Binding(
            get: { RecapScheduler.isEnabled },
            set: { enabled in
                RecapScheduler.isEnabled = enabled
                if enabled {
                    Task {
                        _ = await RecapScheduler.requestAuthorization()
                        RecapScheduler.scheduleDailyRecap()
                    }
                } else {
                    RecapScheduler.cancelDailyRecap()
                }
            }
        )
    }

    private func deleteNotes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredNotes[index])
            }
        }
    }

    private func exportAll(asMarkdown: Bool) {
        exportDocument = TextFileDocument(text: MarkdownExporter.export(notes: notes))
        exportFilename = asMarkdown ? "本地笔记.md" : "本地笔记.txt"
        showingExporter = true
    }
}
