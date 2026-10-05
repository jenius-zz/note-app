import AVFoundation
import Combine
import Speech

/// 端侧语音转写：AVAudioEngine + SFSpeechRecognizer（zh-CN）。
/// requiresOnDeviceRecognition = true —— 识别全程在设备上完成，
/// 录音不上传云端，符合"数据在自己手里"的产品定位。
///
/// 注意：本类不标 @MainActor（SwiftUI body 是非隔离上下文，
/// 直接访问 @MainActor 属性在 Swift 5 下会编译失败）；
/// 识别回调在后台线程触发，更新 @Published 前统一切回主线程。
final class VoiceTranscriber: ObservableObject {
    /// 本轮识别出的完整文字（随说话实时更新）
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    /// 可直接展示给用户的中文错误提示
    @Published var errorMessage: String?

    private let recognizer: SFSpeechRecognizer? =
        SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    /// 检查权限与端侧能力。返回 nil 表示可用，否则返回中文错误提示。
    /// 调用方在主线程发起即可。
    func ensurePermissions() async -> String? {
        guard let recognizer else {
            return "当前系统不支持中文语音识别"
        }
        guard recognizer.supportsOnDeviceRecognition else {
            return "此设备不支持本地中文语音识别，请先到"设置 > 通用 > 听写语言"下载中文离线听写"
        }
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else {
            return "没有语音识别权限，请到"设置 > 本地笔记"中打开"语音识别""
        }
        let micGranted = await AVAudioApplication.requestRecordPermission()
        guard micGranted else {
            return "没有麦克风权限，请到"设置 > 本地笔记"中打开"麦克风""
        }
        return nil
    }

    /// 开始录音并实时转写。调用前先走 ensurePermissions()。
    /// 必须在主线程调用。
    func start() {
        guard !isRecording else { return }
        guard let recognizer else {
            errorMessage = "当前系统不支持中文语音识别"
            return
        }
        cleanup()
        transcript = ""

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        recognitionRequest = request

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }
            audioEngine.prepare()
            try audioEngine.start()

            // 回调在后台线程，更新 UI 状态前切回主线程
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }
                DispatchQueue.main.async {
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                    }
                    if error != nil || result?.isFinal == true {
                        self.stop()
                    }
                }
            }
            isRecording = true
        } catch {
            errorMessage = "启动录音失败：\(error.localizedDescription)"
            cleanup()
        }
    }

    /// 停止录音与识别。必须在主线程调用。
    func stop() {
        guard isRecording || recognitionTask != nil else { return }
        cleanup()
    }

    private func cleanup() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        try? AVAudioSession.sharedInstance()
            .setActive(false, options: .notifyOthersOnDeactivation)
    }
}
