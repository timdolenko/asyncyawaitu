# Module 2/4

*Convert your old APIs to async/await!*

<img width="352" alt="Screenshot 2022-06-13 at 15 26 01" src="https://user-images.githubusercontent.com/35912614/173363332-c963e186-5b4a-428f-812b-384594f8d4ad.png">

### 1. [Callback API to async/await](https://github.com/timdolenko/asyncyawaitu/blob/master/2-Converting-APIs.md#converting-callback-api-to-asyncawait)
### 2. [MainActor](https://github.com/timdolenko/asyncyawaitu/edit/master/2-Converting-APIs.md)
### 3. [Delegate API to async/await](https://github.com/timdolenko/asyncyawaitu/edit/master/2-Converting-APIs.md)

## Converting callback API to async/await

Let's continue with our project and open `asyncyawaituApp.swift`, and enable the 2nd screen of the project:
```swift
@main
struct asyncyawaituApp: App {
    var body: some Scene {
        WindowGroup {
//            PictureThumbnailsView()
            IamFeelingLuckyView()
//            MagicButtonView()
//            DonationsView()
        }
    }
}

```
Run the app to see how it looks!

If you tap `Play Slot` it will generate 3 random emojis and show it on the screen.

<img width="201" alt="Screenshot 2022-06-13 at 15 27 08" src="https://user-images.githubusercontent.com/35912614/173364188-51ddb602-422b-479e-8f6d-09633ad069fd.png">

If you tap `I am feeling lucky` you have a 30% chance that you will "get lucky"!

<img width="352" alt="Screenshot 2022-06-13 at 15 26 01" src="https://user-images.githubusercontent.com/35912614/173363953-257f1a6e-d4e3-460c-9b31-5c62fb3dfd24.png">

You can have a quick look at the view and the view model. We use 2 "APIs" to make it work, let's start with the `LuckySlot`. It uses callback to return the result.
```swift
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
```


Let's convert it to async await. Let's say we want to keep the old API, we don't want to modify it, and we want to create an async-wrapper-API.
Let's imagine how our new API might look like:
```swift
public class LuckySlotAsync {
    func play() async throws -> [LuckySlotItem] {}
}
```
Looks good right? Okay, let's say we inject `LuckySlot` like that:
```swift
private let slot: LuckySlot

init(slot: LuckySlot = LuckySlotLive()) {
  self.slot = slot
}

func play() async throws -> [LuckySlotItem] {
  slot.play { }
}
```
Now what? Use `withCheckedThrowingContinuation`! Similar to `withTaskGroup` from [part 1](https://github.com/timdolenko/asyncyawaitu/blob/master/1-3-Task-Groups.md#task-groups). If you look into it's signature you'll see that it accepts closure with some `Continuation` and asynchronously returns `T`. Exactly what we need!
```swift
func withCheckedThrowingContinuation<T>(... _ body: (CheckedContinuation<T, Error>) -> Void) async throws -> T
```
Basically it takes closure and returns the async result!
```swift
func play() async throws -> [LuckySlotItem] {
      withCheckedThrowingContinuation { continuation in
          slot.play { result in

          }
      }
  }
```
Of course you can now use `continuation` to pass whatever result you get from the callback, finally, adding `try await`, we have:

```swift
func play() async throws -> [LuckySlotItem] {
    try await withCheckedThrowingContinuation { continuation in
        slot.play { result in
            continuation.resume(with: result)
        }
    }
}
```

It's time to use it inside viewModel:

```swift
let slot = LuckySlotAsync() // Now let's use async API!
```

And update `playSlot()` to fix compile issues:
```swift
func playSlot() async {
      do {
          let items = try await slot.play()
          self.lastResult = items
              .reduce(into: "", { $0 = $0 + $1.rawValue })
      } catch {
          self.isDisplayingError = true
      }
  }
```
And in the view, let's add `await`:
```swift
Button {
    Task { await viewModel.playSlot() }
} label: {
    Text("Play Slot")
}
```

And run! It still works! But there's an issue, now we update UI from the background thread! Ooops.
<img width="763" alt="Screenshot 2022-06-13 at 15 47 50" src="https://user-images.githubusercontent.com/35912614/173368102-971a1203-b2d8-4a3e-99ed-6a387938f8a0.png">

## Main Actor

Okay, it's time to introduce `MainActor`! Add `@MainActor` to the view model's class definition:
```swift
@MainActor class IamFeelingLuckyViewModel: ObservableObject {
```
Run the app! Problem is gone! We will discuss specifics of actors in the part 4, but what you need to know now is that adding `@MainActor` to class definitions moves all properties modifications to the main thread. You can also mark with `@MainActor` separate functions or properies of the class.

## Converting delegate API to async/await

Let's now go and wrap `LuckGenerator`!

How it looks now:
```swift
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
```

Let's try the same trick:
```swift
public class LuckGeneratorAsync: LuckGeneratorDelegate {
    
    private let generator: LuckGenerator
    
    public init(generator: LuckGenerator = LuckGeneratorLive()) {
        self.generator = generator
        
        // Don't forget to set the delegate!
        generator.delegate = self
    }
    
    public func play() async -> Bool {
        await withCheckedContinuation { continuation in 
            
        }
    }
    
    public func didGetLucky(with generator: LuckGenerator, didGetLucky: Bool) {
        
    }
}
```
Now what? Just store the continuation to make it accessible inside the delegate's `didGetLucky`:
```swift
private var activeContinuation: CheckedContinuation<Bool, Never>?
...

await withCheckedContinuation { continuation in
    self.activeContinuation = continuation
    generator.play()
}
...

public func didGetLucky(with generator: LuckGenerator, didGetLucky: Bool) {
    activeContinuation?.resume(returning: didGetLucky)
}
```

Well, that's all we had to do! Of course, viewModel has to be updated too:
```swift
private let luckGenerator = LuckGeneratorAsync()

init() {}
```
We don't need delegate no more! Remove `extension IamFeelingLuckyViewModel: LuckGeneratorDelegate { ... }`. And finally update `func playGenerator()`.

```swift
func playGenerator() async {
    let didGetLucky = await luckGenerator.play()

    guard didGetLucky else { return }

    isDisplayingJackpot = true
}
```
And inside the view:
```swift
Task { await viewModel.playGenerator() }
```

Run the app!

# [▶️ Module 3/4 - AsyncSequence](https://github.com/timdolenko/asyncyawaitu/blob/master/3-AsyncSequence.md)
