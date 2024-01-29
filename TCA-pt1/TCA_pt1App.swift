//
//  TCA_pt1App.swift
//  TCA-pt1
//
//  Created by Kien Hoang on 29/01/2024.
//

import SwiftUI
import ComposableArchitecture

@main
struct TCA_pt1App: App {
  var body: some Scene {
    WindowGroup {
      ContentView(
        store: Store(initialState: CounterReducer.State()) {
          CounterReducer()
            ._printChanges()
        }
      )
    }
  }
}
