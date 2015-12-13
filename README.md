Sweetry
===

Sweetry is a small Swift framework that allows for retrying operations that might fail. It depends on the (excellent) [BrightFutures](https://github.com/Thomvis/BrightFutures) library by @thomvis.

Installation
---

To install via Carthage, add the following to your `Cartfile`:
```
github "jflinter/sweetry", ~> 0.1
```

Example usage
---

```swift

Retry(maxAttempts: 3, operation: {
  let promise = Promise<MyValue, MyError>()
  doSomeWorkThatMightFail({ result in
    promise.complete(result)
  })
  return promise.future
}).start()

```

Backoff strategy
---

You can customize the schedule at which a Retry will re-attempt its work by passing it a `BackoffStrategy` in its initializer. The library implements two concrete implementations of this protocol, `Linear` and `Exponential`.

