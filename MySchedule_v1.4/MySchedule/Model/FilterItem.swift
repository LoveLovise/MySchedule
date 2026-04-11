//
//  FilterItem.swift
//  MySchedule
//
//  Created by Aaron on 8/11/25.
//

import SwiftUI

struct FilterItem: Identifiable {
    var id = UUID()
    
    var isByDate: Bool = false
    var isByTop: Bool = false
    var isByUnFinished: Bool = false
    var isByNote: Bool = false
    var isByTask: Bool = false
    var isEnableChooseNoteAndTask: Bool = false
    var isRemoved: Bool = false
    var isByFinished: Bool = false
    var isEnableUnAndFinished: Bool = false
    
    var startDate: Date = .init()
    var endDate: Date = .init()        
}
