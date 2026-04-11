//
//  LineCountPreferenceKey.swift
//  MySchedule
//
//  Created by Aaron on 8/7/25.
//

import SwiftUI

struct LineCountPreferenceKey: PreferenceKey {
    static var defaultValue: Int = 0
    static func reduce(value: inout Int, nextValue: () -> Int) {
        value = nextValue()
    }
}
