import Foundation

extension Double {
    func rounded(to places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }

    var percentString: String { "\(Int(self * 100))%" }

    var heartRateString: String { "\(Int(self)) bpm" }

    var hrvString: String { "\(Int(self)) ms" }
}

extension Int {
    var sleepScoreGrade: String {
        switch self {
        case 85...: return "Excellent"
        case 70..<85: return "Good"
        case 50..<70: return "Fair"
        default: return "Poor"
        }
    }
}

extension Array where Element: BinaryFloatingPoint {
    var mean: Element {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Element(count)
    }

    var standardDeviation: Element {
        guard count > 1 else { return 0 }
        let avg = mean
        let variance = map { (value: Element) -> Element in pow(value - avg, 2) }.reduce(0, +) / Element(count - 1)
        return sqrt(variance)
    }
}
