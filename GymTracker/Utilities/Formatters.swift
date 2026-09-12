import Foundation

/// Shared date and number formatting so the whole app displays data the
/// same way.
enum AppFormatters {

    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    /// e.g. "September 11, 2026"
    static func longDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).day().year())
    }

    /// e.g. "Sep 11"
    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    /// "Today", "Yesterday", or a short date.
    static func relativeDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return shortDate(date)
    }

    /// A weight such as 185 or 182.5 → "185" / "182.5".
    static func weight(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return decimalFormatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// Total volume, e.g. "4,850 lb".
    static func volume(_ value: Double) -> String {
        let formatted = decimalFormatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formatted) lb"
    }

    /// Time-of-day greeting for the Home screen.
    static func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}