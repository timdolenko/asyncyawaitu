Async/await was introduced in Swift 5.5 and if you still not sure how to use it - this tutorial should be more than enough to get you started!

We'll cover most of the real use cases with practical examples. Let's kick off!

<a href="https://www.youtube.com/watch?v=aZ6w3HH1t0w"><img width="215" alt="Screenshot 2022-08-15 at 15 55 41" src="https://user-images.githubusercontent.com/35912614/184648965-bbca0620-a3f2-4524-b249-6f94217f8c7a.png"></a>

### Here's what we will cover:
1. `async` functions
2. `async get` properties
3. `async let`
4. Parallel execution using `withTaskGroup` and `withThrowingTaskGroup`
5. Legacy APIs and `withCheckedContinuation` and `withCheckedThrowingContinuation`
6. Create array of events or `AsyncSequence` with `AsyncStream`
7. `actor` and `nonisolated` and why we need them

You can try each feature in the playground project you can grab [here](https://github.com/timdolenko/asyncyawaitu) to follow the tutorial and run the code on your machine!

## Foundations

### Why?

Let's start with why? Why the hell do we need it? Have a look:

```swift
public func fetchThumbnail(for id: String, completion: @escaping (Result<Thumbnail, Error>) -> Void) {
    let request = thumbnailURLRequest(for: id)

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
        } else if (response as? HTTPURLResponse)?.statusCode != 200 {
            completion(.failure(FetchError.badID))
        } else {
            guard let image = UIImage(data: data!) else {
                completion(.failure(FetchError.badImage))
                return
            }

            image.prepareThumbnail(of: Thumbnail.size) { thumbnail in
                guard let thumbnail = thumbnail else {
                    completion(.failure(FetchError.badImage))
                    return
                }
                completion(.success(Thumbnail(id: id, image: thumbnail)))
            }
        }
    }
    task.resume()
}
```

Boy this looks ugly. And it's a typical async code we had in our apps, until now.

### The first async function

Now let's make it pretty with async/await, and you'll see why we need it. 

Let's keep this ugly monster here and create a new function. 

```swift
public func fetchThumbnail(for id: String) async throws -> Thumbnail {
    let request = thumbnailURLRequest(for: id)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw FetchError.badID
    }

    guard let image = UIImage(data: data) else {
        throw FetchError.badImage
    }

    guard let thumbnail = await image.byPreparingThumbnail(ofSize: Thumbnail.size) else {
        throw FetchError.badImage
    }

    return Thumbnail(id: id, image: thumbnail)
}
```

First, we have to mark the function as `async`, it always goes before `throws`:
```swift
public func fetchThumbnail(for id: String) *async* throws -> Thumbnail
```

```swift
let (data, response) = try await URLSession.shared.data(for: request)
```

A lot of Apple APIs now have async alternatives for the functions we know.

Instead of passing the result through callback the function simply returns it and errors are thrown. That's something we do in our function too:

```swift
public func fetchThumbnail(for id: String) async *throws -> Thumbnail*
```

Now when we call a function like that, we have to `await` it on the callers side. It's done with `await` keyword which always goes after `try`. `try` is needed here to catch errors.

```swift
guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw FetchError.badID }
```

```swift
guard let image = UIImage(data: data) else { throw FetchError.badImage }
```

Here we see a further benefit - no we can use throw to return from a function with error. You can't do it inside the callback!

`image.byPreparingThumbnail` is just another async function provided for us by Apple. Nice!

Compare the 2 now. Which one is easier to read?

Let's actually use the function now, let's go to the `ViewModel` and replace the old `onAppear()`:

```swift
public func onAppear() async {
    do {
        let result = try await repository.fetchThumbnail(for: repository.randomId)

        DispatchQueue.main.async { [weak self] in
            self?.images = [result]
        }
    } catch {
        print(error)
    }
}
```

Now the function has to be marked `async`, and we handle errors with a `do/catch` block.

Let's go to the view now!

```swift
.onAppear { viewModel.onAppear() }
```
<img width="1079" alt="Screenshot 2022-08-15 at 16 53 47" src="https://user-images.githubusercontent.com/35912614/184659292-ded644d9-658e-48c9-b0d6-28dbbdae2511.png">

`'async' call in a function that does not support concurrency` screams at us!

How can we convert `.onAppear {}` to be async? - We can't! We use `Task` instead!
```swift
.onAppear {
    Task { await viewModel.onAppear() }
}
```

We dispatch a task (aka call an async function) this way from `non-async` context. It's a bridge between `async` and `non-async` worlds (and not only that).

Let's run the app now to see it work!

### Not only functions (async get)

Btw. functions are not the only things that can be marked async. You can have `async` `get` properties now too!

```swift
extension UIImage {
    var thumbnail: UIImage? {
        get async {
            await byPreparingThumbnail(ofSize: Thumbnail.size)
        }
    }
}
```

Let's use it it `fetchThumbnail`:

```swift
guard let thumbnail = await UIImage(data: data)?.thumbnail else { throw FetchError.badImage }
```

## Parallel execution (async let)

Let's imagine we want to fetch several images, like this:
```swift
public func fetchThumbnails() async throws -> [Thumbnail] {
    let t1 = try await fetchThumbnail(for: "100")
    let t2 = try await fetchThumbnail(for: "101")

    return [t1, t2]
}
```
Looks simple right? But let's run the app, and before that, let's add some print statement to our `fetchThumbnail(for id: String) async`:
```swift
public func fetchThumbnail(for id: String) async throws -> Thumbnail {
    print("start \(id)")
    ...

    print("end \(id)")
    return ...
}
```

And don't forget to call the new function in the `viewModel.onAppear()`.

Run the app! Here's what we see in the console:
```
start 100
end 100
start 101
end 101
```
We may also notice that loading is pretty slow, and that's because we get images one after the other, not in parallel.

How do we fix it? Actually, it's easy with `async let`. Add `async` before `let` in `fetchThumbnails()`, and remove `await`, like this:
```swift
async let t1 = try fetchThumbnail(for: "100")
```
And add `try await` on the `return` line:

```swift
public func fetchThumbnails() async throws -> [Thumbnail] {
    async let t1 = try fetchThumbnail(for: "100")
    async let t2 = try fetchThumbnail(for: "101")

    return try await [t1, t2]
}
```
Let's run! What do we see now?

```
start 100
start 101
end 100
end 101
```
We get them in parallel! Basically, when we type `async let`, we fire off the task, but we aren't waiting until it completes. We do it only when the variable is needed. In this case on the `return` line.

### Task Groups

Now let's say we have an array of `n` elements, let's actually say we want to fetch all images for our `ids` array, that is located inside `ThumnailRepositoryLive`.

How would you do it? Here's how I would do it:

```swift
public func fetchThumbnails() async throws -> [Thumbnail] {
    var result = [Thumbnail]()

    for id in ids {
        let image = try await fetchThumbnail(for: id)
        result.append(image)
    }

    return result
}
```

Let's run and see that images are downloaded one after another once again!

That sucks! How do we fix it? `async let` won't help us here (you can try 😉). 

Let's remove everything inside `fetchThumbnails`, and add:

```swift
public func fetchThumbnails() async throws -> [Thumbnail] {
    try await withThrowingTaskGroup(of: Thumbnail.self) { group in

        for id in ids {
            group.addTask { try await self.fetchThumbnail(for: id) }
        }

        var result = [Thumbnail]()

        for try await image in group {
            result.append(image)
        }

        return result
    }
}
```

That gives us a closure with `group`, that we can use to add tasks, like here:
```swift
group.addTask { try await self.fetchThumbnail(for: id) }
```

All we have to do is to await for them in a loop:
```swift
for try await image in group { ... }
```

Now let's run the app! What do we see now? The app is much faster! And have a look in the console - image downloading now happens in parallel!

## How to convert callback to async/await?

In the [example project](https://github.com/timdolenko/asyncyawaitu) we have 2 classes that represent `delegate` and `callback` APIs. Let's see how we provide async/await interface around them.

Here's our delegate API:

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

Here we just return 3 random emojis to some caller after a delay.

Let's create a wrapper for this class that would use `async/await`:

```swift
public class LuckySlotAsync {
    
    private let slot = LuckySlotLive()
    
    init() {}
    
    public func play() async throws -> [LuckySlotItem] {
        
        return try await withCheckedThrowingContinuation { continuation in
            slot.play { result in
                continuation.resume(with: result)
            }
        }
    }
}
```

We created an `async` function, that uses `LuckySlotLive` combined with `withCheckedThrowingContinuation`.

`withCheckedThrowingContinuation` allows us to convert the API. Now we can return whatever is passed inside the closure with `return`, by using `continuation` inside the closure.
It takes closure and returns the async result!

It's time to use it inside `viewModel`:

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
Fix the errors in the `view` to the same way we did before with `Task` and `await`! 

Update `struct asyncyawaituApp: App { ... }` to use the correct screen. 

```swift
//PictureThumbnailsView()
IamFeelingLuckyView()
```

Run the app! It still works! 

But there's an issue, now we update UI from the background thread! Ooops.

<img width="763" alt="Screenshot 2022-06-13 at 15 47 50" src="https://user-images.githubusercontent.com/35912614/173368102-971a1203-b2d8-4a3e-99ed-6a387938f8a0.png">

### Main Actor

Add `@MainActor` to the view model's class definition:
```swift
@MainActor class IamFeelingLuckyViewModel: ObservableObject {
```
Run the app! Problem is gone! Adding `@MainActor` to class definitions moves all properties modifications to the main thread. You can also mark with `@MainActor` separate functions or properies of the class.

### How to convert delegate to async/await?

Now let's convert our delegate API:

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

After some delay we will randomly get `true` or `false` via `didGetLucky(with generator: LuckGenerator, didGetLucky: Bool)` delegate function.

Let's create a wrapper for this class that would use `async/await`:

```swift
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
```

We use the same `withCheckedContinuation`, but now we use a little trick, we actually store it, to make it accessible inside didGetLucky(with:didGetLucky:).

Let's update the `viewModel` and the `view`:

We don't need delegate no more! Remove `extension IamFeelingLuckyViewModel: LuckGeneratorDelegate { ... }`. And finally update `func playGenerator()`.

```swift
private let luckGenerator = LuckGeneratorAsync()

init() {}

...

func playGenerator() async {
    let didGetLucky = await luckGenerator.play()

    guard didGetLucky else { return }

    isDisplayingJackpot = true
}
```

## How to use for-in loop with async/await

What if you could have an array of events? What if you could use for-each loop to iterate it? 

Let's take a simple example. Let's say we have a class that every second produces a number:

```swift
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
```

How would you turn this class into a sequence of events? We will use `AsyncStream` for that:

```swift
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
```

This way you can turn almost any class or API you have into an async sequency.

How we would use it?

Inside the initialiser of `MagicButtonViewModel`, please add for-in loop:

```swift
@MainActor class MagicButtonViewModel: ObservableObject {
    
    @Published var output: String = "🙈"
    
    private var subscription: Task<(), Error>!
    
    init() {
        subscription = Task {            
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
    
    public func cancel() { subscription.cancel() }
}
```

You can also iterate with for-in over other sequences of events like NotificationCenter.default.notifications(named:) for example! Try it out!

In the `view` add:
```swift
Button {
    viewModel.sendNotification()
} label: {
    Text("🪄 Play")
        .font(.title)
}
.padding()
```

Inside the `viewModel` add:
```swift
private let center = NotificationCenter.default

private var subscription: Task<(), Error>!

init() {
    subscription = Task {
        for await _ in center.notifications(named: .asyncAwaity) {
            try await present(LuckySlotItem.random())
        }
    }
}

public func sendNotification() {
    center.post(name: .asyncAwaity, object: nil)
}
```

With some extensions:
```swift
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
```

Run it!

You can even use methods like `.filter`, `.map`, or `.first` on your array of events:
```swift
init() {
    subscription = Task {
        let _ = await center.notifications(named: .asyncAwaity).first(where: { _ in true })

        try await present("Only first")
    }
}
```

## How to create a data race in Swift?

I created a sample screen, to demonstrate how we might create a data race in Swift. 

We iterate in a loop a 1000 times and each time call a function from global and main queues. The function just increments an integer.

Have a look into BankAccount and DonationsViewModel:

```swift
class BankAccount {

    private(set) var balance = 0
    
    func deposit() -> Int {
        balance = balance + 100
        return balance
    }
}
```

```swift
  public func receiveDeposits() {
      bankAccount = BankAccount()
      balance = bankAccount.balance.description

      for _ in 1...1000 {

          /// 1. Global queue
          DispatchQueue.global().async {
              self.depositAndDisplay()
          }

          /// 2. Main Queue
          depositAndDisplay()
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          self.checkResults()
      }
  }
```

Here's an example of data race in Swift:

<img width="1335" alt="data race" src="https://user-images.githubusercontent.com/35912614/183483569-a4d47547-f302-4454-bfb1-584b28bdf9af.png">

We call deposit 2 times, and expect the balance to be 200. But it's actually 100! It's called a data race. And it's a bug.

Before running the app edit the current scheme and enable "Thread Sanityser"

<img width="499" alt="Screenshot 2022-08-08 at 20 04 38" src="https://user-images.githubusercontent.com/35912614/183483985-32dcefe5-e2f5-4577-afe1-e579cc066dd3.png">

<img width="953" alt="Screenshot 2022-08-08 at 20 05 03" src="https://user-images.githubusercontent.com/35912614/183484091-4f787e96-2cbf-4715-a162-d69cfec66ebe.png">

Run the app and tap the first button on the screen!

We have a couple of problems. We expect to have $200,000 (2 function calls * 1000 iterations * 100 each increment), but we get only a fraction of it displayed on the screen and on the alert we see that we lack $300. Not good.

<img width="615" alt="Screenshot 2022-08-08 at 20 06 25" src="https://user-images.githubusercontent.com/35912614/183484380-6a4e8f22-181b-4d7c-9bc6-6c4ed697cf9e.png">

We also see that we have data raced warning triggered by the Thread Sanitizer:

<img width="815" alt="Screenshot 2022-08-08 at 20 06 25" src="https://user-images.githubusercontent.com/35912614/183484374-d14df2b7-309e-446b-bf04-8d1b2f449aec.png">

To fix it turn the BankAccount into `actor` replacing `class` with `actor`:
```swift
actor BankAccount { ... }
```

Actor is a special type which guarantees that access to it's members will be granted to only one thread at a time. No more data races! This time Thread B will just wait until Thread A finishes with calling the `deposit()` function. Actor is a reference type.

Let's fix compile issues.

<img width="1022" alt="Screenshot 2022-08-08 at 20 18 51" src="https://user-images.githubusercontent.com/35912614/183486255-d59f6b69-b25e-41c6-a792-3de8aa013f86.png">

Now every member of `BankAccount` is `async` and has to be awaited. With a `deposit()` it makes sence, but with other static things like `bankDetails()` it makes no sense. 

```swift
nonisolated func bankDetails() -> String { iban }
```

`nonisolated` will fix it. It can make a part of `actor` accessible with awaiting it.

```swift
public func receiveDeposits() async {
    bankAccount = BankAccount()
    balance = await bankAccount.balance.description

    for _ in 1...1000 {

        /// 1. Global queue
        DispatchQueue.global().async {
            Task {
                await self.depositAndDisplay()
            }
        }

        /// 2. Main Queue
        await depositAndDisplay()
    }

    try! await Task.sleep(nanoseconds: 1_000_000_000)

    await self.checkResults()
}
```

Let's fix `receiveDeposits()` by making it `async` and awaiting for the `bankAccount.balance`, and `self.depositAndDisplay()`.

```swift
public func depositAndDisplay() async {
    let result = await bankAccount.deposit()
    ...
```

```swift
public func checkResults() async {
    let actualBalance = await bankAccount.balance
    ...
```

Same applies to `depositAndDisplay()` and `checkResults()`.

Make `DonationsViewModel` `@MainActor` and run the app!
