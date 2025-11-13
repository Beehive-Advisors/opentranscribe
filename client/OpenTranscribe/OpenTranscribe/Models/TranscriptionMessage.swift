//
//  TranscriptionMessage.swift
//  OpenTranscribe
//
//  Model for transcription messages from backend
//

import Foundation

struct TranscriptionMessage: Codable {
    let text: String
    let final: Bool
}

