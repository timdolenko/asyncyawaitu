import Foundation

@MainActor class MagicButtonViewModel: ObservableObject {
    
    @Published var output: String = "🙈"
    
    private let center = NotificationCenter.default
    
    public func sendNotification() {}
    
    private func present(_ result: String) async throws {
        output = result
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        output = "🙈"
    }
    
    public func cancel() {}
}

extension Notification.Name {
    static var asyncAwaity: Self {
        Self(rawValue: "asyncAwaity")
    }
}
