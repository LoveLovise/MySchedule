//
//  Date.swift
//  MySchedule
//
//  Created by Aaron on 8/1/25.
//

import SwiftUI

extension Date {
    var dayForWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
//        formatter.timeZone = TimeZone.current
//        formatter.locale = Locale(identifier: "en_US_POSIX")  // 固定区域设置
        return formatter.string(from: self)
    }
    
    var dayForDetail: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
//        formatter.timeZone = TimeZone.current
//        formatter.locale = Locale(identifier: "en_US_POSIX")  // 固定区域设置
        return formatter.string(from: self)
    }
    
    var dayForAll: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd hh:mm"
//        formatter.timeZone = TimeZone.current
//        formatter.locale = Locale(identifier: "en_US_POSIX")  // 固定区域设置
        return formatter.string(from: self)
    }
    
    var dayForYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY"
//        formatter.timeZone = TimeZone.current
//        formatter.locale = Locale(identifier: "en_US_POSIX")  // 固定区域设置
        return formatter.string(from: self)
    }
    
    var dayForNumber: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"  // 匹配"20250801"格式
//        formatter.timeZone = TimeZone.current
//        formatter.locale = Locale(identifier: "en_US_POSIX")  // 固定区域设置
        return Int(formatter.string(from: self)) ?? 0
    }
}
