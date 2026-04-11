//
//  Home.swift
//  MySchedule
//
//  Created by Aaron on 8/4/25.
//

import SwiftUI

struct Home: View {
    @State private var activeTabItem: TabItem = .schedule
    @State private var dates: [DateInfo] = []
    @State private var selectedDateID = UUID()
    @State private var choosedStartDate: Date = .init()
    @State private var choosedEndDate: Date = .init()
    var body: some View {
        VStack {
            TabView(selection: $activeTabItem) {
                HorizontalDatePicker(
                    dates: $dates,
                    selectedDateID: $selectedDateID,
                    choosedStartDate: $choosedStartDate,
                    choosedEndDate: $choosedEndDate
                )
                    .tag(TabItem.schedule)
                /// Hiding native Tab Bar
                    .toolbar(.hidden)
                
                NotesView()
                    .tag(TabItem.task)
                /// Hiding native Tab Bar
                    .toolbar(.hidden)
            }
            CustomTabBar()
        }
        .padding(10)
        .onAppear {
            choosedEndDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
            initializeStartAndEndDate()
            dates = generateDateInfo(startDay: choosedStartDate, endDay: choosedEndDate)

            guard let index = dates.firstIndex(where: { $0.date.dayForDetail == Date().dayForDetail }) else { return }
            selectedDateID = dates[index].id            
//            print("ID: \(selectedDateID)")
        }
    }
    
    /// Custom Tab Bar
    /// With more easy customization
    @ViewBuilder
    func CustomTabBar(_ tint: Color = .orange, _ inactiveTint: Color = .secondary) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(TabItem.allCases, id: \.rawValue) {
                TabItemView(tint: tint,
                            inactiveTint: inactiveTint,
                            tabItem: $0,
                            activeTabItem: $activeTabItem)
                
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(15)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7), value: activeTabItem)
    }
}

struct TabItemView: View {
    var tint: Color
    var inactiveTint: Color
    var tabItem: TabItem
    @Binding var activeTabItem: TabItem
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: tabItem.systemName)
                .font(.system(size: 25))
                .foregroundStyle(activeTabItem == tabItem ? tint : inactiveTint)
            
            Text(tabItem.rawValue)
                .font(.caption)
                .foregroundStyle(activeTabItem == tabItem ? tint : .gray)
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            activeTabItem = tabItem
        }
    }
}

#Preview {
    Home()
}

extension Home {
    private func initializeStartAndEndDate() -> Void {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        if let dateInfo = UserDefaults.standard.string(forKey: "CONFIRMEDADDANDENDDATE"), dateInfo
            .components(separatedBy: ":").count == 2 {
            choosedStartDate = dateInfo.components(separatedBy: ":")[0].stringForDate ?? .init()
            choosedEndDate = dateInfo.components(separatedBy: ":")[1].stringForDate ?? .init()
        }
        
        return
    }
    
    private func generateDateInfo(startDay: Date, endDay: Date) -> [DateInfo] {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 30
        let dateList = (0 ... days).compactMap { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: startDay) ?? .init()
            return DateInfo(date: date)
        }
        return dateList
    }
}
