import AVFoundation

class AudioService {
    static let shared = AudioService()
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    func speak(_ text: String, rate: Float = 0.5) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.volume = 1.0 // Ensure volume is up
        
        // 1. Try to find IELTS-preferred British English
        if let britishVoice = AVSpeechSynthesisVoice(language: "en-GB") {
            utterance.voice = britishVoice
        } 
        // 2. Fallback to any English voice
        else if let englishVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language.contains("en") }) {
            utterance.voice = englishVoice
        }
        // 3. System default if nothing else matches
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        synthesizer.speak(utterance)
    }
}
