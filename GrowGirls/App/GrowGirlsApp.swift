//
//  GrowGirlsApp.swift
//  GrowGirls
//
//  Created by Kamil on 11/11/2026.
//

import SwiftUI

@main
struct GrowGirlsApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(AppState.shared)
        }
    }
}
