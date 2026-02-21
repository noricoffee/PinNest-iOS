//
//  pinNestApp.swift
//  pinNest
//
//  Created by 吉田範之 on 2026/02/18.
//

import ComposableArchitecture
import SwiftUI

@main
struct pinNestApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: AppReducer.State()) {
                AppReducer()
            })
        }
    }
}
