import SwiftUI
import SwiftData

struct DailyLogSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = DailyLogViewModel()
    @State private var showSaveSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sleepBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.md) {
                        dateHeader
                        caffeineSection
                        exerciseSection
                        stressSection
                        alcoholSection
                        screenTimeSection
                        supplementsSection
                        napSection
                        moodSection
                        notesSection
                        Spacer(minLength: 100)
                    }
                    .padding(Spacing.md)
                }
                VStack {
                    Spacer()
                    saveButton
                        .padding(Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [Color.sleepBackground.opacity(0), Color.sleepBackground],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .ignoresSafeArea()
                        )
                }
            }
            .navigationTitle("Today's Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.textSecondary)
                }
            }
        }
        .task {
            viewModel.setup(context: context)
            await viewModel.loadExisting()
        }
        .onChange(of: viewModel.saveSuccess) { _, success in
            if success {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showSaveSuccess = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { dismiss() }
            }
        }
    }

    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Logging for")
                    .font(.bodyMedium)
                    .foregroundStyle(.textTertiary)
                Text(viewModel.date.relativeDescription)
                    .font(.titleLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(.textPrimary)
            }
            Spacer()
            Image(systemName: "calendar")
                .font(.system(size: 24))
                .foregroundStyle(.sleepPurpleLight)
        }
    }

    private var caffeineSection: some View {
        LogSection(title: "Caffeine", icon: "cup.and.saucer.fill", iconColor: .scoreFair,
                   badge: viewModel.totalCaffeineMg > 0 ? "\(viewModel.totalCaffeineMg) mg" : nil) {
            VStack(spacing: Spacing.sm) {
                if !viewModel.caffeineEntries.isEmpty {
                    ForEach(Array(viewModel.caffeineEntries.enumerated()), id: \.element.id) { index, _ in
                        CaffeineEntryRowView(
                            entry: Binding(
                                get: { viewModel.caffeineEntries[index] },
                                set: { viewModel.caffeineEntries[index] = $0 }
                            ),
                            onDelete: { viewModel.caffeineEntries.remove(at: index) }
                        )
                    }
                }
                SingleSelectChipGroup(
                    options: CaffeineEntry.commonSources,
                    selected: Binding(
                        get: { nil },
                        set: { if let s = $0 { viewModel.addCaffeineEntry(source: s) } }
                    ),
                    color: .scoreFair
                )
            }
        }
    }

    private var exerciseSection: some View {
        LogSection(title: "Exercise", icon: "figure.run", iconColor: .sleepTeal,
                   badge: viewModel.totalExerciseMinutes > 0 ? "\(viewModel.totalExerciseMinutes) min" : nil) {
            VStack(spacing: Spacing.sm) {
                if !viewModel.exerciseEntries.isEmpty {
                    ForEach(Array(viewModel.exerciseEntries.enumerated()), id: \.element.id) { index, _ in
                        ExerciseEntryRowView(
                            entry: Binding(
                                get: { viewModel.exerciseEntries[index] },
                                set: { viewModel.exerciseEntries[index] = $0 }
                            ),
                            onDelete: { viewModel.exerciseEntries.remove(at: index) }
                        )
                    }
                }
                SingleSelectChipGroup(
                    options: ExerciseEntry.commonTypes,
                    selected: Binding(
                        get: { nil },
                        set: { if let s = $0 { viewModel.addExerciseEntry(type: s) } }
                    ),
                    color: .sleepTeal
                )
            }
        }
    }

    private var stressSection: some View {
        LogSection(title: "Stress Level", icon: "brain.head.profile", iconColor: .sleepPurpleLight,
                   badge: viewModel.stressLevel > 0 ? "\(viewModel.stressLevel)/5" : nil) {
            StressSlider(value: $viewModel.stressLevel)
        }
    }

    private var alcoholSection: some View {
        LogSection(title: "Alcohol", icon: "wineglass.fill", iconColor: .scorePoor,
                   badge: viewModel.alcoholUnits > 0 ? String(format: "%.1f units", viewModel.alcoholUnits) : nil) {
            HStack {
                Text("Standard drinks")
                    .font(.bodyMedium)
                    .foregroundStyle(.textSecondary)
                Spacer()
                Stepper(value: $viewModel.alcoholUnits, in: 0...15, step: 0.5) {
                    Text(viewModel.alcoholUnits > 0 ? String(format: "%.1f", viewModel.alcoholUnits) : "None")
                        .font(.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.alcoholUnits > 0 ? Color.scorePoor : Color.textTertiary)
                        .monoDigits()
                }
                .tint(.scorePoor)
            }
        }
    }

    private var screenTimeSection: some View {
        LogSection(title: "Screen Time Before Bed", icon: "iphone", iconColor: .warning,
                   badge: viewModel.screenTimeMinutes > 0 ? "\(viewModel.screenTimeMinutes) min" : nil) {
            SleepSlider(
                value: Binding(
                    get: { Double(viewModel.screenTimeMinutes) },
                    set: { viewModel.screenTimeMinutes = Int($0) }
                ),
                range: 0...180, step: 5, trackColor: .warning
            )
        }
    }

    private var supplementsSection: some View {
        LogSection(title: "Supplements", icon: "pill.fill", iconColor: .positive,
                   badge: viewModel.selectedSupplements.isEmpty ? nil : "\(viewModel.selectedSupplements.count)") {
            SelectableChipGroup(
                options: DailyLogViewModel.commonSupplements,
                selected: $viewModel.selectedSupplements,
                color: .positive
            )
        }
    }

    private var napSection: some View {
        LogSection(title: "Nap", icon: "bed.double.fill", iconColor: .sleepTealLight) {
            VStack(spacing: Spacing.sm) {
                Toggle("Took a nap today", isOn: $viewModel.hasNap)
                    .font(.bodyMedium)
                    .foregroundStyle(.textSecondary)
                    .tint(.sleepTeal)
                if viewModel.hasNap {
                    HStack {
                        Text("Duration").font(.bodyMedium).foregroundStyle(.textSecondary)
                        Spacer()
                        Picker("Duration", selection: $viewModel.napDurationMinutes) {
                            ForEach([10, 15, 20, 30, 45, 60, 90], id: \.self) { min in
                                Text("\(min) min").tag(min)
                            }
                        }
                        .tint(.sleepTealLight)
                    }
                    DatePicker("Time", selection: $viewModel.napTime, displayedComponents: .hourAndMinute)
                        .font(.bodyMedium)
                        .foregroundStyle(.textSecondary)
                        .tint(.sleepTeal)
                        .colorScheme(.dark)
                }
            }
        }
    }

    private var moodSection: some View {
        LogSection(title: "Mood", icon: "face.smiling.fill", iconColor: .sleepPurpleLight) {
            VStack(spacing: Spacing.sm) {
                if viewModel.moodAfterWaking > 0 {
                    moodRow(label: "This morning", value: $viewModel.moodAfterWaking)
                }
                moodRow(label: "Before sleep", value: $viewModel.moodBeforeSleep)
            }
        }
    }

    private func moodRow(label: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label).font(.bodyMedium).foregroundStyle(.textSecondary)
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { v in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                            value.wrappedValue = v
                        }
                    } label: {
                        Image(systemName: v <= value.wrappedValue ? "star.fill" : "star")
                            .font(.system(size: 24))
                            .foregroundStyle(v <= value.wrappedValue ? Color.scoreFair : Color.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var notesSection: some View {
        LogSection(title: "Notes", icon: "note.text", iconColor: .textSecondary) {
            TextEditor(text: $viewModel.notes)
                .font(.bodyMedium)
                .foregroundStyle(.textSecondary)
                .frame(minHeight: 80, maxHeight: 120)
                .scrollContentBackground(.hidden)
                .overlay(alignment: .topLeading) {
                    if viewModel.notes.isEmpty {
                        Text("Anything else that might affect your sleep tonight?")
                            .font(.bodyMedium)
                            .foregroundStyle(.textTertiary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var saveButton: some View {
        PrimaryButton(
            title: showSaveSuccess ? "Saved!" : "Save Log",
            icon: showSaveSuccess ? "checkmark" : nil,
            isLoading: viewModel.isSaving
        ) {
            Task { await viewModel.save() }
        }
    }
}

private struct LogSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    var badge: String? = nil
    let content: () -> Content

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .frame(width: 20)
                    Text(title)
                        .font(.titleSmall)
                        .foregroundStyle(.textPrimary)
                    Spacer()
                    if let badge {
                        Text(badge)
                            .font(.labelSmall)
                            .fontWeight(.semibold)
                            .foregroundStyle(iconColor)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 3)
                            .background { Capsule().fill(iconColor.opacity(0.15)) }
                    }
                }
                content()
            }
        }
    }
}

