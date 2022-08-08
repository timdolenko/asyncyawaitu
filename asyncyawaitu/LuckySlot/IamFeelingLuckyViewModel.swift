import Foundation

class IamFeelingLuckyViewModel: ObservableObject {
    
    @Published var lastResult: String = "🙈🙈🙈"
    @Published var isDisplayingError: Bool = false
    @Published var isDisplayingJackpot: Bool = false
    
    let slot = LuckySlotAsync()
    private let luckGenerator = LuckGeneratorAsync()
    
    init() {}
    
    func playSlot() async {
        do {
            let items = try await slot.play()
            
            self.lastResult = items
                .reduce(into: "", { $0 = $0 + $1.rawValue })
        } catch {
            self.isDisplayingError = true
        }
    }
    
    func playGenerator() async {
        let didGetLucky = await luckGenerator.play()
        guard didGetLucky else { return }
        
        isDisplayingJackpot = true
    }
}
