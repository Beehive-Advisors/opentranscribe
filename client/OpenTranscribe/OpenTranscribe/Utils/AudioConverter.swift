//
//  AudioConverter.swift
//  OpenTranscribe
//
//  Converts audio from input format to 16kHz mono PCM
//

import AVFoundation

class AudioConverter {
    private let targetFormat: AVAudioFormat
    
    init() {
        // Target format: 16kHz, 16-bit, mono PCM
        self.targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )!
    }
    
    func convert(buffer: AVAudioPCMBuffer, from inputFormat: AVAudioFormat) -> Data? {
        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            return nil
        }
        
        // Calculate output buffer size
        let ratio = targetFormat.sampleRate / inputFormat.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputFrameCapacity
        ) else {
            return nil
        }
        
        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        
        if let error = error {
            print("Audio conversion error: \(error)")
            return nil
        }
        
        // Convert to Data (Int16 samples)
        guard let int16ChannelData = outputBuffer.int16ChannelData else {
            return nil
        }
        
        let channelData = int16ChannelData.pointee
        let frameLength = Int(outputBuffer.frameLength)
        let data = Data(bytes: channelData, count: frameLength * MemoryLayout<Int16>.size)
        
        return data
    }
}

