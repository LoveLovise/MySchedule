//
//  AppDelegate.swift
//  MySchedule
//
//  Created by Aaron on 8/18/25.
//

import SwiftUI
import Combine
import SwiftData

// MARK: - 应用委托
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarManager: StatusBarManager?
    let scheduleManager = ScheduleManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarManager = StatusBarManager(manager: scheduleManager)
    }
}

// MARK: - 日程管理器
class ScheduleManager: ObservableObject {
    @Published var items: [Item] = [] {
        didSet {
            NotificationCenter.default.post(name: .schedulesUpdated, object: nil)
        }
    }
    
    // 不再使用 @Environment，改为从外部传入 context
    // @Environment(\.modelContext) private var modelContext
    weak var modelContext: ModelContext?
    
    @Published var currentIndex: Int = 0
    private var timer: AnyCancellable? //Timer?
    
    func addItem(item: Item) {
        items.append(item)
        modelContext?.insert(item)
        
        do {
            try modelContext?.save()
            print("成功保存项目: \(item.title)")
        } catch {
            print("保存失败: \(error)")
        }
        
        if timer == nil && items.count > 1 {
            startRotation()
        }
    }
    
    func startRotation() {
        timer?.cancel()
        guard items.count > 1 else { return }
        
        timer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    withAnimation {
                        self.currentIndex = (self.currentIndex + 1) % self.items.count
                        print("切换到索引: \(self.currentIndex)")
                    }
                }
            }
    }
    
    func stopRotation() {
        timer?.cancel()
        timer = nil
    }
    
    // 从 SwiftData 加载数据
    func fetchItems(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // 简化查询，避免使用可能导致崩溃的谓词
        let descriptor = FetchDescriptor<Item>(
//            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let fetchedItems = try modelContext.fetch(descriptor)
            print("从数据库加载了 \(fetchedItems.count) 个项目")
            
            // 手动过滤已删除的项目
            items = fetchedItems.filter { !$0.isRemoved }
            
            if items.count > 1 {
                startRotation()
            }
        } catch {
            print("加载数据失败: \(error.localizedDescription)")
            items = []
        }
    }
    
    // 标记项目为已完成
    func markAsFinished(_ item: Item) {
        item.isFinished = true
        item.modifyDate = Date()
        do {
            try modelContext?.save()
            NotificationCenter.default.post(name: .schedulesUpdated, object: nil)
        } catch {
            print("标记完成失败: \(error.localizedDescription)")
        }
    }
    
    // 删除项目（软删除）
    func removeItem(_ item: Item) {
        item.isRemoved = true
        item.modifyDate = Date()
        do {
            try modelContext?.save()
            // 从当前列表中移除
            items.removeAll { $0.id == item.id }
            NotificationCenter.default.post(name: .schedulesUpdated, object: nil)
        } catch {
            print("删除项目失败: \(error.localizedDescription)")
        }
    }
}

extension Notification.Name {
    static let schedulesUpdated = Notification.Name("SchedulesUpdated")
}

// MARK: - 事件监听器
class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void
    
    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }
    
    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

// MARK: - 状态栏管理器
class StatusBarManager: NSObject {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var eventMonitor: EventMonitor?
    private var cancellables = Set<AnyCancellable>()
    
    private let scheduleManager: ScheduleManager
    
    init(manager: ScheduleManager) {
        self.scheduleManager = manager
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        
        super.init()
        
        setupStatusItem()
        setupPopover()
        setupObservers()
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown], handler: { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover()
            }
        })
    }
    
    private func setupStatusItem() {
        guard let button = statusItem.button else { return }
        updateStatusItem()
        button.action = #selector(togglePopover)
        button.target = self
    }
    
    private func updateStatusItem() {
        guard let button = statusItem.button else { return }
        
        let attributedString: NSMutableAttributedString
        var fontSize: CGFloat = 11
        
        if scheduleManager.items.isEmpty {
            button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "MySchedule")
            attributedString = NSMutableAttributedString(string: "无日程")
            fontSize = 11
        } else {
            fontSize = 9
            button.image = NSImage(systemSymbolName: "calendar.badge.plus", accessibilityDescription: "MySchedule")
            let index = scheduleManager.currentIndex
            let item = scheduleManager.items[index]
            
            let contentText: String
            if item.title.isEmpty && item.content.isEmpty {
                contentText = "空日程"
            } else if item.title.isEmpty {
                contentText = item.content
            } else if item.content.isEmpty {
                contentText = item.title
            } else {
                contentText = "\(item.title)\n\(item.content)"
            }
            attributedString = NSMutableAttributedString(string: contentText)
        }
        
        // 设置字体属性
        attributedString
            .addAttribute(
                .font,
                value: NSFont.systemFont(ofSize: fontSize),
                range: NSRange(location: 0, length: attributedString.length)
            )
        button.attributedTitle = attributedString
        button.imagePosition = .imageLeft
    }
    
    private func setupPopover() {
        popover.contentSize = NSSize(width: 300, height: 150)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: StatusBarPopoverView().environmentObject(scheduleManager)
        )
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: .schedulesUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItem()
            }
            .store(in: &cancellables)
        
        // 监听定时器索引变化
        scheduleManager.$currentIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItem()
            }
            .store(in: &cancellables)
    }
    
    @objc func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        eventMonitor?.start()
        
        if scheduleManager.items.count > 1 {
            scheduleManager.startRotation()
        }
    }
    
    func closePopover() {
        popover.performClose(nil)
        eventMonitor?.stop()
        scheduleManager.stopRotation()
    }
}

