//
//  ContentView.swift
//  TCA-pt1
//
//  Created by Kien Hoang on 29/01/2024.
//

import SwiftUI
import ComposableArchitecture

struct NumberFactClient {
  var fetch: (Int) async throws -> String
}

extension NumberFactClient: DependencyKey {
  static let liveValue = Self(
    fetch: { number in
      let (data, _) = try await URLSession.shared.data(
        from: URL(string: "http://numbersapi.com/\(number)")!
      )
      return String(decoding: data, as: UTF8.self)
    }
  )
}

extension DependencyValues {
  var numberFact: NumberFactClient {
    get { self[NumberFactClient.self] }
    set { self[NumberFactClient.self] = newValue }
  }
}

@Reducer
struct CounterReducer {
  @ObservableState
  struct State: Equatable {
    var count = 0
    var numberFact: String?
    var isLoadingFact = false
    var isTimerOn = false
  }
  
  enum Action: Equatable {
    case decrementButtonTapped
    case incrementButtonTapped
    case numberFactButtonTapped
    case numberFactResponse(String)
    case toggleTimerButtonTapped
    case timerTicked
  }
  
  private enum CancelID {
    case timer
  }
  
  @Dependency(\.numberFact) private var numberFact
  @Dependency(\.continuousClock) private var clock
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .decrementButtonTapped:
        state.count -= 1
        state.numberFact = nil
        return .none
      case .incrementButtonTapped:
        state.count += 1
        state.numberFact = nil
        return .none
      case .numberFactButtonTapped:
        state.numberFact = nil
        state.isLoadingFact = true
        return .run { [count = state.count] send in
          let fact = try await numberFact.fetch(count)
          await send(.numberFactResponse(fact))
        }
      case .numberFactResponse(let fact):
        state.numberFact = fact
        state.isLoadingFact = false
        return .none
      case .toggleTimerButtonTapped:
        state.isTimerOn.toggle()
        if state.isTimerOn {
          return .run { send in
            for await _ in self.clock.timer(interval: .seconds(1)) {
              await send(.timerTicked)
            }
          }
          .cancellable(id: CancelID.timer)
        } else {
          return .cancel(id: CancelID.timer)
        }
      case .timerTicked:
        state.count += 1
        return .none
      }
    }
  }
}

struct ContentView: View {
  let store: StoreOf<CounterReducer>
  
  var body: some View {
    Form {
      Section {
        Text("\(store.count)")
        Button("Decrement") {
          store.send(.decrementButtonTapped)
        }
        Button("Increment") {
          store.send(.incrementButtonTapped)
        }
      }
      Section {
        Button {
          store.send(.numberFactButtonTapped)
        } label: {
          HStack {
            Text("Get fact")
            if store.isLoadingFact {
              Spacer()
              ProgressView()
            }
          }
        }
        if let fact = store.numberFact {
          Text(fact)
        }
      }
      Section {
        if store.isTimerOn {
          Button("Stop timer") {
            store.send(.toggleTimerButtonTapped)
          }
        } else {
          Button("Start timer") {
            store.send(.toggleTimerButtonTapped)
          }
        }
      }
    }
  }
}

#Preview {
  ContentView(
    store: Store(initialState: CounterReducer.State()) {
      CounterReducer()
    }
  )
}
