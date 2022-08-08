# Module 4/4

*Actors and data races! 🎭*

<img width="273" alt="Screenshot 2022-06-13 at 16 38 29" src="https://user-images.githubusercontent.com/35912614/173378764-9ee73a51-a889-460c-8381-81c1183f20c9.png">

### 1. [Let’s create our own data race!]()
### 2. [Fixing it with actors and async/await]()
### 3. [A touch with @Sendable and nonisolated]()

## Let’s create our own data race!

Let's continue with our project and open `asyncyawaituApp.swift`, and enable the 4th screen of the project:
```swift
@main
struct asyncyawaituApp: App {
    var body: some Scene {
        WindowGroup {
//            PictureThumbnailsView()
//            IamFeelingLuckyView()
//            MagicButtonView()
            DonationsView()
        }
    }
}
```
