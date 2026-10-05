# 本地笔记 · iOS 工程（Phase 0 骨架）

SwiftUI + SwiftData，iOS 17+，本地优先。

## 文件

| 文件 | 内容 |
|---|---|
| `NoteAppApp.swift` | App 入口，SwiftData 本地容器；启动时请求通知权限并安排每日回顾 |
| `Models.swift` | `Note`（灵感/摘句）、`Book`（ISBN书架）数据模型 |
| `ContentView.swift` | 笔记列表、类型筛选、本地全文搜索、md/txt导出、每日回顾开关 |
| `NoteEditorView.swift` | 新建/编辑：原文与批注分离、摘句归属书籍 |
| `Exporter.swift` | 导出为 Markdown / TXT 的文件包装 |
| `NoteApp/Shared/SharedStore.swift` | App Group 共享 SwiftData 容器（App 与小组件共用） |
| `NoteAppWidget/` | WidgetKit 速记小组件：今日条数 + 一键新建（noteapp:// URL Scheme）+ 中尺寸今日回顾 |
| `NoteApp/NoteApp.entitlements` / `NoteAppWidget/NoteAppWidget.entitlements` | App Group `group.com.localnote.NoteApp` |
| `NoteApp/Intents/CaptureIntent.swift` | App Intent"记一条灵感"：快捷指令/锁屏按钮可调用，后台写入 SwiftData |
| `NoteApp/Speech/VoiceTranscriber.swift` | 端侧语音转写：Speech zh-CN + requiresOnDeviceRecognition，录音不上传 |
| `NoteApp/Recap/RecapScheduler.swift` | 每日回顾：每天 8:00 本地通知推一条历史笔记（优先 7 天前同一天，否则随机）；开关存 UserDefaults；今日回顾 note id + 日期写入 App Group 供小组件读取 |
| `NoteApp/NoteEditorView.swift` | 新增麦克风按钮：点按开始/停止转写，红色脉冲"正在听…"状态，转写文字实时追加 |

## 在 Mac 上跑起来（约 5 分钟）

1. 打开 Xcode → Create New Project → iOS → App，项目名填 `NoteApp`
   - Interface 选 **SwiftUI**，Language 选 **Swift**
   - Minimum Deployments 选 **iOS 17.0**
2. 把本目录 `NoteApp/` 下的 5 个 `.swift` 文件拖进 Xcode 项目（勾选 Copy items if needed）
3. 删除 Xcode 自动生成的 `ContentView.swift`（用这里的版本替换）
4. Cmd+R 运行，模拟器里即可新建、搜索、导出笔记

## 下一步（Phase 1→2）

- 小组件速记：新建 Widget Extension target，用 App Group 共享 SwiftData
- 语音转写：Speech 框架，`SFSpeechRecognizer` 端侧识别
- 拍照 OCR：Vision `VNRecognizeTextRequest`，中文 `recognitionLanguages = ["zh-Hans"]`
- ISBN 查书：Open Library `https://openlibrary.org/isbn/{isbn}.json`
