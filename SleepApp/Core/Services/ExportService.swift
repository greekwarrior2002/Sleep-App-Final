import Foundation
import UIKit

@MainActor
final class ExportService {
    static let shared = ExportService()
    private init() {}

    func generateCSV(sessions: [SleepSession], logs: [DailyLog]) -> URL? {
        let sorted = sessions.sorted { $0.endDate > $1.endDate }
        var rows: [String] = [csvHeader]

        let logsByDate: [Date: DailyLog] = Dictionary(
            uniqueKeysWithValues: logs.map { (Calendar.current.startOfDay(for: $0.date), $0) }
        )

        for session in sorted {
            let log = logsByDate[session.calendarDate]
            rows.append(csvRow(session: session, log: log))
        }

        let csv = rows.joined(separator: "\n")
        let fileName = "slumber_export_\(Date().exportDateString).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    func generatePDFReport(sessions: [SleepSession]) -> URL? {
        let sorted = sessions.sorted { $0.endDate > $1.endDate }
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let fileName = "slumber_report_\(Date().exportDateString).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try renderer.writePDF(to: url) { ctx in
                ctx.beginPage()
                drawPDFContent(sessions: sorted, in: pageRect, context: ctx)
            }
            return url
        } catch {
            return nil
        }
    }

    private var csvHeader: String {
        "Date,Bedtime,Wake Time,Duration (h),Efficiency (%),Deep Sleep (h),REM Sleep (h),Light Sleep (h),Score,HRV (ms),Heart Rate (bpm),Source,Caffeine (mg),Exercise (min),Stress (0-10),Alcohol (units),Screen Time (min),Mood Before,Mood After"
    }

    private func csvRow(session: SleepSession, log: DailyLog?) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"

        let fields: [String] = [
            fmt.string(from: session.endDate),
            timeFmt.string(from: session.startDate),
            timeFmt.string(from: session.endDate),
            String(format: "%.2f", session.durationHours),
            String(format: "%.1f", session.sleepEfficiency * 100),
            String(format: "%.2f", session.deepSleepDuration / 3600),
            String(format: "%.2f", session.remSleepDuration / 3600),
            String(format: "%.2f", session.lightSleepDuration / 3600),
            session.score.map { "\($0.overallScore)" } ?? "",
            session.heartRateVariability.map { String(format: "%.1f", $0) } ?? "",
            session.averageHeartRate.map { String(format: "%.1f", $0) } ?? "",
            "\"\(session.sourceApp)\"",
            log.map { "\($0.totalCaffeineMg)" } ?? "",
            log.map { "\($0.totalExerciseMinutes)" } ?? "",
            log.map { "\($0.stressLevel)" } ?? "",
            log.map { String(format: "%.1f", $0.alcoholUnits) } ?? "",
            log.map { "\($0.screenTimeMinutes)" } ?? "",
            log.map { $0.moodBeforeSleep.map { "\($0)" } ?? "" } ?? "",
            log.map { $0.moodAfterWaking.map { "\($0)" } ?? "" } ?? ""
        ]
        return fields.joined(separator: ",")
    }

    private func drawPDFContent(sessions: [SleepSession], in rect: CGRect, context: UIGraphicsPDFRendererContext) {
        let margin: CGFloat = 40
        var y: CGFloat = margin

        // Title
        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        UIColor(red: 0.05, green: 0.06, blue: 0.1, alpha: 1).setFill()
        UIRectFill(rect)

        "Slumber Sleep Report".draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttr)
        y += 36

        let subAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.lightGray
        ]
        "Generated \(Date().longDateString) · \(sessions.count) nights".draw(at: CGPoint(x: margin, y: y), withAttributes: subAttr)
        y += 30

        // Summary stats
        if !sessions.isEmpty {
            let avgScore = sessions.compactMap { $0.score?.overallScore }.reduce(0, +) / max(1, sessions.count)
            let avgDur = sessions.map(\.durationHours).reduce(0, +) / Double(sessions.count)

            let statsAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.white
            ]
            "Avg Score: \(avgScore)   Avg Duration: \(String(format: "%.1f", avgDur))h   Nights: \(sessions.count)"
                .draw(at: CGPoint(x: margin, y: y), withAttributes: statsAttr)
            y += 30
        }

        // Table header
        let headerAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: UIColor(red: 0.67, green: 0.55, blue: 0.98, alpha: 1)
        ]
        let rowAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.white
        ]

        UIColor(red: 0.11, green: 0.15, blue: 0.22, alpha: 1).setFill()
        UIRectFill(CGRect(x: margin, y: y, width: rect.width - 2 * margin, height: 20))
        "Date         Score   Duration   Deep     REM     Efficiency".draw(at: CGPoint(x: margin + 4, y: y + 4), withAttributes: headerAttr)
        y += 22

        let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
        for (i, session) in sessions.prefix(30).enumerated() {
            if y > rect.height - margin { break }
            if i % 2 == 0 {
                UIColor(red: 0.09, green: 0.12, blue: 0.18, alpha: 1).setFill()
                UIRectFill(CGRect(x: margin, y: y, width: rect.width - 2 * margin, height: 18))
            }
            let score = session.score.map { "\($0.overallScore)" } ?? "—"
            let line = String(format: "%-12s  %-6s  %-9s  %-8s  %-7s  %.0f%%",
                (fmt.string(from: session.endDate) as NSString).utf8String!,
                (score as NSString).utf8String!,
                (session.formattedDuration as NSString).utf8String!,
                (session.deepSleepDuration.shortDuration as NSString).utf8String!,
                (session.remSleepDuration.shortDuration as NSString).utf8String!,
                session.sleepEfficiency * 100
            )
            line.draw(at: CGPoint(x: margin + 4, y: y + 3), withAttributes: rowAttr)
            y += 18
        }
    }
}

private extension Date {
    var exportDateString: String {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: self)
    }
    var longDateString: String {
        let fmt = DateFormatter(); fmt.dateStyle = .long
        return fmt.string(from: self)
    }
}

private extension TimeInterval {
    var shortDuration: String {
        let h = Int(self / 3600)
        let m = Int((self.truncatingRemainder(dividingBy: 3600)) / 60)
        if h == 0 { return "\(m)m" }
        return "\(h)h\(m > 0 ? "\(m)m" : "")"
    }
}
