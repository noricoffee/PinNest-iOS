//
//  pinNestApp.swift
//  pinNest
//
//  Created by 吉田範之 on 2026/02/18.
//

import ComposableArchitecture
import FirebaseCore
import SwiftUI

@main
struct pinNestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        if DemoData.isEnabled {
            DemoData.setupThumbnails()
        }
    }

    var body: some Scene {
        WindowGroup {
            if DemoData.isEnabled {
                AppView(store: Store(initialState: AppReducer.State()) {
                    AppReducer()
                } withDependencies: {
                    $0.pinClient = DemoData.demoClient
                })
            } else {
                AppView(store: Store(initialState: AppReducer.State()) {
                    AppReducer()
                })
            }
        }
    }
}
