# Async let and Task Groups - Parallel execution
[⏪ Module 1/4](https://github.com/timdolenko/asyncyawaitu/blob/master/1-Basics.md)

## Async Let

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
    return Thumbnail(id: id, image: thumbnail)
}
```

Okay, there's one more thing, in our view model, let's call the new function:
```swift
public func onAppear() async {
...
    let result = try await repository.fetchThumbnails()

    DispatchQueue.main.async { [weak self] in
        self?.images = result
    }
...
}
```
Finally, run the app!

Here's what we see in the console:
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

## Task Groups

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

That sucks! How do we fix it? `async let` won't help us here (you can try 😉). Let's remove everything inside `fetchThumbnails`, and add:

```swift
withTaskGroup(of: Thumbnail.self) { group in 
}
```

That gives us a closure with `group`, that we can use to add tasks, like here:
```swift
group.addTask { try await self.fetchThumbnail(for: id) }
```
Okay, we need our `for in` here:
```swift
for id in ids {
    group.addTask { try await self.fetchThumbnail(for: id) }
}
```
Since `fetchThumbnail(for:)` throws, let's update `withTaskGroup` to `withThrowingTaskGroup` and try and await itself:
```swift
try await withThrowingTaskGroup(of: Thumbnail.self) { group in

    for id in ids {
        group.addTask { try await self.fetchThumbnail(for: id) }
    }
}
```
Now, let's finally await for the results. Since in the for loop we actually fire all the functions now we just have to wait for all of them and finally:
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

Group here actually conforms to `AsyncSequence` that we discuss later in the [Part 3](https://github.com/timdolenko/asyncyawaitu/edit/master/3-AsyncSequence.md)! That's why we use `for await in` here. Nothing to worry about!

Okay, now let's run the app! What do we see now? The app is much faster! And have a look in the console - image downloading now happens in parallel!
