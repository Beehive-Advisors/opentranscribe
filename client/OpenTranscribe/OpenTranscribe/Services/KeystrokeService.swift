//
//  KeystrokeService.swift
//  OpenTranscribe
//
//  Synthesizes keystrokes using CGEvent APIs
//

import AppKit
import Carbon

class KeystrokeService {
    private var hasAccessibilityPermission: Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func typeText(_ text: String) {
        guard hasAccessibilityPermission else {
            print("⚠️ Accessibility permission required for typing")
            return
        }
        
        for character in text {
            typeCharacter(character)
        }
    }
    
    private func typeCharacter(_ character: Character) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Create keyboard event
        let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
        let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        
        // Set Unicode string for the character
        var unicodeString = [UniChar](String(character).utf16)
        keyDownEvent?.keyboardSetUnicodeString(stringLength: unicodeString.count, unicodeString: &unicodeString)
        keyUpEvent?.keyboardSetUnicodeString(stringLength: unicodeString.count, unicodeString: &unicodeString)
        
        // Post events
        keyDownEvent?.post(tap: .cghidEventTap)
        keyUpEvent?.post(tap: .cghidEventTap)
    }
    
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}

