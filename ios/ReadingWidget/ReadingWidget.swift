// Home screen widgets for iOS: the book being read (with its progress and
// the streak), the library and the statistics. NOT part of the Xcode project
// yet: they need a Widget Extension target and an App Group, which need a
// paid Apple developer account.
// See README.md in this folder for the steps.

import SwiftUI
import WidgetKit

/// Must match `ReadingWidgetSync.iOSAppGroup` in the Flutter app and the App
/// Group enabled on both the Runner and the widget target.
private let appGroup = "group.com.marcomanzalini.bookshelf"

/// Reads what the app saved (see lib/features/home_widget).
private struct WidgetStore {
  let data = UserDefaults(suiteName: appGroup)
  let date: Date

  func string(_ key: String, _ fallback: String = "") -> String {
    data?.string(forKey: key) ?? fallback
  }

  func int(_ key: String, _ fallback: Int = 0) -> Int {
    data?.object(forKey: key) == nil ? fallback : data!.integer(forKey: key)
  }

  /// Whether the last day with reading is today, yesterday or older.
  private var streakKey: String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = "yyyy-MM-dd"
    let today = formatter.string(from: date)
    let yesterday = formatter.string(
      from: Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date)
    let last = string("last_read_day")
    return last == today ? "streak_today" : last == yesterday ? "streak_alive" : "streak_none"
  }

  var streakLine: String { string(streakKey) }

  /// Days in a row, 0 once a whole day went by without reading.
  var streakCount: Int { streakKey == "streak_none" ? 0 : int("streak_count") }
}

/// One entry now and one just after each of the next midnights, so "read
/// today" becomes "read yesterday" without the app running.
private func midnightTimeline<E: TimelineEntry>(_ make: (Date) -> E) -> Timeline<E> {
  let calendar = Calendar.current
  let today = calendar.startOfDay(for: Date())
  var entries = [make(Date())]
  for day in 1...7 {
    if let midnight = calendar.date(byAdding: .day, value: day, to: today) {
      entries.append(make(midnight.addingTimeInterval(60)))
    }
  }
  return Timeline(entries: entries, policy: .atEnd)
}

private let accent = Color(red: 1, green: 0.54, blue: 0.24)
private let widgetBackground = Color(red: 0.09, green: 0.09, blue: 0.11)

// MARK: - Reading

struct ReadingEntry: TimelineEntry {
  let date: Date
  let hasBook: Bool
  let label: String
  let title: String
  let author: String
  let progress: Int
  let progressLabel: String
  let info: [String]
  let streak: String
  let streakCount: Int
}

struct ReadingProvider: TimelineProvider {
  func placeholder(in context: Context) -> ReadingEntry {
    ReadingEntry(
      date: Date(), hasBook: true, label: "In lettura", title: "Dune",
      author: "Frank Herbert", progress: 40, progressLabel: "240 / 600",
      info: ["360 pagine rimaste"], streak: "5 giorni di fila", streakCount: 5)
  }

