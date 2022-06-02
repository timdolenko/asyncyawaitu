import Foundation

@MainActor class MagicButtonViewModel: ObservableObject {
    
    @Published var output: String = "🙈"
    
    private let center = NotificationCenter.default
    
    private lazy var subscription: Task<(), Error> = subscribe()
    
    init() {
        _ = subscription
    }
    
    public func sendNotification() {
        center.post(name: .asyncAwaity, object: nil)
    }
    
    public func subscribe() -> Task<(), Error> {
        
//        Task {
//            for await _ in center.notifications(named: .asyncAwaity) {
//                try await present("Magic \(LuckySlotItem.allCases.randomElement()!.rawValue)")
//            }
//        }
        
//        Task {
//            let _ = await center.notifications(named: .asyncAwaity)
//            try await present("Got first!")
//        }
        
        Task {
            for await number in TickerAsyncSequenceFactory().makeAsyncSequence() {
                try await present("⏰ \(number) ⏰")
            }
        }
    }
    
    private func present(_ result: String) async throws {
        output = result
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        output = "🙈"
    }
    
    public func cancel() {
        subscription.cancel()
    }
}

extension Notification.Name {
    static var asyncAwaity: Self {
        Self(rawValue: "asyncAwaity")
    }
}
