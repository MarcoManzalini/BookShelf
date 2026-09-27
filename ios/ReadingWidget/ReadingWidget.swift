// Home screen widget for iOS: the book being read, its progress and the
// streak. NOT part of the Xcode project yet: it needs a Widget Extension
// target and an App Group, which need a paid Apple developer account.
// See README.md in this folder for the steps.

import SwiftUI
import WidgetKit

/// Must match `ReadingWidgetSync.iOSAppGroup` in the Flutter app and the App
/// Group enabled on both the Runner and the widget target.
private let appGroup = "group.com.marcomanzalini.bookshelf"

struct ReadingEntry: TimelineEntry {
  let date: Date
  let hasBook: Bool
  let label: String
  let title: String
  let author: String
  let progress: Int
  let progressLabel: String
  let streak: String
}

struct ReadingProvider: TimelineProvider {
  func placeholder(in context: Context) -> ReadingEntry {
    ReadingEntry(
      date: Date(), hasBook: true, label: "In lettura", title: "Dune",
      author: "Frank Herbert", progress: 40, progressLabel: "240 / 600",
      streak: "5 giorni di fila")
  }

  func getSnapshot(in context: Context, completion: @escaping (ReadingEntry) -> Void) {
    completion(entry(for: Date()))
  }

  /// One entry now and one just after each of the next midnights, so "read
  /// today" becomes "read yesterday" without the app running.
  func getTimeline(in context: Context, completion: @escaping (Timeline<ReadingEntry>) -> Void) {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    var entries = [entry(for: Date())]
    for day in 1...7 {
      if let midnight = calendar.date(byAdding: .day, value: day, to: today) {
        entries.append(entry(for: midnight.addingTimeInterval(60)))
      }
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  private func entry(for date: Date) -> ReadingEntry {
    let data = UserDefaults(suiteName: appGroup)
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = "yyyy-MM-dd"
    let today = formatter.string(from: date)
    let yesterday = formatter.string(
      from: Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date)
    let last = data?.string(forKey: "last_read_day") ?? ""
    let streakKey = last == today ? "streak_today" : last == yesterday ? "streak_alive" : "streak_none"
    let hasBook = data?.bool(forKey: "has_book") ?? false
    return ReadingEntry(
      date: date,
      hasBook: hasBook,
      label: data?.string(forKey: "label_reading") ?? "In lettura",
      title: hasBook
        ? (data?.string(forKey: "title") ?? "")
        : (data?.string(forKey: "label_no_book") ?? "Nessun libro in lettura"),
      author: data?.string(forKey: "author") ?? "",
      progress: data?.integer(forKey: "progress") ?? -1,
      progressLabel: data?.string(forKey: "progress_label") ?? "",
      streak: data?.string(forKey: streakKey) ?? "")
  }
}

struct ReadingWidgetView: View {
  let entry: ReadingEntry
  private let accent = Color(red: 1, green: 0.54, blue: 0.24)

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(entry.label.uppercased())
        .font(.caption2).bold().foregroundColor(accent)
      Text(entry.title)
        .font(.headline).foregroundColor(.white).lineLimit(2)
      if entry.hasBook && !entry.author.isEmpty {
        Text(entry.author).font(.caption).foregroundColor(.white.opacity(0.7)).lineLimit(1)
      }
      Spacer(minLength: 4)
      if entry.hasBook && entry.progress >= 0 {
        ProgressView(value: Double(entry.progress), total: 100).tint(accent)
        Text(entry.progressLabel).font(.caption2).foregroundColor(.white.opacity(0.7))
      }
      if !entry.streak.isEmpty {
        Label(entry.streak, systemImage: "flame.fill")
          .font(.caption).foregroundColor(.white).lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .containerBackground(for: .widget) { Color(red: 0.09, green: 0.09, blue: 0.11) }
  }
}

@main
struct ReadingWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "ReadingWidget", provider: ReadingProvider()) { entry in
      ReadingWidgetView(entry: entry)
    }
    .configurationDisplayName("BookShelf")
    .description("Il libro che stai leggendo e la tua serie")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