  func getSnapshot(in context: Context, completion: @escaping (ReadingEntry) -> Void) {
    completion(entry(for: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ReadingEntry>) -> Void) {
    completion(midnightTimeline(entry(for:)))
  }

  private func entry(for date: Date) -> ReadingEntry {
    let store = WidgetStore(date: date)
    let hasBook = store.data?.bool(forKey: "has_book") ?? false
    return ReadingEntry(
      date: date,
      hasBook: hasBook,
      label: store.string("label_reading", "In lettura"),
      title: hasBook
        ? store.string("title")
        : store.string("label_no_book", "Nessun libro in lettura"),
      author: store.string("author"),
      progress: store.int("progress", -1),
      progressLabel: store.string("progress_label"),
      info: ["info_left", "info_finish", "info_since"]
        .map { store.string($0) }.filter { !$0.isEmpty },
      streak: store.streakLine,
      streakCount: store.streakCount)
  }
}

struct ReadingWidgetView: View {
  let entry: ReadingEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    let small = family == .systemSmall
    VStack(alignment: .leading, spacing: 4) {
      Text(entry.label.uppercased())
        .font(.caption2).bold().foregroundColor(accent)
      Text(entry.title)
        .font(.headline).foregroundColor(.white).lineLimit(small ? 3 : 2)
      if entry.hasBook && !small && !entry.author.isEmpty {
        Text(entry.author).font(.caption).foregroundColor(.white.opacity(0.7)).lineLimit(1)
      }
      if entry.hasBook && family == .systemLarge {
        VStack(alignment: .leading, spacing: 2) {
          ForEach(entry.info, id: \.self) { line in
            Text(line).font(.caption).foregroundColor(.white.opacity(0.9)).lineLimit(1)
          }
        }
        .padding(.top, 8)
      }
      Spacer(minLength: 4)
      if entry.hasBook && entry.progress >= 0 {
        ProgressView(value: Double(entry.progress), total: 100).tint(accent)
        if !small {
          Text(entry.progressLabel).font(.caption2).foregroundColor(.white.opacity(0.7))
        }
      }
      if small {
        Label("\(entry.streakCount)", systemImage: "flame.fill")
          .font(.caption).foregroundColor(.white)
      } else if !entry.streak.isEmpty {
        Label(entry.streak, systemImage: "flame.fill")
          .font(.caption).foregroundColor(.white).lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .containerBackground(for: .widget) { widgetBackground }
  }
}

struct ReadingWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "ReadingWidget", provider: ReadingProvider()) { entry in
      ReadingWidgetView(entry: entry)
    }
    .configurationDisplayName("BookShelf")
    .description("Il libro che stai leggendo e la tua serie")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

// MARK: - Library

struct LibraryRow: Hashable {
  let title: String
  let subtitle: String
  let progress: Int
}

struct LibraryEntry: TimelineEntry {
  let date: Date
  let counts: [(count: Int, label: String)]
  let readingLabel: String
  let reading: [LibraryRow]
  let wantLabel: String
  let want: [LibraryRow]
  let shelves: String
  let empty: String
}

struct LibraryProvider: TimelineProvider {
  func placeholder(in context: Context) -> LibraryEntry {
    LibraryEntry(
      date: Date(),
      counts: [(2, "In lettura"), (14, "Da leggere"), (37, "Letti")],
      readingLabel: "In lettura",
      reading: [LibraryRow(title: "Dune", subtitle: "240 / 600 pagine", progress: 40)],
      wantLabel: "Da leggere",
      want: [LibraryRow(title: "Il nome della rosa", subtitle: "Umberto Eco", progress: -1)],
      shelves: "Scaffali: Fantasy 8", empty: "Niente qui per ora")
  }

  func getSnapshot(in context: Context, completion: @escaping (LibraryEntry) -> Void) {
    completion(entry(for: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<LibraryEntry>) -> Void) {
    completion(Timeline(entries: [entry(for: Date())], policy: .never))
  }

  private func entry(for date: Date) -> LibraryEntry {
    let store = WidgetStore(date: date)
    func rows(_ prefix: String) -> [LibraryRow] {
      (0..<3).compactMap { i in
        let title = store.string("\(prefix)_\(i)_title")
        return title.isEmpty ? nil : LibraryRow(
          title: title,
          subtitle: store.string("\(prefix)_\(i)_sub"),
          progress: store.int("\(prefix)_\(i)_progress", -1))
      }
    }
    let shelves = store.string("lib_shelves")
    return LibraryEntry(
      date: date,
      counts: [
        (store.int("lib_reading_count"), store.string("lib_label_reading", "In lettura")),
        (store.int("lib_want_count"), store.string("lib_label_want", "Da leggere")),
        (store.int("lib_read_count"), store.string("lib_label_read", "Letti")),
      ],
      readingLabel: store.string("lib_label_reading", "In lettura"),
      reading: rows("lib_r"),
      wantLabel: store.string("lib_label_want", "Da leggere"),
      want: rows("lib_w"),
      shelves: shelves.isEmpty ? "" : "\(store.string("lib_label_shelves", "Scaffali")): \(shelves)",
      empty: store.string("lib_label_empty", "Niente qui per ora"))
  }
}

struct LibraryWidgetView: View {
  let entry: LibraryEntry
  @Environment(\.widgetFamily) private var family

