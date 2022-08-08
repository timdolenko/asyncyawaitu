import Foundation

@MainActor class MagicButtonViewModel: ObservableObject {
    
    @Published var output: String = "🙈"
    
    private var subscription: Task<(), Error>!
    
    init() {
        subscription = Task {}
    }
    
    private func present(_ result: String) async throws {
        output = result
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        output = "🙈"
    }
    
    public func cancel() { subscription.cancel() }
}
