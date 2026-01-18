import Foundation
import AVFoundation

final class TTSService {
    static let shared = TTSService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    func speak(text: String, language: String = "zh-CN") {
        stop()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: mapLanguageCode(language))
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        }
    }
    
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }
    
    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }
    
    var isPaused: Bool {
        synthesizer.isPaused
    }
    
    private func mapLanguageCode(_ code: String) -> String {
        let map = [
            "zh-CN": "zh-CN",
            "zh-TW": "zh-TW",
            "en": "en-US",
            "ja": "ja-JP",
            "ko": "ko-KR",
            "fr": "fr-FR",
            "de": "de-DE",
            "es": "es-ES"
        ]
        return map[code] ?? code
    }
}
