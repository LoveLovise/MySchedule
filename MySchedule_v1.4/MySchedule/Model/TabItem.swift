//
//  TabItem.swift
//  MySchedule
//
//  Created by Aaron on 8/4/25.
//

import SwiftUI

enum TabItem: String, CaseIterable {
    case schedule = "Schedule"
    case task = "Task"
    
    var systemName: String {
        switch self {
        case .schedule:
            return "calendar.badge.clock"
        case .task:
            return "note.text"
        }
    }
    
    var index: Int {
        return TabItem.allCases.firstIndex(of: self) ?? 0
    }
}
