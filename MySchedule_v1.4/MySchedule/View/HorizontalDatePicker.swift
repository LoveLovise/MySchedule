//
//  HorizontalDatePicker.swift
//  MySchedule
//
//  Created by Aaron on 8/1/25.
//

import SwiftUI
import SwiftData

struct HorizontalDatePicker: View {
    
//    @State private var dates: [DateInfo] = []
    @Binding var dates: [DateInfo]
//    @State private var selectedDate: DateInfo = .init(date: Date())
//    @State private var selectedDateID = UUID()
    @Binding var selectedDateID: UUID
    @State private var dateInfo: Date?
    @State private var hoverID: UUID?
    @Environment(\.modelContext) private var modelContext    
    @Query private var scheduleItems: [ScheduleItem]
    @State private var scheduleItemList: [ScheduleItem] = []
    @State private var isShowAddDateSheet: Bool = false
    @State private var isShowAddSchudeueItemSheet: Bool = false
    @State private var isHovering: Bool = false
//    @State private var choosedStartDate: Date = .init()
    @Binding var choosedStartDate: Date
//    @State private var choosedEndDate: Date = .init()
    @Binding var choosedEndDate: Date
    
    @State private var scheduleStartDate: Date = .init()
    @State private var scheduleEndDate: Date = .init()
    @State private var scheduleContent: String = ""
    
    // CONFIRMEDADDANDENDDATE = "20250801:20260701"
    @State private var confirmAddAndEndDate: String = ""
    @State private var isFromScheduleEdit: Bool = false
    @State private var currentScheduleItem: ScheduleItem = .init()
    
