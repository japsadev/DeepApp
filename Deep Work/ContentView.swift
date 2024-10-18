//
//  ContentView.swift
//  Deep Work
//
//  Created by japsa on 18.10.2024.
//

import SwiftUI

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
    var body: some View {
        Text("Stats View")
    }
}

struct FocusView: View {
    @State private var focusDuration: Double = 0
    @State private var isTimerRunning = false
    @State private var showingTagSelection = false
    @State private var selectedTag: Tag?
    @State private var tags: [Tag] = [Tag(name: "Deep Work", emoji: "🎯", color: .blue)]

    var body: some View {
        VStack(spacing: 20) {
            CircularSliderView(
                value: $focusDuration,
                inRange: 0...180,
                step: 5,
                sliderColor: selectedTag?.color ?? .blue,
                emoji: selectedTag?.emoji ?? "🎯"
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
//                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(selectedTag?.color)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(100)
            }
            .padding(.horizontal)

            Text(timeString(from: Int(focusDuration * 60)))
                .font(.title)
                .bold()

            Button(action: {
                self.isTimerRunning.toggle()
            }) {
                Text(isTimerRunning ? "Pause Focus" : "Start Focus")
                    .padding()
                    .background(selectedTag?.color ?? .blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .sheet(isPresented: $showingTagSelection) {
            SelectTagView(tags: $tags, selectedTag: $selectedTag)
        }
    }

    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
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

    init(value: Binding<Double>, inRange range: ClosedRange<Int>, step: Double, sliderColor: Color, emoji: String) {
        self._value = value
        self.inRange = Double(range.lowerBound)...Double(range.upperBound)
        self.step = step
        self.sliderColor = sliderColor
        self.emoji = emoji
    }

    private var progressFraction: Double {
        (value - inRange.lowerBound) / (inRange.upperBound - inRange.lowerBound)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .stroke(sliderColor.opacity(0.3), lineWidth: 20)
                Circle()
                    .trim(from: 0, to: CGFloat(progressFraction))
                    .stroke(sliderColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                // Knob
                Circle()
                    .fill(sliderColor)
                    .frame(width: 30, height: 30)
                    .shadow(radius: 4)
                    .offset(x: geometry.size.width / 2 * cos(2 * .pi * progressFraction - .pi / 2),
                            y: geometry.size.width / 2 * sin(2 * .pi * progressFraction - .pi / 2))
                
                Text(emoji)
                    .font(.system(size: 100))
                
                // Gesture area
                Circle()
                    .fill(Color.clear)
                    .contentShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { dragValue in
                                updateProgress(dragValue: dragValue, in: geometry.size)
                            }
                    )
            }
        }
        .aspectRatio(1, contentMode: .fit)
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
                        
                        // Update selectedTag if it was the edited tag
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
