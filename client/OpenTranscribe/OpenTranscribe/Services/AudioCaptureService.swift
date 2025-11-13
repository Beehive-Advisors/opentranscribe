//
//  AudioCaptureService.swift
//  OpenTranscribe
//
//  Captures microphone audio using AVAudioEngine
//

import AVFoundation
import Combine

class AudioCaptureService: NSObject, ObservableObject {
    private let engine = AVAudioEngine()
    private var audioConverter: AudioConverter?
    private var onAudioData: ((Data) -> Void)?
    
    @Published var isRecording = false
    @Published var hasPermission = false
    
    override init() {
        super.init()
        checkMicrophonePermission()
    }
    
    func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            hasPermission = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                }
            }
        default:
            hasPermission = false
        }
    }
    
    func startCapture(onAudioData: @escaping (Data) -> Void) throws {
        guard hasPermission else {
            throw AudioCaptureError.permissionDenied
        }
        
        guard !isRecording else {
            return
        }
        
        self.onAudioData = onAudioData
        self.audioConverter = AudioConverter()
        
        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        // Install tap with buffer size for ~20ms of audio at input sample rate
        let bufferSize = AVAudioFrameCount(inputFormat.sampleRate * 0.02)
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            self?.processBuffer(buffer, inputFormat: inputFormat)
        }
        
        try engine.start()
        isRecording = true
    }
    
    func stopCapture() {
        guard isRecording else {
            return
        }
        
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
        onAudioData = nil
    }
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer, inputFormat: AVAudioFormat) {
        guard let converter = audioConverter,
              let pcmData = converter.convert(buffer: buffer, from: inputFormat) else {
            return
        }
        
        onAudioData?(pcmData)
    }
}

enum AudioCaptureError: Error {
    case permissionDenied
    case engineStartFailed
}

