//
//  TranscriptionViewModel.swift
//  OpenTranscribe
//
//  ViewModel for managing transcription state
//

import Foundation
import Combine

class TranscriptionViewModel: ObservableObject {
    private let sttManager = STTManager()
    private let audioCapture = AudioCaptureService()
    private let keystrokeService = KeystrokeService()
    
    @Published var isTranscribing = false
    @Published var currentText = ""
    @Published var errorMessage: String?
    
    init() {
        // Request accessibility permission on init
        keystrokeService.requestAccessibilityPermission()
    }
    
    func toggleTranscription() {
        if isTranscribing {
            stopTranscription()
        } else {
            startTranscription()
        }
    }
    
    private func startTranscription() {
        guard audioCapture.hasPermission else {
            errorMessage = "Microphone permission required"
            return
        }
        
        // Connect WebSocket
        sttManager.connect { [weak self] text, isFinal in
            DispatchQueue.main.async {
                if isFinal {
                    // Type final text
                    self?.keystrokeService.typeText(text)
                } else {
                    // Update UI with interim text
                    self?.currentText = text
                }
            }
        }
        
        // Start audio capture
        do {
            try audioCapture.startCapture { [weak self] audioData in
                self?.sttManager.sendAudio(audioData)
            }
            isTranscribing = true
        } catch {
            errorMessage = "Failed to start audio capture: \(error.localizedDescription)"
            sttManager.disconnect()
        }
    }
    
    private func stopTranscription() {
        audioCapture.stopCapture()
        sttManager.disconnect()
        isTranscribing = false
        currentText = ""
    }
}

