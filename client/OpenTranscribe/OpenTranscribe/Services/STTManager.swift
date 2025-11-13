//
//  STTManager.swift
//  OpenTranscribe
//
//  WebSocket client for real-time transcription
//

import Foundation
import Combine

class STTManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var receiveTask: Task<Void, Never>?
    
    @Published var isConnected = false
    @Published var currentText = ""
    @Published var errorMessage: String?
    
    private var committedText = "" // Text already typed
    private var onTranscription: ((String, Bool) -> Void)?
    
    // Backend URL - update for production
    private let backendURL = "wss://stt.beehive-advisors.com/stream"
    // For local testing: "ws://localhost:8000/stream"
    
    func connect(onTranscription: @escaping (String, Bool) -> Void) {
        self.onTranscription = onTranscription
        
        guard let url = URL(string: backendURL) else {
            errorMessage = "Invalid backend URL"
            return
        }
        
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        webSocketTask = urlSession?.webSocketTask(with: url)
        webSocketTask?.resume()
        
        startReceiveLoop()
        isConnected = true
    }
    
    func disconnect() {
        receiveTask?.cancel()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession = nil
        isConnected = false
        committedText = ""
        currentText = ""
    }
    
    func sendAudio(_ audioData: Data) {
        guard isConnected, let task = webSocketTask else {
            return
        }
        
        task.send(.data(audioData)) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Send error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func startReceiveLoop() {
        receiveTask = Task {
            while !Task.isCancelled {
                do {
                    guard let task = webSocketTask else { break }
                    
                    let message = try await task.receive()
                    
                    switch message {
                    case .string(let text):
                        await handleTranscriptionMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            await handleTranscriptionMessage(text)
                        }
                    @unknown default:
                        break
                    }
                } catch {
                    if !Task.isCancelled {
                        DispatchQueue.main.async {
                            self.errorMessage = "Receive error: \(error.localizedDescription)"
                            self.isConnected = false
                        }
                    }
                    break
                }
            }
        }
    }
    
    @MainActor
    private func handleTranscriptionMessage(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let message = try? JSONDecoder().decode(TranscriptionMessage.self, from: data) else {
            return
        }
        
        currentText = message.text
        
        if message.final {
            // Type only the new text (diff from committed)
            let newText = String(message.text.dropFirst(committedText.count))
            if !newText.isEmpty {
                onTranscription?(newText, true)
                committedText = message.text
            }
        } else {
            // Update UI only, don't type interim text
            onTranscription?(message.text, false)
        }
    }
    
    // MARK: - URLSessionWebSocketDelegate
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async {
            self.isConnected = true
            self.errorMessage = nil
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            self.isConnected = false
            if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
                self.errorMessage = "Connection closed: \(reasonString)"
            }
        }
    }
}

