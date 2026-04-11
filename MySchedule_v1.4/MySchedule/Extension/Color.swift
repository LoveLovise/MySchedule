//
//  Color.swift
//  MySchedule
//
//  Created by Aaron on 8/1/25.
//

import SwiftUI

extension Color {
    func toString() -> String {
        switch self {
        case .red: return "red"
        case .blue: return "blue"
        case .green: return "green"
        case .yellow: return "yellow"
        case .orange: return "orange"
        case .purple: return "purple"
        case .pink: return "pink"
        case .black: return "black"
        case .white: return "white"
        case .gray: return "gray"
        case .primary: return "primary"
        case .secondary: return "secondary"
        default: return "unknown"
        }
    }
}

