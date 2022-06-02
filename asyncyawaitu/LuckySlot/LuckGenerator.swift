import Foundation

public class LuckGeneratorAsync: LuckGeneratorDelegate {
    
    private lazy var generator: LuckGeneratorLive = {
        let g = LuckGeneratorLive()
        g.delegate = self
        return g
    }()
    
    private var activeContinuation: CheckedContinuation<Bool, Never>?
    
    public func play() async -> Bool {
        
        return await withCheckedContinuation { continuation in
            self.activeContinuation = continuation
            generator.play()
        }
    }
    
    public func didGetLucky(with generator: LuckGenerator, didGetLucky: Bool) {
        activeContinuation?.resume(returning: didGetLucky)
    }
}

public protocol LuckGeneratorDelegate: AnyObject {
    func didGetLucky(with generator: LuckGenerator, didGetLucky: Bool)
}

public protocol LuckGenerator: AnyObject {
    
    var delegate: LuckGeneratorDelegate? { get set }
    
    /// If you're lucky delegate's `didGetLucky` method will be called
    func play()
}

// MARK: - Implementation

public class LuckGeneratorLive: LuckGenerator {
    public weak var delegate: LuckGeneratorDelegate?
    
    public init() {}
    
    public func play() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.125) { [weak self] in
            guard let `self` = self else { return }
            
            let didGetLucky = Int.random(in: 1...3) == 3
            
            self.delegate?.didGetLucky(with: self, didGetLucky: didGetLucky)
        }
    }
}
