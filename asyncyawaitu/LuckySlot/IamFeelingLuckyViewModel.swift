import Foundation

class IamFeelingLuckyViewModel: ObservableObject {
    
    @Published var lastResult: String = "🙈🙈🙈"
    @Published var isDisplayingError: Bool = false
    @Published var isDisplayingJackpot: Bool = false
    
    let slot = LuckySlotLive()
    private let luckGenerator = LuckGeneratorLive()
    
    init() {
        luckGenerator.delegate = self
    }
    
    func playSlot() {
        slot.play { [weak self] result in
            guard let `self` = self else { return }
            
            switch result {
            case .success(let items):
                self.lastResult = items
                    .reduce(into: "", { $0 = $0 + $1.rawValue })
            case .failure:
                self.isDisplayingError = true
            }
        }
    }
    
    func playGenerator() {
        luckGenerator.play()
    }
}

extension IamFeelingLuckyViewModel: LuckGeneratorDelegate {
    func didGetLucky(with generator: LuckGenerator, didGetLucky: Bool) {
        guard didGetLucky else { return }
        
        isDisplayingJackpot = true
    }
}
