import Foundation

@MainActor class MagicButtonViewModel: ObservableObject {
    
    @Published var output: String = "🙈"
    
    private let center = NotificationCenter.default
    
    private var subscription: Task<(), Error>!
    
    init() {
//        subscription = Task {
//            let sequence = TickerAsyncSequenceFactory().makeAsyncSequence()
//            for await number in sequence {
//                try await present("⏰ \(number) ⏰")
//            }
//        }
//        
//        subscription = Task {
//            for await _ in center.notifications(named: .asyncAwaity) {
//                try await present(LuckySlotItem.random())
//            }
//        }
//        
        subscription = Task {
            let _ = await center.notifications(named: .asyncAwaity).first(where: { _ in true })

            try await present("Only first")
        }
    }
    
    public func sendNotification() {
        center.post(name: .asyncAwaity, object: nil)
    }
    
    private func present(_ result: String) async throws {
        output = result
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        output = "🙈"
    }
    
    public func cancel() { subscription.cancel() }
}

extension LuckySlotItem {
    static func random() -> String {
        allCases.randomElement()!.rawValue
    }
}

extension Notification.Name {
    static var asyncAwaity: Self {
        Self(rawValue: "asyncAwaity")
    }
}
