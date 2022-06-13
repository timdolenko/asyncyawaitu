# Task Groups - Parallel execution 
[⏪ Module 1/4](https://github.com/timdolenko/asyncyawaitu/blob/master/1-Basics.md)

Let's say we want to fetch an array of images. How would you do it?

Here's how I would do it:

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
start 1
end 1
start 10
end 10
start 100
end 100
start 1000
end 1000
start 1002
end 1002
start 1003
end 1003
start 1004
end 1004
start 1005
end 1005
start 1006
end 1006
start 1009
end 1009
start 101
end 101
```
We may also notice that loading is pretty slow, and that's because we get images one after the other, not in parallel.

That sucks! How do we fix it? Let's go back to our view model, to our `func fetchThumbnails() async`, remove everything, and add:

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
Now, let's finally await for the results. Since in the for loop we actually fire all the functions now we just have to wait for all of them:
```swift
var result = [Thumbnail]()
            
for try await image in group {
    result.append(image)
}

return result
```

Group here actually conforms to `AsyncSequence` that we discuss later in the [Part 3](https://github.com/timdolenko/asyncyawaitu/edit/master/3-AsyncSequence.md)! That's why we use `for await in` here. Nothing to worry about!

Okay, now let's run the app! What do we see now? The app is much faster! And have a look in the console:

```
start 1
start 10
start 100
start 1000
start 1002
start 1003
start 1004
start 1005
start 1006
start 1009
start 101
end 1005
end 1000
end 1009
end 1
end 1003
end 1004
end 1006
end 10
end 100
end 101
end 1002
```
Image downloading now happens in parallel 
