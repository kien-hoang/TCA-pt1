//
//  TCA_pt1Tests.swift
//  TCA-pt1Tests
//
//  Created by Kien Hoang on 29/01/2024.
//

import XCTest
import ComposableArchitecture
@testable import TCA_pt1

@MainActor
final class TCA_pt1Tests: XCTestCase {
  func testCounter() async {
    let store = TestStore(initialState: CounterReducer.State()) {
      CounterReducer()
    }

    await store.send(.incrementButtonTapped) {
      $0.count = 1
    }
  }
  
  func testTimer() async {
    let clock = TestClock()
    let store = TestStore(initialState: CounterReducer.State()) {
      CounterReducer()
    } withDependencies: {
      $0.continuousClock = clock
    }
    
    await store.send(.toggleTimerButtonTapped) {
      $0.isTimerOn = true
    }
    await clock.advance(by: .seconds(1))
    await store.receive(.timerTicked) {
      $0.count = 1
    }
    await clock.advance(by: .seconds(1))
    await store.receive(.timerTicked) {
      $0.count = 2
    }
    await store.send(.toggleTimerButtonTapped) {
      $0.isTimerOn = false
    }
  }
  
  func testGetFact() async {
    let store = TestStore(initialState: CounterReducer.State()) {
      CounterReducer()
    } withDependencies: {
      $0.numberFact.fetch = { "\($0) is a good number Brent" }
    }
    
    await store.send(.numberFactButtonTapped) {
      $0.isLoadingFact = true
    }
    
    await store.receive(\.numberFactResponse) {
      $0.isLoadingFact = false
      $0.numberFact = "0 is a good number Brent"
    }
  }
  
  func testGetFact_failure() async {
    let store = TestStore(initialState: CounterReducer.State()) {
      CounterReducer()
    } withDependencies: {
      $0.numberFact.fetch = { _ in
        struct SomeError: Error {}
        throw SomeError()
      }
    }
    
    XCTExpectFailure()
    await store.send(.numberFactButtonTapped) {
      $0.isLoadingFact = true
    }
  }
}
