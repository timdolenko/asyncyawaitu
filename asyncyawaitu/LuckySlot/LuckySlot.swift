import Foundation

public enum LuckySlotItem: String, CaseIterable {
    case star = "⭐️"
    case fire = "🔥"
    case rocket = "🚀"
    case finger = "👉"
    case frog = "🐸"
    case bug = "🐛"
}

public protocol LuckySlot {
    
    /// When you play, you will get result consisting of 3 `LuckySlotItems`
    func play(completion: @escaping (Result<[LuckySlotItem], Error>) -> ())
}

public class LuckySlotLive: LuckySlot {
    
    public func play(completion: @escaping (Result<[LuckySlotItem], Error>) -> ()) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.125) {
            completion(.success([
                LuckySlotItem.allCases.randomElement()!,
                LuckySlotItem.allCases.randomElement()!,
                LuckySlotItem.allCases.randomElement()!
            ]))
        }
    }
}
