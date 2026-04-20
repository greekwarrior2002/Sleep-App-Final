import WidgetKit
import SwiftUI

// Shared data key — the main app writes here after every sync
private let appGroupID = "group.com.slumber.app"
private let scoreKey = "widget.lastScore"
private let durationKey = "widget.lastDuration"
private let gradeKey = "widget.lastGrade"
private let trendKey = "widget.lastTrend"
private let dateKey = "widget.lastDate"

struct SleepWidgetEntry: TimelineEntry {
    let date: Date
    let score: Int
    let duration: String
    let grade: String
    let trend: String
    let sleepDate: String
}

struct SleepWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepWidgetEntry {
        SleepWidgetEntry(date: Date(), score: 78, duration: "7h 30m", grade: "Good", trend: "stable", sleepDate: "Last night")
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepWidgetEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepWidgetEntry>) -> Void) {
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry()], policy: .after(nextUpdate)))
    }

    private func entry() -> SleepWidgetEntry {
        let defaults = UserDefaults(suiteName: appGroupID)
        let score = defaults?.integer(forKey: scoreKey) ?? 0
        let duration = defaults?.string(forKey: durationKey) ?? "—"
        let grade = defaults?.string(forKey: gradeKey) ?? "No data"
        let trend = defaults?.string(forKey: trendKey) ?? "stable"
        let dateStr = defaults?.string(forKey: dateKey) ?? "—"
        return SleepWidgetEntry(date: Date(), score: score, duration: duration, grade: grade, trend: trend, sleepDate: dateStr)
    }
}

struct SleepScoreWidget: Widget {
    let kind = "SleepScoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepWidgetProvider()) { entry in
            SleepWidgetView(entry: entry)
                .containerBackground(Color.black, for: .widget)
        }
        .configurationDisplayName("Sleep Score")
        .description("See last night's sleep score at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Widget Data Writer (called from main app after sync)

struct SleepWidgetDataWriter {
    static func write(score: Int, duration: String, grade: String, trend: String, sleepDate: String) {
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(score, forKey: scoreKey)
        defaults?.set(duration, forKey: durationKey)
        defaults?.set(grade, forKey: gradeKey)
        defaults?.set(trend, forKey: trendKey)
        defaults?.set(sleepDate, forKey: dateKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
