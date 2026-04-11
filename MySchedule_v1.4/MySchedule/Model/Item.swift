//
//  Item.swift
//  MySchedule
//
//  Created by Aaron on 8/1/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    @Attribute(.unique) var id = UUID()
    
    var date: Date = Date()
    var modifyDate: Date = Date()
    var checkPoint: Date = Date()
    var correctCheckPoint: Date {
        let calendar = Calendar.current
        let now = Date()
        
        // 从 checkPoint 中提取时间部分（小时、分钟、秒）
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: checkPoint)
        
        // 获取今天的开始时间（00:00:00）
        let today = calendar.startOfDay(for: now)
        
        // 构建今天的检查点时间（今天 + checkPoint 的时间部分）
        let todayCheckpoint = calendar.date(byAdding: timeComponents, to: today)!
        
        // 比较今天的检查点时间和当前时间
        if todayCheckpoint > now {
            return todayCheckpoint
        } else {
            // 如果今天的检查点时间已过，返回明天的检查点时间
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            let tomorrowCheckpoint = calendar.date(byAdding: timeComponents, to: tomorrow)!
            return tomorrowCheckpoint
        }
    }
    
    var title: String = ""
    var content: String = ""
    var lineCount: Int = 0
    var contentLinkList: [URL] = []
    
    var isTask: Bool = true
    var isTop: Bool = false
    var isDailyTracking: Bool = false
    
    var isFinished: Bool = false
    
    var isRemoved: Bool = false
    
    var isModified: Bool = false
    
    var isShowMore: Bool = false
    
    init(date: Date = Date()) {
        self.timestamp = Date()
        self.date = date
    }
    
    var description: String {
        "date: \(date.dayForAll), modeifyDate: \(modifyDate.dayForAll), checkPoint: \(checkPoint.dayForAll), title: \(title), content: \(content), isTask: \(isTask), isTop: \(isTop), isFinished: \(isFinished), isRemoved: \(isRemoved), isModified: \(isModified)"
    }
}