  private func section(_ label: String, _ rows: [LibraryRow], max: Int) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label.uppercased()).font(.caption2).bold().foregroundColor(accent)
      if rows.isEmpty {
        Text(entry.empty).font(.caption2).foregroundColor(.white.opacity(0.7))
      }
      ForEach(rows.prefix(max), id: \.self) { row in
        VStack(alignment: .leading, spacing: 1) {
          Text(row.title).font(.subheadline).bold().foregroundColor(.white).lineLimit(1)
          if !row.subtitle.isEmpty {
            Text(row.subtitle).font(.caption2).foregroundColor(.white.opacity(0.7)).lineLimit(1)
          }
          if row.progress >= 0 {
            ProgressView(value: Double(row.progress), total: 100).tint(accent)
          }
        }
      }
    }
  }

  var body: some View {
    let large = family == .systemLarge
    VStack(alignment: .leading, spacing: 12) {
      if large {
        HStack {
          ForEach(entry.counts, id: \.label) { item in
            VStack(alignment: .leading) {
              Text("\(item.count)").font(.title3).bold().foregroundColor(.white)
              Text(item.label).font(.caption2).foregroundColor(.white.opacity(0.7)).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
      section(entry.readingLabel, entry.reading, max: large ? 3 : 2)
      if large {
        section(entry.wantLabel, entry.want, max: 3)
        Spacer(minLength: 0)
        if !entry.shelves.isEmpty {
          Text(entry.shelves).font(.caption2).foregroundColor(.white.opacity(0.9)).lineLimit(1)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .containerBackground(for: .widget) { widgetBackground }
  }
}

struct LibraryWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "LibraryWidget", provider: LibraryProvider()) { entry in
      LibraryWidgetView(entry: entry)
    }
    .configurationDisplayName("BookShelf · Libreria")
    .description("I libri che stai leggendo, i prossimi e i tuoi scaffali")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

// MARK: - Statistics

struct StatsEntry: TimelineEntry {
  let date: Date
  let year: String
  let books: Int
  let booksLabel: String
  let goalProgress: Int
  let goal: String
  let tiles: [(value: Int, label: String)]
}

struct StatsProvider: TimelineProvider {
  func placeholder(in context: Context) -> StatsEntry {
    StatsEntry(
      date: Date(), year: "Il tuo 2026", books: 12, booksLabel: "libri letti",
      goalProgress: 50, goal: "Obiettivo: 12 di 24",
      tiles: [(5, "giorni di fila"), (320, "pagine questo mese"), (18, "pagine al giorno")])
  }

  func getSnapshot(in context: Context, completion: @escaping (StatsEntry) -> Void) {
    completion(entry(for: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<StatsEntry>) -> Void) {
    completion(midnightTimeline(entry(for:)))
  }

  private func entry(for date: Date) -> StatsEntry {
    let store = WidgetStore(date: date)
    return StatsEntry(
      date: date,
      year: store.string("stat_label_year"),
      books: store.int("stat_books_year"),
      booksLabel: store.string("stat_label_books"),
      goalProgress: store.int("stat_goal_progress", -1),
      goal: store.string("stat_label_goal"),
      tiles: [
        (store.streakCount, store.string("stat_label_streak")),
        (store.int("stat_pages_month"), store.string("stat_label_month")),
        (store.int("stat_avg_pages"), store.string("stat_label_avg")),
      ])
  }
}

struct StatsWidgetView: View {
  let entry: StatsEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    HStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 2) {
        Text(entry.year.uppercased()).font(.caption2).bold().foregroundColor(accent)
        Spacer(minLength: 0)
        Text("\(entry.books)").font(.system(size: 34, weight: .bold)).foregroundColor(.white)
        Text(entry.booksLabel).font(.caption).foregroundColor(.white.opacity(0.7))
        Spacer(minLength: 0)
        if entry.goalProgress >= 0 {
          ProgressView(value: Double(entry.goalProgress), total: 100).tint(accent)
        }
        Text(entry.goal).font(.caption2).foregroundColor(.white.opacity(0.7)).lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      if family != .systemSmall {
        VStack(alignment: .leading) {
          ForEach(Array(entry.tiles.enumerated()), id: \.offset) { index, tile in
            HStack(spacing: 8) {
              if index == 0 {
                Label("\(tile.value)", systemImage: "flame.fill").labelStyle(.titleAndIcon)
                  .font(.headline).foregroundColor(.white)
              } else {
                Text("\(tile.value)").font(.headline).foregroundColor(.white)
              }
              Text(tile.label).font(.caption2).foregroundColor(.white.opacity(0.7)).lineLimit(2)
            }
            .frame(maxHeight: .infinity)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .containerBackground(for: .widget) { widgetBackground }
  }
}

struct StatsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "StatsWidget", provider: StatsProvider()) { entry in
      StatsWidgetView(entry: entry)
    }
    .configurationDisplayName("BookShelf · Statistiche")
    .description("Libri letti quest'anno, obiettivo, serie e pagine")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@main
struct BookShelfWidgets: WidgetBundle {
  var body: some Widget {
    ReadingWidget()
    LibraryWidget()
    StatsWidget()
  }
}
