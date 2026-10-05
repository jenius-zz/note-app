import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// 首页：笔记列表 + 本地全文搜索 + 导出（温暖手账风）
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
            ZStack(alignment: .bottomTrailing) {
                Color.creamBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        headerView
                        searchField
                        kindChips
                        if filteredNotes.isEmpty {
                            emptyView
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredNotes) { note in
                                    noteCard(for: note)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 110)
                }

                fabButton
            }
            .navigationBarTitleDisplayMode(.inline)
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
                            .foregroundStyle(Color.inkBrown)
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
                            .foregroundStyle(Color.inkBrown)
                    }
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

    // MARK: - 顶部标题 + 日期

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("灵感笔记")
                .font(.journalTitle)
                .foregroundStyle(Color.inkBrown)
            HStack {
                Text(dateRowText)
                    .font(.journalBody)
                    .foregroundStyle(Color.inkBrown)
                Spacer()
                Text("✦")
                    .foregroundStyle(Color.tagOrange.opacity(0.6))
            }
        }
    }

    private var dateRowText: String {
        let now = Date()
        let df = DateFormatter()
        df.locale = Locale(identifier: "zh_CN")
        df.dateFormat = "M月d日"
        let wf = DateFormatter()
        wf.locale = Locale(identifier: "zh_CN")
        wf.dateFormat = "EEEE"
        return "今天 · \(df.string(from: now)) \(wf.string(from: now))"
    }

    // MARK: - 搜索框

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.inkSoft)
            TextField("搜索笔记…", text: $searchText)
                .font(.journalBody)
                .foregroundStyle(Color.inkBrown)
        }
        .padding(12)
        .background(Color.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - 类型筛选 chips

    private var kindChips: some View {
        HStack(spacing: 8) {
            filterChip(title: "全部", selected: kindFilter == nil) { kindFilter = nil }
            ForEach(NoteKind.allCases) { kind in
                filterChip(title: kind.title, selected: kindFilter == kind) { kindFilter = kind }
            }
        }
    }

    private func filterChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.journalCaption.weight(.semibold))
                .foregroundStyle(selected ? .white : Color.inkBrown)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? Color.inkBrown : Color.white.opacity(0.7))
                .clipShape(Capsule())
        }
    }

    // MARK: - 笔记卡片

    private func noteCard(for note: Note) -> some View {
        NavigationLink {
            NoteEditorView(note: note)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(note.kind.title)
                        .font(.journalCaption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.tagColor(for: note.kind))
                        .clipShape(Capsule())
                    if let book = note.book {
                        Text("《\(book.title)》")
                            .font(.journalCaption)
                            .foregroundStyle(Color.inkSoft)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                Text(note.preview)
                    .font(.journalBody)
                    .foregroundStyle(Color.inkBrown)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                HStack {
                    Text(note.createdAt, format: .dateTime.month().day().hour().minute().locale(Locale(identifier: "zh_CN")))
                        .font(.journalCaption)
                        .foregroundStyle(Color.inkSoft)
                    Spacer()
                    Text("✦")
                        .font(.caption2)
                        .foregroundStyle(Color.inkSoft.opacity(0.4))
                }
            }
            .padding(AppTheme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardColor(for: note.kind))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        }
        .contextMenu {
            Button("删除", role: .destructive) { deleteNote(note) }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Text("✎").font(.largeTitle)
            Text(searchText.isEmpty ? "还没有笔记，去记一笔吧" : "没有匹配的笔记")
                .font(.journalBody)
                .foregroundStyle(Color.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - 悬浮新建按钮

    private var fabButton: some View {
        NavigationLink {
            NoteEditorView(note: nil)
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Color.accentOrange)
                .clipShape(Circle())
                .shadow(color: Color.accentOrange.opacity(0.35), radius: 10, y: 4)
        }
        .accessibilityIdentifier("newNoteButton")
        .padding(.trailing, 20)
        .padding(.bottom, 24)
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

    private func deleteNote(_ note: Note) {
        withAnimation {
            modelContext.delete(note)
        }
    }

    private func exportAll(asMarkdown: Bool) {
        exportDocument = TextFileDocument(text: MarkdownExporter.export(notes: notes))
        exportFilename = asMarkdown ? "本地笔记.md" : "本地笔记.txt"
        showingExporter = true
    }
}
