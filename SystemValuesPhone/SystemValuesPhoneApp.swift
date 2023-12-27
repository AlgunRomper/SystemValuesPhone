//
//  SystemValuesPhoneApp.swift
//  SystemValuesPhone
//
//  Created by Algun Romper  on 27.12.2023.
//

import SwiftUI

@main
struct SystemValuesPhoneApp: App {
    @StateObject private var modelSystemValues = ViewModelSystemValuesOfPhone()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelSystemValues)
        }
    }
}
