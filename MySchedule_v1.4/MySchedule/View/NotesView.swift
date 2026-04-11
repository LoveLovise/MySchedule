//
//  NotesView.swift
//  MySchedule
//
//  Created by Aaron on 8/1/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var matchedItems: [Item] = []
    @State private var removedItems: [Item] = []
    @State private var currentItem: Item = .init()
    @State private var isEditMode: Bool = false
    @State private var isShowAddNoteSheet: Bool = false
    @State private var searchContent: String = ""
    @State private var isAllowSetSystemAlert: Bool = false
    @State private var filterItem: FilterItem = .init()
    @State private var isShowFilterView: Bool = false
    @State private var animationItem: AnimationItem = .init()
    @AppStorage("MyScheduleCOLORSCHEME") var colorScheme: String = ""
    @Environment(\.openURL) var openURL
    var body: some View {
        VStack {
            if matchedItems.isEmpty {
                Text("Pending Add Now ...")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                SearchView()
                
                if isShowFilterView {
                    FilterView()
                }
                
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack {
                        ForEach(sortMatchItems(), id: \.id) { item in
                            NotesCardView(item: item)
                                .onHover(perform: { isHovering in
                                    if isShowAddNoteSheet { return }
                                    if isHovering {
                                        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
                                        currentItem = items[index]
                                    } else {
                                        currentItem = .init()
                                    }
                                })
                        }
                    }
                }
            }
        }
        .overlay(
            Text("Check point is invalid, because user do not allow set notification...")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
                .opacity(isAllowSetSystemAlert ? 0 : 1)
            ,alignment: .bottom
        )
        .overlay (
            Button(action: {
                /// New add
                currentItem = .init()
                /// New add Check point is after 30min
                currentItem.checkPoint = Calendar.current.date(byAdding: .minute, value: 30, to: .init())!
                isShowAddNoteSheet.toggle()
                isEditMode = false
            }) {
                Image(systemName: "plus.square.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(2)
                    .background(Color.green)
                    .cornerRadius(8)
            }
                .keyboardShortcut("n", modifiers: [.command])
            ,alignment: .bottomTrailing
        )
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
        .padding(10)
        .buttonStyle(.plain)
        .onChange(of: currentItem, { oldValue, newValue in
            if !isEditMode { return }
            currentItem.isModified = true
            currentItem.modifyDate = .init()
        })
        .sheet(isPresented: $isShowAddNoteSheet) {
            NoteSheetView()
        }
        .onAppear {
            matchedItems = items.filter({ !$0.isRemoved })
            
            requestNotificationAuthorization()
            
            removedItems = items.filter({ $0.isRemoved })
        }
    }
    
    @ViewBuilder
    private func SearchView() -> some View {
        HStack {
            HStack(spacing: 3) {
                Image(systemName: "magnifyingglass.circle.fill")
                
                Divider()
                    .frame(height: 15)
                
                TextField("Try to search content...", text: $searchContent, onCommit: {
                    
                })
                .foregroundStyle(.blue)
                
                Button(action: {
                    searchContent = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .opacity(searchContent.isEmpty ? 0 : 1)
            }
            .textFieldStyle(.plain)
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            
            Button(action: {
                withAnimation(.spring) {
                    isShowFilterView.toggle()
                    if !isShowFilterView {
                        filterItem = .init()
                    }
                }
            }) {
                Image(systemName: isShowFilterView ? "chevron.down" : "chevron.left")
                    .frame(width: 30, height: 30)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(5)
            }
        }
    }
    
    @ViewBuilder
    private func FilterView() -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                /// By Date
                HStack(spacing: 5) {
                    Button(action: {
                        filterItem.isByDate.toggle()
                    }) {
                        Image(systemName: filterItem.isByDate ? "checkmark.square.fill" : "square")
                            .foregroundStyle(filterItem.isByDate ? .blue : .primary)
                    }
                    DatePicker("", selection: $filterItem.startDate)
                        .disabled(!filterItem.isByDate)
                    Text("~")
                        .foregroundStyle(filterItem.isByDate ? .primary : .secondary)
                    DatePicker("", selection: $filterItem.endDate)
                        .disabled(!filterItem.isByDate)
                }
                .labelsHidden()
                .datePickerStyle(.field)
                .frame(width: 310, height: 35)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                
                Button(action: {
                    searchContent = ""
                    filterItem.isRemoved.toggle()
                }) {
                    Text("Remove")
                        .foregroundStyle(filterItem.isRemoved ? .primary : .secondary)
                        .padding(10)
                        .background(
                            filterItem.isRemoved ? Color.blue : Color.secondary.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .overlay (
                            Text("\(removedItems.count)")
                                .font(.system(size: 8))
                                .padding(3)
                            ,alignment: .topTrailing
                        )
                }
            }
            
            HStack(spacing: 10) {
                /// By TOP
                Button(action: {
                    filterItem.isByTop.toggle()
                    filterItem.isByFinished = false
                    if filterItem.isByUnFinished { return }
                    filterItem.isEnableUnAndFinished = false
                }) {
                    Text("TOP")
                        .foregroundStyle(filterItem.isByTop ? .primary : .secondary)
                        .padding(10)
                        .background(
                            filterItem.isByTop ? Color.blue : Color.secondary.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .overlay(
                            Text("\(matchedItems.filter({ $0.isTop } ).count)")
                                .font(.system(size: 8))
                                .padding(3)
                            ,alignment: .topTrailing
                        )
                }
                
                /// Task And Note
                HStack(spacing: 2) {
                    Button(action: {
                        filterItem.isEnableChooseNoteAndTask.toggle()
                        if !filterItem.isEnableChooseNoteAndTask {
                            filterItem.isByTask = false
                            filterItem.isByNote = false
                        } else {
                            filterItem.isByTask = true
                        }
                    }) {
                        Image(systemName: filterItem.isEnableChooseNoteAndTask ? "checkmark.square.fill" : "square")
                            .foregroundStyle(filterItem.isEnableChooseNoteAndTask ? .blue : .primary)
                    }
                    .padding(.trailing, 5)
                    
                    Button(action: {
                        filterItem.isEnableChooseNoteAndTask = true
                        filterItem.isByTask = true
                        filterItem.isByNote = false
                    }) {
                        Text("Task")
                            .padding(8)
                            .foregroundStyle(filterItem.isByTask ? .primary : .secondary)
                            .background(
                                filterItem.isByTask ? Color.blue : Color.secondary.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay(
                                Text("\(matchedItems.filter({ $0.isTask } ).count)")
                                    .font(.system(size: 8))
                                    .padding(3)
                                ,alignment: .topTrailing
                            )
                    }
                    Divider()
                        .frame(height: 18)
                    Button(action: {
                        filterItem.isEnableChooseNoteAndTask = true
                        filterItem.isByNote = true
                        filterItem.isByTask = false
                        filterItem.isByFinished = false
                        filterItem.isByUnFinished = false
                        filterItem.isEnableUnAndFinished = false
                    }) {
                        Text("Note")
                            .padding(8)
                            .foregroundStyle(filterItem.isByNote ? .primary : .secondary)
                            .background(
                                filterItem.isByNote ? Color.blue : Color.secondary.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay(
                                Text("\(matchedItems.filter({ !$0.isTask } ).count)")
                                    .font(.system(size: 8))
                                    .padding(3)
                                ,alignment: .topTrailing
                            )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                
                /// By UnFinished And Finished
                HStack(spacing: 2) {
                    Button(action: {
                        filterItem.isEnableUnAndFinished.toggle()
                        if !filterItem.isEnableUnAndFinished {
                            filterItem.isByFinished = false
                            filterItem.isByUnFinished = false
                        } else {
                            filterItem.isByUnFinished = true
                        }
                    }) {
                        Image(systemName: filterItem.isEnableUnAndFinished ? "checkmark.square.fill" : "square")
                            .foregroundStyle(filterItem.isEnableUnAndFinished ? .blue : .primary)
                    }
                    .padding(.trailing, 5)
                    .disabled(filterItem.isByNote)
                    
                    Button(action: {
                        filterItem.isEnableUnAndFinished = true
                        filterItem.isByUnFinished = true
                        filterItem.isByFinished = false
                    }) {
                        Text("Undone")
                            .padding(8)
                            .foregroundStyle(filterItem.isByUnFinished ? .primary : .secondary)
                            .background(
                                filterItem.isByUnFinished ? Color.blue : Color.secondary.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay(
                                Text("\(matchedItems.filter({ !$0.isFinished } ).count)")
                                    .font(.system(size: 8))
                                    .padding(3)
                                ,alignment: .topTrailing
                            )
                    }
                    .disabled(filterItem.isByNote)
                    
                    Divider()
                        .frame(height: 18)
                    
                    Button(action: {
                        filterItem.isEnableUnAndFinished = true
                        filterItem.isByUnFinished = false
                        filterItem.isByFinished = true
                    }) {
                        Text("Finish")
                            .padding(8)
                            .foregroundStyle(filterItem.isByFinished ? .primary : .secondary)
                            .background(
                                filterItem.isByFinished ? Color.blue : Color.secondary.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay(
                                Text("\(matchedItems.filter({ $0.isFinished } ).count)")
                                    .font(.system(size: 8))
                                    .padding(3)
                                ,alignment: .topTrailing
                            )
                    }
                    .disabled(filterItem.isByTop || filterItem.isByNote)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(width: 400)
    }
    
    @ViewBuilder
    private func NotesCardView(item: Item) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 3) {
                Text("Create: \(item.date.dayForAll)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Spacer()
                if item.isTask {
                    Text("CP: ")
                        .font(.system(size: 20))
                        .bold()
                        .foregroundStyle(item.isDailyTracking ? .orange : .primary)
                        .overlay(
                            Text("daily")
                                .font(.system(size: 5))
                                .foregroundStyle(item.isDailyTracking ? .orange : .clear)
                            ,alignment: .topTrailing
                        )
                    
                    Text("\(item.isDailyTracking ? item.correctCheckPoint.dayForAll : item.checkPoint.dayForAll)")
                        .foregroundColor(isAllowSetSystemAlert ? .blue : .secondary)
                        .padding(.trailing, 10)
                }
                                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
                    .opacity(item.isFinished && item.isTask ? 1 : 0)
                
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.yellow)
                    .rotationEffect(.degrees(20))
                    .opacity(item.isTop ? 1 : 0)
            }
            
            if !item.title.isEmpty {
                Text("- \(item.title)")
                    .font(.title2)
                    .bold()
            }
            
            Text("\(item.content)")
                .font(.system(size: 15))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(item.isShowMore ? nil : 4)
                .padding(.leading, 20)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: LineCountPreferenceKey.self, value: Int(proxy.size.height / 18))
                    }
                )
                .onPreferenceChange(LineCountPreferenceKey.self) { count in
                    item.lineCount = count
                }
                .overlay(
                    Button(action: {
                        withAnimation(.spring) { item.isShowMore.toggle() }
                    }) {
                        VStack(spacing: 1) {
                            if item.isShowMore {
                                Image(systemName: "chevron.compact.up")
                                    .font(.system(size: 10))
                            }
                            Image(systemName: "circle.fill")
                                .font(.system(size: 3))
                            Image(systemName: "circle.fill")
                                .font(.system(size: 3))
                            if !item.isShowMore {
                                Image(systemName: "chevron.compact.down")
                                    .font(.system(size: 10))
                            }
                        }
                        .padding(5)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(5)
                    }.opacity(item.lineCount > 3 ? 1 : 0)
                    ,alignment: .bottomTrailing
                )
            if !item.contentLinkList.isEmpty {
                Divider()
                ContentLinkView(item: item)
            }
        }
        .strikethrough(item.isFinished && item.isTask ,color: .secondary)
        .overlay (
            HStack {
                if filterItem.isRemoved {
                    Button(action: {
                        guard let index = removedItems.firstIndex(where: { $0.id == item.id }) else { return }
                        removedItems.remove(at: index)
                        item.isRemoved = false
                        matchedItems.append(item)
                    }) {
                        Image(systemName: "arrow.trianglehead.2.counterclockwise")
                            .font(.system(size: 15))
                            .padding(10)
                            .foregroundStyle(.green)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                    }
                } else {
                    Button(action: {
                        guard let index = matchedItems.firstIndex(where: { $0.id == item.id }) else { return }
                        currentItem = matchedItems[index]
                        isEditMode = true
                        isShowAddNoteSheet.toggle()
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 15))
                            .padding(10)
                            .foregroundStyle(.orange)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                
                Button(action: {
                    print("Here ...")
                    removeNotificationForDate(item: item)
                    // 彻底删除
                    if filterItem.isRemoved {
                        guard let indexRem = removedItems.firstIndex(where: { $0.id == item.id }) else { return }
                        removedItems.remove(at: indexRem)
                        modelContext.delete(item)
                        return
                    }
                    // 标记删除
                    print("Remove Item...")
                    guard let index = matchedItems.firstIndex(where: { $0.id == item.id }) else { return }
                    matchedItems.remove(at: index)
                    removedItems.append(item)
                    item.isRemoved = true
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 15))
                        .padding(10)
                        .foregroundStyle(.red)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                }
                
                if !item.isFinished && !filterItem.isRemoved {
                    Button(action: {
                        withAnimation(.spring) { withAnimation(.spring) { item.isTop.toggle() } }
                    }) {
                        Image(systemName: item.isTop ? "pin.fill" : "pin")
                            .font(.system(size: 15))
                            .rotationEffect(.degrees(item.isTop ? 30 : 0))
                            .foregroundStyle(item.isTop ? .yellow : .white)
                            .padding(10)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
            }
                .opacity(currentItem.id == item.id ? 1 : 0)
            ,alignment: .trailing
        )
        .overlay(
            Button(action: {
                copySchedultItem(item: item)
                withAnimation(.spring) {
                    animationItem.content = "Copy Successfully"
                    animationItem.isSuccess = true
                    animationItem.isAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        animationItem.isAnimation = false
                    }
                }
            }) {
                Image(systemName: "rectangle.fill.on.rectangle.fill")
                    .resizable()
                    .frame(width: 15, height: 12)
                    .foregroundColor(Color.indigo)
            }
                .opacity(currentItem.id == item.id ? 1 : 0)
            ,alignment: .bottomLeading
        )
        .containerShape(Rectangle())
        .padding(10)
        .background(Color.secondary.opacity(0.1))
        .compositingGroup()
        .shadow(color: .secondary.opacity((colorScheme == "dark") ? 0 : 0.7), radius: 3, x: 3, y: 3)
        .shadow(color: .white.opacity((colorScheme == "dark") ? 0 : 0.7), radius: 3, x: -3, y: -3)
        .cornerRadius(10)        
    }
    
    @ViewBuilder
    private func NoteSheetView() -> some View {
        VStack(spacing: 15) {
            HStack(alignment: .top) {
                
                Text("\(currentItem.date.dayForAll)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if isEditMode {
                    Button(action: {
                        guard let index = matchedItems.firstIndex(where: { $0.id == currentItem.id }) else { return }
                        matchedItems[index].isRemoved = true
                        isShowAddNoteSheet.toggle()
                        matchedItems.remove(at: index)
                        removeNotificationForDate(item: currentItem)
                    }) {
                        VStack {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18))
                            Text("Delete")
                                .font(.system(size: 5))
                        }
                        .foregroundColor(.red)
                    }
                }
                
                if currentItem.isTask {
                    Button(action: {
                        currentItem.isFinished.toggle()
                        currentItem.checkPoint = .init()
                        currentItem.isTop = false
                        removeNotificationForDate(item: currentItem)
                    }) {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                            Text("Finished")
                                .font(.system(size: 5))
                        }
                        .foregroundColor(currentItem.isFinished ? .green : .primary)
                    }
                }
                
                Button(action: {
                    withAnimation(.spring) { currentItem.isTop.toggle() }
                }) {
                    VStack {
                        Image(systemName: currentItem.isTop ? "pin.fill" : "pin")
                            .font(.system(size: 18))
                            .rotationEffect(.degrees(currentItem.isTop ? 20 : 0))
                        Text("SetTop")
                            .font(.system(size: 5))
                    }
                    .foregroundColor(
                        currentItem.isFinished ? .secondary.opacity(0.5) : (currentItem.isTop ? .orange : .primary)
                    )
                }
                .disabled(currentItem.isFinished)
            }
            .padding(.bottom, 15)
            
            HStack(alignment: .bottom) {
                HStack(spacing: 3) {
                    Button(action: { currentItem.isTask = true }) {
                        if currentItem.isTask {
                            Text("Task")
                                .bold()
                                .foregroundStyle(.orange)
                        } else {
                            Text("Task")
                        }
                    }
                    .frame(width: 35)
                    
                    Text("/")
                    
                    Button(action: {
                        currentItem.isTask = false;
                        removeNotificationForDate(item: currentItem)
                    }) {
                        if currentItem.isTask {
                            Text("Note")
                        } else {
                            Text("Note")
                                .bold()
                                .foregroundStyle(.blue)
                        }
                    }.frame(width: 35)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if currentItem.isTask {
                    Text("CP:")
                        .font(.title)
                        .bold()
                        .foregroundStyle(currentItem.isDailyTracking ? .orange : .primary)
                        .overlay(
                            Text("daily")
                                .font(.system(size: 5))
                                .foregroundStyle(currentItem.isDailyTracking ? .orange : .clear)
                            ,alignment: .topTrailing
                        )
                        .onTapGesture {
                            currentItem.isDailyTracking.toggle()
                            if !currentItem.isDailyTracking {
                                removeNotificationForDate(item: currentItem)
                            }
                        }
                    
                    DatePicker(
                        "",
                        selection: $currentItem.checkPoint,
                        in: currentItem.checkPoint...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                        .labelsHidden()
                        .datePickerStyle(.field)
                        .background(Color.clear)
                        .textFieldStyle(.plain)
                }
            }
            .frame(height: 30, alignment: .bottom)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Title:")
                    .bold()
                TextField("Title", text: $currentItem.title)
                    .textFieldStyle(.plain)
                    .padding(7)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    Text("Content:")
                        .bold()
                    Image(systemName: "star.fill")
                        .foregroundStyle(.red)
                        .font(.system(size: 5))
                        .opacity(currentItem.title.isEmpty ? 1 : 0)
                }
                TextEditor(text: $currentItem.content)
                    .scrollContentBackground(.hidden)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 5)
                    .frame(minHeight: 100, maxHeight: 500)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
            }
            
            HStack(spacing: 20) {
                // Remove 'cancel' btn, because item is a object, if it's changed, cannot cancel to orginal data
                // so remove it, only keep confirm btn.
//                Button(action: {
//                    isShowAddNoteSheet.toggle()
//                    currentItem = .init()
//                }) {
//                    Text("Cancel")
//                        .frame(width: 85, height: 35)
//                        .background(Color.yellow, in: .capsule)
//                }
                
                Button(action: {
                    isShowAddNoteSheet.toggle()
                    currentItem.contentLinkList = getLinkFromContent(content: "\(currentItem.title)\t\(currentItem.content)")
//                    print(currentItem.contentLinkList)
                    if isEditMode {
                        guard let index = matchedItems.firstIndex(where: { $0.id == currentItem.id }) else { return }
                        matchedItems[index] = currentItem
                    } else {
                        modelContext.insert(currentItem)
                        matchedItems.append(currentItem)
                    }
                    
                    if currentItem.isTask && isAllowSetSystemAlert {
                        scheduleNotificationForDate(item: currentItem, advanceMinutes: 5)
                        scheduleNotificationForDate(item: currentItem, advanceMinutes: 0)
                    }
                    
                    currentItem = .init()
                }) {
                    Text("Confirm")
                        .frame(maxWidth: .infinity)
                        .frame(height: 35)
                        .background(Color.green, in: .capsule)
                }.keyboardShortcut("s", modifiers: [.command])
                    .disabled(currentItem.content.isEmpty && currentItem.title.isEmpty)
            }
            .padding(.top, 15)
            .buttonStyle(.plain)
        }
        .padding()
        .frame(width: 380, height: 410)
    }
    
    @ViewBuilder
    private func ContentLinkView(item: Item) -> some View {
            LazyHGrid(rows: [GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(item.contentLinkList, id: \.self) { contentLink in
                Button(action: {
                    NSWorkspace.shared.open(contentLink)
                }) {
                    Text(contentLink.absoluteString)
                        .padding(8)
                        .foregroundStyle(.blue)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                        .frame(maxWidth: 150)
                }
            }
        }
    }
    
    private func sortMatchItems() -> [Item] {
        // 置顶状态: 不可以是完成的 (删除的已经被默认排除了)
//        if filterItem.isByTop {
//            filterItem.isByFinished = false
//        }
//        // 完成状态, 不可以是 TOP, Note,未完成
//        if filterItem.isByFinished {
//            filterItem.isByTop = false
//            filterItem.isByNote = false
//            filterItem.isByUnFinished = false
//        }
//        // 未完成状态, 不可以是 Note, 完成
//        if filterItem.isByUnFinished {
//            filterItem.isByNote = false
//            filterItem.isByFinished = false
//        }
//        // 移除的状态: 除了 remove, 其他的是 false
//        if filterItem.isRemoved {
//            filterItem = FilterItem.initStatus
//            filterItem.isRemoved = true
//        }
//        // 如果是 Task, 则不可以是 Note
//        if filterItem.isByTask {
//            filterItem.isByNote = false
//        }
//        // 如果是 Note, 则不可以是 Task
//        if filterItem.isByNote {
//            filterItem.isByTask = false
//        }
        
        var demoItemList = filterItem.isRemoved ? removedItems : (filterItem.isByFinished ?
                                                                  matchedItems.filter({ $0.isFinished }) :
                                                                  matchedItems.filter({ !$0.isFinished }))
        
        if filterItem.isByDate {
            demoItemList = demoItemList.filter({ $0.date >= filterItem.startDate && $0.date <= filterItem.endDate })
        }
        
        if filterItem.isByFinished {
            demoItemList = demoItemList.filter({ $0.isFinished })
        }
        
        if filterItem.isByUnFinished {
            demoItemList = demoItemList.filter({ !$0.isFinished })
        }
        
        if filterItem.isByTop {
            demoItemList = demoItemList.filter({ $0.isTop })
        }
        
        if filterItem.isByTask {
            demoItemList = demoItemList.filter({ $0.isTask })
        }
        
        if filterItem.isByNote {
            demoItemList = demoItemList.filter({ !$0.isTask })
        }
        
        return demoItemList.sorted{
//            return $0.date > $1.date
            // 第一优先级: 置顶的排在前面
            if $0.isTop != $1.isTop {
                return $0.isTop && !$1.isTop
            // 第三优先级: 未完成的排在前
            } else if $0.isFinished != $1.isFinished {
                return !$0.isFinished && $1.isFinished
            // 第二优先级: 日期最新的排在最前面
            } else  {
                return true
            }
        }.filter({
            if searchContent.isEmpty { return true }
            return $0.description.lowercased().contains(searchContent.lowercased())
        })

        /// 1. Create date
//        return matchedItems.sorted{
////            return $0.date > $1.date
//            // 第一优先级: 置顶的排在前面
//            if $0.isTop != $1.isTop {
//                return $0.isTop && !$1.isTop
//            // 第二优先级: 日期最新的排在最前面
//            } else if $0.date > $1.date {
//                return true
//            // 第三优先级: 未完成的排在前
//            } else {
//                return !$0.isFinished && $1.isFinished
//            }
//        }.filter({
//            if searchContent.isEmpty { return true }
//            return $0.description.lowercased().contains(searchContent.lowercased())
//        })
    }
    
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                isAllowSetSystemAlert = true
                print("通知权限已授权")
            } else {
                isAllowSetSystemAlert = false
                print("通知权限被拒绝")
            }
        }
    }
    
    private func scheduleNotificationForDate(item: Item, advanceMinutes: Int = 5) {
        let content = UNMutableNotificationContent()
        content.title = item.title
        content.body = (advanceMinutes == 0) ? "Meet check point for task: \n\(item.content)" : "After \(advanceMinutes) Minutes, will meet check point: \n\(item.content)"
        content.sound = .default
        
        // 获取提醒时间的小时和分钟
        let checkPointComponents = Calendar.current.dateComponents([.hour, .minute], from: item.checkPoint)
        
        // 计算提前的时间
        guard let eventDate = Calendar.current.date(bySettingHour: checkPointComponents.hour!,
                                                  minute: checkPointComponents.minute!,
                                                  second: 0,
                                                  of: Date()) else { return }
        
        guard let triggerDate = Calendar.current.date(byAdding: .minute, value: -advanceMinutes, to: eventDate) else {
            return
        }
        
        // 获取提前时间的小时和分钟
        let triggerComponents = Calendar.current.dateComponents([.hour, .minute], from: triggerDate)
        
        // 创建触发器
        let trigger: UNCalendarNotificationTrigger
        
        if item.isDailyTracking {
            // 对于每日重复，只设置小时和分钟
            var dailyComponents = DateComponents()
            dailyComponents.hour = triggerComponents.hour
            dailyComponents.minute = triggerComponents.minute
            dailyComponents.timeZone = TimeZone.current
            
            trigger = UNCalendarNotificationTrigger(dateMatching: dailyComponents, repeats: true)
        } else {
            // 对于单次通知，设置完整日期
            var specificComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            )
            specificComponents.timeZone = TimeZone.current
            trigger = UNCalendarNotificationTrigger(dateMatching: specificComponents, repeats: false)
        }
        
        // 创建通知请求
        let request = UNNotificationRequest(
            identifier: "task_reminder_\(item.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        // 添加到通知中心
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知添加失败: \(error.localizedDescription)")
            } else {
                print("Schedule Item Info: \(item.description), \nid is: \(item.id)")
                print("通知添加成功, 将在 \(triggerDate) 触发")
            }
        }
    }
    
    private func removeNotificationForDate(item: Item) {
        print("Notification Remove: \(item.description)\nid is: \(item.id)")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["task_reminder_\(item.id.uuidString)"])
    }
    
    private func copySchedultItem(item: Item) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        let content = "\(item.title)\n\(item.content)"
        pasteBoard.setString(content, forType: .string)
    }
    
    private func getLinkFromContent(content: String) -> [URL] {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(
            in: content,
            options: [],
            range: NSRange(location: 0, length: content.utf16.count)
        )
        return matches.compactMap({ $0.url })
    }
}

#Preview {
    NotesView()
//    Home()
}
