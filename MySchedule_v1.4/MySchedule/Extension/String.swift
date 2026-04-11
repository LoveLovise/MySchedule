//
//  String.swift
//  MySchedule
//
//  Created by Aaron on 8/1/25.
//

import SwiftUI

extension String {
    func toColor() -> Color {
        switch self {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "black": return .black
        case "white": return .white
        case "gray": return .gray
        case "primary": return .primary
        case "secondary": return .secondary
        default: return .brown
        }
    }
    
    var stringForDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"  // 匹配"20250801"格式
//        formatter.timeZone = TimeZone.current  // 使用UTC避免时区问题
//        formatter.locale = Locale(identifier: "en_US_POSIX")  // 固定区域设置
        return formatter.date(from: self)
    }
}

