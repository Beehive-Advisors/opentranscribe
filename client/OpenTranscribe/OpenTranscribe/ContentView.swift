//
//  ContentView.swift
//  OpenTranscribe
//
//  Main UI view
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TranscriptionViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("OpenTranscribe")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            // Status indicator
            HStack {
                Circle()
                    .fill(viewModel.isTranscribing ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
                Text(viewModel.isTranscribing ? "Transcribing..." : "Stopped")
                    .font(.headline)
            }
            
            // Toggle button
            Button(action: {
                viewModel.toggleTranscription()
            }) {
                Text(viewModel.isTranscribing ? "Stop Transcription" : "Start Transcription")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(viewModel.isTranscribing ? Color.red : Color.green)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            
            // Current transcription text
            ScrollView {
                Text(viewModel.currentText.isEmpty ? "Transcription will appear here..." : viewModel.currentText)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(maxHeight: 200)
            
            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

#Preview {
    ContentView()
}

