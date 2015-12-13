//
//  RetryTests.swift
//  RetryTests
//
//  Created by Jack Flintermann on 12/12/15.
//  Copyright © 2015 jflinter. All rights reserved.
//

import XCTest
@testable import Retry
import BrightFutures
import Result

enum RetryTestError: ErrorType {
    case TestError
}

class RetryTests: XCTestCase {
    
    func testLinearBackoff() {
        let times = [0, 1, 2, 3, 4].map({ return BackoffStrategy.Linear(initialDelay: 1, delta: 5).timeToWait($0) })
        XCTAssertEqual(times, [0, 1, 6, 11, 16])
    }
    
    func testExponentialBackoff() {
        let times = [0, 1, 2, 3, 4].map({ return BackoffStrategy.Exponential(initialDelay: 4, exponentBase: 2).timeToWait($0) })
        XCTAssertEqual(times, [0, 4, 8, 16, 32])
    }
    
    func testSuccess() {
        let retry = Retry(operation: {
            return Future<Int, NoError>(value: 1)
        })
        let expectation = expectationWithDescription("woo")
        retry.future.onSuccess { _ in expectation.fulfill() }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testFailure() {
        let retry = Retry(maxAttempts: 1, operation: {
            return Future<NoValue, RetryTestError>(error: .TestError)
        })
        let expectation = expectationWithDescription("woo")
        retry.future.onFailure { (error) in
            if case RetryError.ExceededMaxAttempts(let attempts) = error {
                XCTAssertEqual(attempts, 1)
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testInitialFailureThenSuccess() {
        var tries = 0
        let retry = Retry<Int, RetryTestError>(operation: {
            if tries == 0 {
                tries += 1
                return Future<Int, RetryTestError>(error: .TestError)
            } else {
                return Future<Int, NoError>(value: 1).promoteError()
            }
        })
        let expectation = expectationWithDescription("woo")
        retry.future.onSuccess { _ in expectation.fulfill() }
        waitForExpectationsWithTimeout(6, handler: nil)
    }
    
}
