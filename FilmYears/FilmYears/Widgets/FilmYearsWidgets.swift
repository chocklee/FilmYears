import WidgetKit
import SwiftUI

struct TodayFrameProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayFrameEntry {
        TodayFrameEntry(date: .now, isFilled: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayFrameEntry) -> Void) {
        completion(TodayFrameEntry(date: .now, isFilled: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayFrameEntry>) -> Void) {
        let entry = TodayFrameEntry(date: .now, isFilled: false)
        let refreshInterval: TimeInterval = 15 * 60
        let refreshDate = Date.now.addingTimeInterval(refreshInterval)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

struct TodayFrameEntry: TimelineEntry {
    let date: Date
    let isFilled: Bool
}

struct TodayFrameWidgetEntryView: View {
    var entry: TodayFrameEntry

    var body: some View {
        VStack(spacing: 4) {
            if entry.isFilled {
                Image(systemName: "photo.fill")
                    .font(.title)
                Text("今日已记录")
                    .font(.caption2)
            } else {
                Image(systemName: "film")
                    .font(.title)
                    .foregroundColor(.secondary)
                Text("Today's Frame")
                    .font(.caption2)
                Text("Add a photo")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "widget://open-today-frame"))
    }
}

struct TodayFrameWidget: Widget {
    let kind: String = "TodayFrameWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayFrameProvider()) { entry in
            TodayFrameWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("今日帧")
        .description("快速查看和添加今日的胶片帧")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Random Frame Widget

struct RandomFrameWidget: Widget {
    let kind: String = "RandomFrameWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayFrameProvider()) { entry in
            VStack {
                Image(systemName: "photo.on.rectangle")
                    .font(.title)
                Text("随机回忆")
                    .font(.caption2)
            }
            .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("随机胶片帧")
        .description("随机展示一段历史回忆")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Year Ring Widget

struct YearRingWidget: Widget {
    let kind: String = "YearRingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayFrameProvider()) { entry in
            VStack {
                Circle()
                    .stroke(Color.accentColor, lineWidth: 6)
                    .frame(width: 40, height: 40)
                Text("2026")
                    .font(.caption2)
            }
            .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("年轮缩略")
        .description("查看某年的记忆年轮")
        .supportedFamilies([.systemSmall])
    }
}
