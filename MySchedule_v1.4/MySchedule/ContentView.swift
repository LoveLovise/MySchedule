//
//  ContentView.swift
//  MySchedule
//
//  Created by Aaron on 8/1/25.
//

import SwiftUI
struct ContentView: View {
//    @State private var currentColorScheme: ColorScheme = .dark
    @AppStorage("MyScheduleCOLORSCHEME") var currentColorScheme: String = "dark"
    var body: some View {
        ZStack {
            Home()
                .preferredColorScheme(currentColorScheme == "dark" ? .dark : .light)
            
            Button(action: {                
                currentColorScheme = currentColorScheme == "dark" ? "light" : "dark"
            }) {
                EmptyView()
            }
            .buttonStyle(.plain)
            .keyboardShortcut("s", modifiers: [.command, .option])
        }
    }
}

#Preview {
    ContentView()
}
