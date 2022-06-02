import Foundation

public class TickerAsyncSequenceFactory {
    
    func makeAsyncSequence() -> AsyncStream<Int> {
        AsyncStream(Int.self) { continuation in
            let ticker = Ticker()
            
            ticker.tick = { continuation.yield($0) }
            
            continuation.onTermination = { _ in
                ticker.stop()
            }
            
            ticker.start()
        }
    }
}

public class Ticker {
    
    deinit { print("Deinit Timer") }
    
    public var tick: ((Int) -> ())?
    
    public private(set) var counter: Int = 0
    
    private var timer: Timer?
    
    init() {}
    
    func start() {
        counter = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let `self` = self else { return }
            self.tick?(self.counter)
            self.counter += 1
        }
    }
    
    func stop() {
        timer?.invalidate()
    }
}