private struct CaffeineEntryRowView: View {
    @Binding var entry: CaffeineEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(entry.source)
                .font(.bodyMedium)
                .foregroundStyle(.textSecondary)
            Spacer()
            DatePicker("", selection: $entry.time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .colorScheme(.dark)
                .tint(.scoreFair)
            Stepper(value: $entry.amountMg, in: 10...600, step: 10) {
                Text("\(entry.amountMg) mg")
                    .font(.labelLarge)
                    .fontWeight(.medium)
                    .foregroundStyle(.scoreFair)
                    .monoDigits()
                    .frame(width: 55)
            }
            .tint(.scoreFair)
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill").foregroundStyle(.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Spacing.xxs)
    }
}

private struct ExerciseEntryRowView: View {
    @Binding var entry: ExerciseEntry
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Text(entry.type).font(.bodyMedium).foregroundStyle(.textSecondary)
                Spacer()
                Stepper(value: $entry.durationMinutes, in: 5...300, step: 5) {
                    Text("\(entry.durationMinutes) min")
                        .font(.labelLarge)
                        .fontWeight(.medium)
                        .foregroundStyle(.sleepTeal)
                        .monoDigits()
                        .frame(width: 60)
                }
                .tint(.sleepTeal)
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill").foregroundStyle(.textTertiary)
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: Spacing.xs) {
                ForEach(ExerciseTime.allCases, id: \.self) { time in
                    Button {
                        entry.timeOfDay = time
                    } label: {
                        Text(time.displayName)
                            .font(.caption)
                            .foregroundStyle(entry.timeOfDay == time ? .white : Color.textTertiary)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 4)
                            .background {
                                Capsule().fill(entry.timeOfDay == time ? Color.sleepTeal : Color.sleepElevated)
                            }
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                IntensityPicker(value: $entry.intensityLevel)
                    .frame(width: 140)
            }
        }
    }
}