    @State private var allowPickColors = ["blue", "red", "green", "yellow", "orange", "purple", "gray", "pink"]
    @State private var currentPickColor: String = "blue"
    @State private var animationItem: AnimationItem = .init()
//    @State private var isHoveringMicroSchedule: Bool = false
    var body: some View {
        VStack(spacing: 15) {
            Text("My Schedule")
                .font(.title)
                .bold()
            ScrollViewReader { proxy in
                VStack {
                    // Calendar View
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: 0) {
//                            ForEach(Array(dates.enumerated()), id: \.element.id) { index, dateItem in
                            ForEach(dates, id: \.id) { dateItem in
                                VStack(spacing: 5) {
                                    cardView(dateItem: dateItem)
                                    ForEach(checkDateInSchedule(dateItem: dateItem), id: \.id) { scheduleItem in
                                        Rectangle()
                                            .fill(scheduleItem.color.toColor())
                                            .frame(height: isHovering ? 20 : 2)
                                            .overlay {
                                                if isHovering {
                                                    Text(scheduleItem.content)
                                                        .font(.system(size: 8))
                                                        .bold()
                                                }
                                            }
                                            .containerShape(Rectangle())
                                            .onTapGesture(count: 2, perform: {
//                                                withTransaction {
                                                    isShowAddSchudeueItemSheet = true
                                                    isFromScheduleEdit = true
                                                    guard let index = scheduleItemList.firstIndex(where: { $0.id == scheduleItem.id }) else { return }
                                                    scheduleStartDate = scheduleItemList[index].startDate
                                                    scheduleEndDate = scheduleItemList[index].endDate
                                                    scheduleContent = scheduleItemList[index].content
                                                    currentPickColor = scheduleItemList[index].color
                                                    currentScheduleItem = scheduleItemList[index]
//                                                }
                                            })
                                    }
                                }
                                .id(dateItem.id)
                            }
                        }
                        .padding()
                        .padding(.top)
                    }
//                    .frame(height: 170)
//                    .background(Color.gray.opacity(0.2))
                    .onHover { isHovering in
                        self.isHovering = isHovering
                    }
                    // MARK: add and today button
                    .overlay (
                        HStack {
                            Button(action: {
                                isShowAddDateSheet = true
                            }) {
                                Text("Choose")
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                guard let index = dates.firstIndex(where: { $0.date.dayForDetail == Date().dayForDetail }) else { return }
                                selectedDateID = dates[index].id
                                withAnimation {
                                    proxy.scrollTo(selectedDateID, anchor: .center)
                                }
                            }) {
                                Text("Today")
                            }
                            .keyboardShortcut("d", modifiers: [.command])
                        }
                        ,alignment: .top
                    )
                    .onChange(of: selectedDateID) { oldValue, newValue in
                        withAnimation {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                    .overlay(
                        Button(action: {
                            isShowAddSchudeueItemSheet = true
                            isFromScheduleEdit = false
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 30))
                                .foregroundStyle(.blue)
                        }
                            .buttonStyle(.plain)
                            .keyboardShortcut("n", modifiers: [.command])
                        ,alignment: .bottomTrailing
                    )
                    
                    microScheduleItemView()
                }
            }
        }
        .sheet(isPresented: $isShowAddDateSheet, content: {
            addDataSheetView()
        })
        .sheet(isPresented: $isShowAddSchudeueItemSheet, content: {
            addSchudeueItemSheetView()
        })
        .overlay(
            Text("\(animationItem.content)")
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(animationItem.isSuccess ? .green : .red)
                .cornerRadius(10)
                .opacity(animationItem.isAnimation ? 1 : 0)
        )
        .onAppear {
            dateInfo = dates[0].date
            scheduleItemList = scheduleItems
        }
    }
    
    @ViewBuilder
    private func cardView(dateItem: DateInfo) -> some View {
        VStack {
            Text("\(dateItem.date.dayForWeek)")
                .font(.caption)
                .bold()
            Text(dateItem.date.dayForDetail)
                .font(.headline)
        }
        .padding(10)
        .foregroundColor(
            (dateItem.date.dayForWeek == "Sat" || dateItem.date.dayForWeek == "Sun") ? .secondary : .primary
        )
        .background(cardBackgroundColor(dateItem: dateItem))
        .cornerRadius(10)
        .padding(.horizontal, 2)
        .onHover(perform: { isHovering in
            if isHovering {
                hoverID = dateItem.id
            } else {
                hoverID = nil
            }
        })
        .overlay(
            Text("\(dateItem.date.dayForYear)")
                .font(.system(size: 8))
                .padding(3)
                .opacity(hoverID == dateItem.id ? 1 : 0)
            ,alignment: .topLeading
        )
        .onTapGesture {
            withAnimation(.spring) {
                scheduleStartDate = dateItem.date
                scheduleEndDate = dateItem.date
                selectedDateID = dateItem.id
            }
        }
    }
    
    @ViewBuilder
    private func addDataSheetView() -> some View {
        VStack(spacing: 15) {
            Text("CHOOSE DATE")
                .font(.title)
                .bold()
            
            HStack {
                Text("Start:")
                DatePicker("", selection: $choosedStartDate, displayedComponents: [.date])
            }
            
            HStack {
                Text("End:")
                DatePicker("", selection: $choosedEndDate, displayedComponents: [.date])
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    isShowAddDateSheet.toggle()
                }) {
                    Text("Cancel")
                        .frame(width: 65, height: 25)
                        .background(Color.yellow, in: .capsule)
                }
                
                Button(action: {
                    isShowAddDateSheet.toggle()
                    confirmAddAndEndDate = "\(choosedStartDate.dayForNumber):\(choosedEndDate.dayForNumber)"
                    dates = generateDateInfo(startDay: choosedStartDate, endDay: choosedEndDate)
                    UserDefaults.standard.set(confirmAddAndEndDate, forKey: "CONFIRMEDADDANDENDDATE")
                }) {
                    Text("Confirm")
                        .frame(width: 65, height: 25)
                        .background(Color.green, in: .capsule)
                }
            }
            .buttonStyle(.plain)
            .padding(.top)
        }
        .frame(width: 280, height: 190)
        .background(Color.brown)
        .cornerRadius(15)
        .shadow(radius: 2)
        .overlay(
            Text("\((Calendar.current.dateComponents([.day], from: choosedStartDate, to: choosedEndDate).day ?? 0)+1)")
                .bold()
                .padding(15)
                .foregroundStyle(.secondary)
            ,alignment: .topTrailing
        )
    }
    
    @ViewBuilder
    private func addSchudeueItemSheetView() -> some View {
        VStack(spacing: 10) {
            Text("ADD SCHEDULE")
                .font(.title)
                .bold()
            
            HStack(spacing: 3) {
                Text("Start:")
                DatePicker("", selection: $scheduleStartDate, displayedComponents: [.date])
            }.disabled(isFromScheduleEdit)
            
            HStack(spacing: 3) {
                Text("  End:")
                DatePicker("", selection: $scheduleEndDate, displayedComponents: [.date])
            }.disabled(isFromScheduleEdit)
            
            Picker("Color:", selection: $currentPickColor) {
                ForEach(allowPickColors, id: \.self) { colorStr in
                    Text(colorStr)
                        .frame(width: 110)
                        .onTapGesture {
                            currentPickColor = colorStr
                        }
                }
            }.disabled(isFromScheduleEdit)
            
            HStack(spacing: 3) {
                Text("Task:")
                Image(systemName: "star.fill")
                    .foregroundStyle(.red)
                    .font(.system(size: 5))
                TextField("Note", text: $scheduleContent)
                    .frame(width: 100)                
            }.disabled(isFromScheduleEdit)
            
            HStack(spacing: 20) {
                Button(action: {
                    isShowAddSchudeueItemSheet.toggle()
                    isFromScheduleEdit = false
                }) {
                    Text("Cancel")
                        .frame(width: 65, height: 25)
                        .background(Color.yellow, in: .capsule)
                }
                
                if isFromScheduleEdit {
                    Button(action: {
                        modelContext.delete(currentScheduleItem)
                        guard let index = scheduleItemList.firstIndex(where: { $0.id == currentScheduleItem.id }) else { return }
                        scheduleItemList.remove(at: index)
                        isShowAddSchudeueItemSheet = false
                    }) {
                        Text("Delete")
                            .frame(width: 65, height: 25)
                            .background(Color.red, in: .capsule)
                    }
                } else {
                    Button(action: {
                        let scheduleItem = ScheduleItem(startDate: scheduleStartDate, endDate: scheduleEndDate, content: scheduleContent, color: currentPickColor)
                        modelContext.insert(scheduleItem)
                        scheduleItemList.append(scheduleItem)
                        isShowAddSchudeueItemSheet.toggle()
                        isFromScheduleEdit = false
                    }) {
                        Text("Confirm")
                            .frame(width: 65, height: 25)
                            .background(Color.green, in: .capsule)
                    }.keyboardShortcut("s", modifiers: [.command])
                    .disabled(scheduleContent.isEmpty)
                }
            }
            .buttonStyle(.plain)
            .padding(.top)
        }
        .frame(width: 310, height: 260)
        .background(currentPickColor.toColor().opacity(0.9))
//        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
        .overlay(
            Text("\((Calendar.current.dateComponents([.day], from: scheduleStartDate, to: scheduleEndDate).day ?? 0)+1)")
                .bold()
                .padding(15)
                .foregroundStyle(.secondary)
            ,alignment: .topTrailing
        )
    }
    
    @ViewBuilder
    private func microScheduleItemView() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading) {
                ForEach(checkMatchedScheduleItem(), id: \.id) { scheItem in
                    HStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(scheItem.color.toColor())
                            .frame(width: 23, height: 13)
                        
                        Text("[\(scheItem.startDate.dayForDetail) ~ \(scheItem.endDate.dayForDetail)]:")
                            .frame(width: 110, alignment: .leading)
                        
                        Text("\(scheItem.content) (\((Calendar.current.dateComponents([.day], from: scheItem.startDate, to: scheItem.endDate).day ?? 0)+1) days)")
                    }
                    .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay (
            Button(action: {
                copySchedultItem()
                withAnimation(.spring) {
                    animationItem.content = "Copy Successfully"
                    animationItem.isSuccess = true
                    animationItem.isAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        animationItem.isAnimation = false
                    }
                }
                print("Copy Finished")
            }) {
                Image(systemName: "rectangle.fill.on.rectangle.fill")
                    .foregroundStyle(.secondary)
            }.buttonStyle(.plain)
                .keyboardShortcut("c", modifiers: [.command])
            ,alignment: .bottomTrailing
        )
        .padding(10)
        .frame(height: 130)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func cardBackgroundColor(dateItem: DateInfo) -> Color {
        if Date().dayForDetail == dateItem.date.dayForDetail { return .orange }
        if dateItem.id == selectedDateID { return .blue }
        
        if dateItem.date.dayForWeek == "Sat" || dateItem.date.dayForWeek == "Sun" { return .gray.opacity(0.1) }
        
        return Color.gray.opacity(0.3)
    }
    
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
    
    private func checkDateInSchedule(dateItem: DateInfo) -> [ScheduleItem] {
        return scheduleItemList.filter({
            dateItem.date.dayForNumber <= $0.endDateNum &&
            dateItem.date.dayForNumber >= $0.startDateNum
        })
    }
    
    private func checkMatchedScheduleItem() -> [ScheduleItem] {
        scheduleItemList
            .filter({ $0.endDate.dayForNumber >= Date().dayForNumber })
            .sorted(by: { $0.startDateNum <= $1.startDateNum })
    }
    
    private func copySchedultItem() {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        
        var content = ""
        let sortedScheduleItemList = scheduleItemList.sorted(by: { $0.startDateNum <= $1.startDateNum })
        for itemInfo in sortedScheduleItemList {
            content += "[\(itemInfo.startDateNum) ~ \(itemInfo.endDateNum)]: \(itemInfo.content)"
            content += " (\((Calendar.current.dateComponents([.day], from: itemInfo.startDate, to: itemInfo.endDate).day ?? 0)+1) days)\n"
        }
        
        pasteBoard.setString(content, forType: .string)
    }
}

#Preview {
    Home()
        .modelContainer(for: Item.self, inMemory: true)
}
