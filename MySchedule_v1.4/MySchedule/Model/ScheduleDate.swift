//
//  ScheduleDate.swift
//  MySchedule
//
//  Created by Aaron on 8/1/25.
//

import SwiftUI
import SwiftData

@Model
class ScheduleItem {
    var timestamp: Date
    
    @Attribute(.unique) var id = UUID()
    
    var startDate = Date()
    var endDate = Date()
    var content: String = ""
    var color: String = "blue"
    
    var startDateNum: Int { startDate.dayForNumber }
    var endDateNum: Int { endDate.dayForNumber }
    
    init(startDate: Date = .init(), endDate: Date = .init(), content: String = "", color: String = "blue") {
        self.timestamp = Date()
        self.startDate = startDate
        self.endDate = endDate
        self.content = content
        self.color = color
    }
}
