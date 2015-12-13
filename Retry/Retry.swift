//
//  Retry.swift
//  Dashboard
//
//  Created by Jack Flintermann on 12/12/15.
//  Copyright © 2015 Stripe. All rights reserved.
//

import BrightFutures
import Result

public protocol BackoffStrategy {
    func timeToWait(iteration: Int) -> NSTimeInterval
}

public enum BackoffStrategies: BackoffStrategy {
    case Linear(initialDelay: NSTimeInterval, delta: NSTimeInterval)
    case Exponential(initialDelay: NSTimeInterval, exponentBase: Int)
    public func timeToWait(iteration: Int) -> NSTimeInterval {
        if iteration == 0 { return 0 }
        switch self {
            case .Linear(let initialDelay, let delta): return initialDelay + (delta * Double(iteration - 1))
            case .Exponential(let initialDelay, let exponentBase): return initialDelay * pow(Double(exponentBase), Double(iteration - 1))
        }
    }
}

public enum RetryError: ErrorType {
    case ExceededMaxAttempts(attemptCount: Int)
}

public class Retry<T, E: ErrorType> {
    
    var future: Future<T, RetryError> { return self.promise.future }
    public func start() {
        if self.started { return }
        self.started = true
        self.run(self.maxAttempts, iteration: 0, after: .In(0))
    }
    
    private let maxAttempts: Int?
    private let promise: Promise<T, RetryError>
    private let backoffStrategy: BackoffStrategy
    private let operation: Void -> Future<T, E>
    private let queue: Queue
    private var started = false

    public init(maxAttempts: Int? = nil, backoffStrategy: BackoffStrategy = BackoffStrategies.Exponential(initialDelay: 5, exponentBase: 2), queue: Queue = Queue.global, operation: Void -> Future<T, E>) {
        self.maxAttempts = maxAttempts
        self.backoffStrategy = backoffStrategy
        self.promise = Promise<T, RetryError>()
        self.operation = operation
        self.queue = queue
    }
    
    private func run(remainingAttempts: Int?, iteration: Int, after: TimeInterval) {
        if remainingAttempts == 0 {
            promise.failure(.ExceededMaxAttempts(attemptCount: iteration))
            return
        }
        self.queue.after(after) { [weak self] in
            guard let strongself = self else { return }
            strongself.operation().onSuccess(callback: strongself.promise.success).onFailure(callback: { error in
                let timeToWait = TimeInterval.In(strongself.backoffStrategy.timeToWait(iteration + 1))
                strongself.run(remainingAttempts.map({$0 - 1}), iteration: iteration + 1, after: timeToWait)
            })
        }
    }
}