struct StatusBarPopoverView_Old: View {
    @EnvironmentObject var manager: ScheduleManager
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var title = ""
    @State private var content = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 添加新日程的表单
            VStack(alignment: .leading, spacing: 8) {
                Text("添加新日程")
                    .font(.headline)
                
                TextField("标题", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("内容", text: $content)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
//                Button(action: addNewSchedule) {
//                    Text("添加")
//                        .frame(maxWidth: .infinity)
//                }
//                .disabled(newTitle.isEmpty)
                Button("添加") {
                    let newItem = Item()
                    newItem.title = title
                    newItem.content = content
                    modelContext.insert(newItem)
                    manager.addItem(item: newItem)
                    title = ""
                    content = ""
                }
                .disabled(title.isEmpty && content.isEmpty)
            }
            
            Divider()
            
            Text("当前日程")
                .font(.headline)
            
            // 日程显示区域
            if manager.items.isEmpty {
                VStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    Text("没有日程安排")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let currentItem = manager.items[manager.currentIndex]
                VStack(alignment: .leading, spacing: 12) {
                    if !currentItem.title.isEmpty {
                        Text(currentItem.title)
                            .fontWeight(.bold)
                    }
                    
                    if !currentItem.content.isEmpty {
                        Text(currentItem.content)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            // 确保 ScheduleManager 有 modelContext
            if manager.modelContext == nil {
                manager.modelContext = modelContext
                manager.fetchItems(modelContext: modelContext)
            }
            manager.fetchItems(modelContext: modelContext)
            
            print(items.count)
        }
    }
}

// MARK: - 状态栏弹出视图
struct StatusBarPopoverView: View {
    @EnvironmentObject var scheduleManager: ScheduleManager
    @Environment(\.modelContext) private var modelContext
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var isTask: Bool = true
    @State private var showAllItems: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("添加新日程")
                .font(.headline)
            
            TextField("标题", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("内容", text: $content)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Toggle("是任务", isOn: $isTask)
            
            Button("添加") {
                let newItem = Item()
                newItem.title = title
                newItem.content = content
                newItem.isTask = isTask
//                newItem.lineCount = content.split(separator: "\n").count
                scheduleManager.addItem(item: newItem)
//                  scheduleManager.additem(item: newItem)
                title = ""
                content = ""
            }
            .disabled(title.isEmpty && content.isEmpty)
            
            Divider()
            
            if scheduleManager.items.isEmpty {
                Text("无日程")
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("当前日程 (\(scheduleManager.currentIndex + 1)/\(scheduleManager.items.count))")
                            .font(.headline)
                        
                        Spacer()
                        
                        Toggle("显示全部", isOn: $showAllItems)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                    
                    if showAllItems {
                        List {
                            ForEach(scheduleManager.items, id: \.id) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        if !item.title.isEmpty {
                                            Text(item.title)
                                                .fontWeight(.bold)
                                                .strikethrough(item.isFinished)
                                        }
                                        Spacer()
                                        if item.isFinished {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    
                                    if !item.content.isEmpty {
                                        Text(item.content)
                                            .strikethrough(item.isFinished)
                                            .font(.caption)
                                    }
                                    
                                    Text("创建于: \(item.date, formatter: dateFormatter)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Button(item.isFinished ? "标记未完成" : "标记完成") {
                                            if item.isFinished {
                                                item.isFinished = false
                                            } else {
                                                scheduleManager.markAsFinished(item)
                                            }
                                        }
                                        .buttonStyle(.borderless)
                                        .controlSize(.small)
                                        
                                        Button("删除") {
                                            scheduleManager.removeItem(item)
                                        }
                                        .buttonStyle(.borderless)
                                        .controlSize(.small)
                                        .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .frame(height: 150)
                    } else {
                        let currentItem = scheduleManager.items[scheduleManager.currentIndex]
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                if !currentItem.title.isEmpty {
                                    Text(currentItem.title)
                                        .fontWeight(.bold)
                                        .strikethrough(currentItem.isFinished)
                                }
                                Spacer()
                                if currentItem.isFinished {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            
                            if !currentItem.content.isEmpty {
                                Text(currentItem.content)
                                    .strikethrough(currentItem.isFinished)
                                    .font(.caption)
                            }
                            
                            Text("创建于: \(currentItem.date, formatter: dateFormatter)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Button(currentItem.isFinished ? "标记未完成" : "标记完成") {
                                    if currentItem.isFinished {
                                        currentItem.isFinished = false
                                    } else {
                                        scheduleManager.markAsFinished(currentItem)
                                    }
                                }
                                .buttonStyle(.borderless)
                                .controlSize(.small)
                                
                                Button("删除") {
                                    scheduleManager.removeItem(currentItem)
                                }
                                .buttonStyle(.borderless)
                                .controlSize(.small)
                                .foregroundColor(.red)
                            }
                        }
                        
                        if scheduleManager.items.count > 1 {
                            Divider()
                            HStack {
                                Button("上一个") {
                                    withAnimation {
                                        scheduleManager.currentIndex = (scheduleManager.currentIndex - 1 + scheduleManager.items.count) % scheduleManager.items.count
                                    }
                                }
                                .disabled(scheduleManager.items.count <= 1)
                                
                                Button("下一个") {
                                    withAnimation {
                                        scheduleManager.currentIndex = (scheduleManager.currentIndex + 1) % scheduleManager.items.count
                                    }
                                }
                                .disabled(scheduleManager.items.count <= 1)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear {
            // 确保 ScheduleManager 有 modelContext
            if scheduleManager.modelContext == nil {
                scheduleManager.modelContext = modelContext
                scheduleManager.fetchItems(modelContext: modelContext)
            } else {
                // 每次打开弹窗都重新获取数据，确保数据最新
                scheduleManager.fetchItems(modelContext: modelContext)
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}
