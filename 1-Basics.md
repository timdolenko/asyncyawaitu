# Module 1/4

*Learn basics by fetching a bunch of images and displaying thumbnails*

![Simulator Screen Shot - iPhone 13 Pro - 2022-06-13 at 15 09 55](https://user-images.githubusercontent.com/35912614/173361329-f7a67d18-93b9-4d97-8626-d51611d7f7a5.jpeg)

### 1. [Async/await Basics](https://github.com/timdolenko/asyncyawaitu/edit/master/1-Basics.md#basics)
### 2. [Async properties](https://github.com/timdolenko/asyncyawaitu/edit/master/1-Basics.md#async-properties)
### 3. [Async let](https://github.com/timdolenko/asyncyawaitu/blob/master/1-3-Task-Groups.md)
### 4. [Task Groups](https://github.com/timdolenko/asyncyawaitu/blob/master/1-3-Task-Groups.md#task-groups)

## Basics

Have a look into view and view model of `PictureThumbnails`

Then let's have a look into `fetchThumbnail` in `ThumnailRepositoryLive`

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

That looks ugly! Or like a normal async code with callbacks:
1) **Easy to make mistakes and forget to call completions**
2) **Can't use `throw` error handling**

[More on "why async await?"](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md#motivation-completion-handlers-are-suboptimal)

## First async function

Let's create our first async function by refactoring this function! Let's start with the signature:

```swift
public func fetchThumbnail(for id: String)
```

We have to 
1. Mark it `async`
2. Declare return type, in this case `Thumbnail`
3. Since we want to notify caller about the error, we will mark the function `throws`
```swift
public func fetchThumbnail(for id: String) async throws -> Thumbnail
```
```
💡 async goes before throws
```

We still call the "normal" function as usual
```swift
let request = thumbnailURLRequest(for: id)
```

`URLSession.shared.dataTask` is transformed into `URLSession.shared.data`.
Many APIs provided by Apple now have autogenerated `async` alternatives, and this is one of them.
This function returns `data, response, error` in a callback. This time it's a bit different.
1. Returns tuple of `(data, response)`
2. Throws the error, therefore the call has to be marked with `try`
3. Is async and has to be marked with `await`

```swift
let (data, response) = try await URLSession.shared.data(for: request)
```

```
💡 try goes before await
```

Next we want to check for the `statusCode` as before.
But now ✨ magic ✨ happens - we can use throws!
```swift
guard (response as? HTTPURLResponse)?.statusCode == 200 else {
    throw FetchError.badID
}
```
Same here:
```swift
guard let image = UIImage(data: data) else {
    throw FetchError.badImage
}
```
Another async function, in this case it's now called `byPreparingThumbnail`:
```swift
guard let thumbnail = await image.byPreparingThumbnail(ofSize: Thumbnail.size) else {
    throw FetchError.badImage
}
```
And finally return!
```swift
return Thumbnail(id: id, image: thumbnail)
```

And the result:
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

So much better, huh? We can refactor it even further:
```swift
public func fetchThumbnail(for id: String) async throws -> Thumbnail {
    let request = thumbnailURLRequest(for: id)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw FetchError.badID }

    guard let thumbnail = await UIImage(data: data)?
        .byPreparingThumbnail(ofSize: Thumbnail.size) else { throw FetchError.badImage }

    return Thumbnail(id: id, image: thumbnail)
}
```
**2x less lines!** And that's not all. Let's actually use the function now, let's go to the `viewModel`.

```swift
public func onAppear() {
    repository.fetchThumbnail(for: repository.randomId) { [weak self] result in
        switch result {
        case .success(let thumbnail):
            DispatchQueue.main.async { [weak self] in
                self?.images = [thumbnail]
            }
        case .failure(let error):
            print(error)
        }
    }
}
```

Let's remove everything from `onAppear()`, and start from scratch. We still want to call our function, but now it has to be awaited.
```swift
let result = await repository.fetchThumbnail(for: repository.randomId)
```
But then the `onAppear()` has to become `async` too! We are pushing this `async` madness up the chain!
```swift
public func onAppear() async {
```
It also throws now! This time we want to handle it, since we are already in viewModel, no one wants to do it in the view!
```swift
do {
    let result = try await repository.fetchThumbnail(for: repository.randomId)
} catch {
    print(error)
}
```
Okay, finally let's use `result` in the `do-catch` block:
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

The project still doesn't compile! Let's go to the view now!

`'async' call in a function that does not support concurrency` screams at us!

How can we convert `.onAppear {}` to be async? - We can't! We use `Task` instead!
```swift
.onAppear {
    Task { await viewModel.onAppear() }
}
```
We dispatch a task (aka call an async function) this way from `non-async` context. It's a bridge between `async` and `non-async` worlds (and not only that).
Let's run the app now to see it work!

## Async properties

Now, final bit of refactoring, let's go back to `ThumbnailRepository.swift` and let's explore async properties! Add:

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
guard let thumbnail = await UIImage(data: data)?
    .byPreparingThumbnail(ofSize: Thumbnail.size) else { throw FetchError.badImage }
```
to:
```swift
guard let thumbnail = await UIImage(data: data)?.thumbnail else { throw FetchError.badImage }
```

# [▶️ Async let and Task Groups](https://github.com/timdolenko/asyncyawaitu/blob/master/1-3-Task-Groups.md)
