//
//  ContentView.swift
//  Deep Work
//
//  Created by japsa on 18.10.2024.
//

import SwiftUI

struct Session: Identifiable, Codable {
    let id = UUID()
    let duration: TimeInterval
    let tagName: String
    let date: Date
}

struct ContentView: View {
    @State private var selectedTab = 1 // Başlangıçta Focus tab'ını seçili yapar

    var body: some View {
        TabView(selection: $selectedTab) {
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
                .tag(0)
            
            FocusView()
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
    }
}

struct StatsView: View {
    @State private var sessions: [Session] = []

    var body: some View {
        NavigationView {
            List {
                ForEach(sessions) { session in
                    VStack(alignment: .leading) {
                        Text(session.tagName)
                            .font(.headline)
                        Text("Duration: \(formatDuration(session.duration))")
                        Text("Date: \(formatDate(session.date))")
                    }
                }
            }
            .navigationTitle("Stats")
            .onAppear(perform: loadSessions)
        }
    }

    func loadSessions() {
        if let savedSessions = UserDefaults.standard.data(forKey: "savedSessions"),
           let decodedSessions = try? JSONDecoder().decode([Session].self, from: savedSessions) {
            sessions = decodedSessions
        }
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct FocusView: View {
    @State private var focusDuration: Double = 0
    @State private var elapsedTime: TimeInterval = 0
    @State private var isTimerRunning = false
    @State private var showingTagSelection = false
    @State private var selectedTag: Tag?
    @State private var tags: [Tag] = [Tag(name: "Deep Work", emoji: "🎯", color: .blue)]
    @State private var isTimerMode = true
    @State private var timer: Timer?
    @State private var showSlider = true
    @State private var sessions: [Session] = []

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Picker("Mode", selection: $isTimerMode) {
                    Image(systemName: "timer").tag(true)
                    Image(systemName: "stopwatch").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 100)
                .onChange(of: isTimerMode) { _, _ in
                    resetTimer()
                }
            }
            .padding(.vertical,50)

            CircularSliderView(
                value: $focusDuration,
                inRange: 0...180,
                step: 5,
                sliderColor: selectedTag?.color ?? .blue,
                emoji: selectedTag?.emoji ?? "🎯",
                showSlider: showSlider && isTimerMode
            )
            .frame(width: 300, height: 300)

            Button(action: {
                showingTagSelection = true
            }) {
                HStack {
                    Text(selectedTag?.emoji ?? "🎯")
                        .font(.title2)
                    Text(selectedTag?.name ?? "Deep Work")
                        .foregroundColor(selectedTag?.color ?? .blue)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(100)
            }
            .padding()

            Text(timeString(from: isTimerMode ? Int(focusDuration * 60 - elapsedTime) : Int(elapsedTime)))
                .font(.title)
                .bold()

            HStack(spacing: 20) {
                Button(action: {
                    if isTimerRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    Text(isTimerRunning ? "Pause" : "Start")
                        .padding()
                        .background(selectedTag?.color ?? .blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                if isTimerRunning || elapsedTime > 0 {
                    Button(action: {
                        stopTimer()
                    }) {
                        Text("Stop")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingTagSelection) {
            SelectTagView(tags: $tags, selectedTag: $selectedTag)
        }
        .onAppear(perform: loadSessions)
    }

    func timeString(from seconds: Int) -> String {
        let minutes = abs(seconds) / 60
        let remainingSeconds = abs(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    func startTimer() {
        isTimerRunning = true
        showSlider = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if isTimerMode {
                if elapsedTime < focusDuration * 60 {
                    elapsedTime += 1
                } else {
                    stopTimer()
                }
            } else {
                elapsedTime += 1
            }
        }
    }

    func pauseTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }

    func stopTimer() {
        pauseTimer()
        if elapsedTime > 0 {
            let newSession = Session(duration: elapsedTime, tagName: selectedTag?.name ?? "Deep Work", date: Date())
            sessions.append(newSession)
            saveSessions()
        }
        elapsedTime = 0
        showSlider = true
    }

    func resetTimer() {
        stopTimer()
        focusDuration = 0
    }

    func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "savedSessions")
        }
    }

    func loadSessions() {
        if let savedSessions = UserDefaults.standard.data(forKey: "savedSessions"),
           let decodedSessions = try? JSONDecoder().decode([Session].self, from: savedSessions) {
            sessions = decodedSessions
        }
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings View")
    }
}

struct CircularSliderView: View {
    @Binding var value: Double
    let inRange: ClosedRange<Double>
    let step: Double
    let sliderColor: Color
    let emoji: String
    let showSlider: Bool

    private var progressFraction: Double {
        (value - inRange.lowerBound) / (inRange.upperBound - inRange.lowerBound)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                gestureArea(in: geometry)
                
                if showSlider {
                    sliderCircle()
                    progressArc()
                    sliderKnob(in: geometry)
                }
                
                Text(emoji)
                    .font(.system(size: 100))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func gestureArea(in geometry: GeometryProxy) -> some View {
        Circle()
            .fill(sliderColor.gradient.opacity(0.3))
            .frame(width: showSlider ? geometry.size.width - 20 : geometry.size.width,
                   height: showSlider ? geometry.size.height - 20 : geometry.size.height)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { dragValue in
                        if showSlider {
                            updateProgress(dragValue: dragValue, in: geometry.size)
                        }
                    }
            )
    }
    
    private func sliderCircle() -> some View {
        Circle()
            .stroke(sliderColor.opacity(0.3), lineWidth: 20)
    }
    
    private func progressArc() -> some View {
        Circle()
            .trim(from: 0, to: CGFloat(progressFraction))
            .stroke(sliderColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
            .rotationEffect(.degrees(-90))
    }
    
    private func sliderKnob(in geometry: GeometryProxy) -> some View {
        let radius = geometry.size.width / 2
        let angle = 2 * .pi * progressFraction - .pi / 2
        let xOffset = radius * cos(angle)
        let yOffset = radius * sin(angle)
        
        return Circle()
            .fill(sliderColor)
            .frame(width: 30, height: 30)
            .shadow(radius: 4)
            .offset(x: xOffset, y: yOffset)
    }

    private func updateProgress(dragValue: DragGesture.Value, in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let vector = CGVector(dx: dragValue.location.x - center.x, dy: dragValue.location.y - center.y)
        let angle = atan2(vector.dy, vector.dx)
        
        var newProgress = (angle + .pi / 2) / (2 * .pi)
        if newProgress < 0 {
            newProgress += 1
        }
        
        let steppedProgress = round((newProgress * (inRange.upperBound - inRange.lowerBound)) / step) * step + inRange.lowerBound
        value = min(max(steppedProgress, inRange.lowerBound), inRange.upperBound)
    }
}

struct SelectTagView: View {
    @Binding var tags: [Tag]
    @Binding var selectedTag: Tag?
    @State private var showingNewTagForm = false
    @State private var tagToEdit: Tag?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("New Tag")) {
                    Button(action: {
                        showingNewTagForm = true
                    }) {
                        Label("New Tag", systemImage: "plus")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                }

                Section(header: Text("Your Tags")) {
                    ForEach(tags) { tag in
                        Button(action: {
                            selectedTag = tag
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Text(tag.emoji)
                                Text(tag.name)
                                Spacer()
                                if selectedTag == tag {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .foregroundColor(tag.color)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteTag(tag)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                tagToEdit = tag
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Select Tag")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingNewTagForm) {
                NewTagView(tags: $tags)
            }
            .sheet(item: $tagToEdit) { tag in
                EditTagView(tags: $tags, tagToEdit: tag, selectedTag: $selectedTag)
            }
        }
    }
    
    func deleteTag(_ tag: Tag) {
        tags.removeAll { $0.id == tag.id }
        if selectedTag == tag {
            selectedTag = nil
        }
    }
}

struct EditTagView: View {
    @Binding var tags: [Tag]
    @Binding var selectedTag: Tag?
    let tagToEdit: Tag
    @State private var tagName: String
    @State private var tagEmoji: String
    @State private var tagColor: Color
    @Environment(\.presentationMode) var presentationMode

    init(tags: Binding<[Tag]>, tagToEdit: Tag, selectedTag: Binding<Tag?>) {
        self._tags = tags
        self._selectedTag = selectedTag
        self.tagToEdit = tagToEdit
        _tagName = State(initialValue: tagToEdit.name)
        _tagEmoji = State(initialValue: tagToEdit.emoji)
        _tagColor = State(initialValue: tagToEdit.color)
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Tag Name", text: $tagName)
                TextField("Emoji", text: $tagEmoji)
                ColorPicker("Tag Color", selection: $tagColor)
            }
            .navigationTitle("Edit Tag")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    if let index = tags.firstIndex(where: { $0.id == tagToEdit.id }) {
                        tags[index].name = tagName
                        tags[index].emoji = tagEmoji
                        tags[index].color = tagColor
                        
                        if selectedTag?.id == tagToEdit.id {
                            selectedTag = tags[index]
                        }
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(tagName.isEmpty || tagEmoji.isEmpty)
            )
        }
    }
}

struct NewTagView: View {
    @Binding var tags: [Tag]
    @State private var tagName = ""
    @State private var tagEmoji = ""
    @State private var tagColor = Color.blue
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                TextField("Tag Name", text: $tagName)
                TextField("Emoji", text: $tagEmoji)
                ColorPicker("Tag Color", selection: $tagColor)
            }
            .navigationTitle("New Tag")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let newTag = Tag(name: tagName, emoji: tagEmoji, color: tagColor)
                    tags.append(newTag)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(tagName.isEmpty || tagEmoji.isEmpty)
            )
        }
    }
}

struct Tag: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var emoji: String
    var color: Color
}

#Preview {
    ContentView()
}
