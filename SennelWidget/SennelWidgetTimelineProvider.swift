import WidgetKit
import SwiftUI
import SwiftData
import Foundation

struct SennelWidgetTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SennelWidgetEntry {
        SennelWidgetEntry(date: .now, nextSlot: Date(timeIntervalSinceNow: 3600), usedToday: 3, dailyLimit: 8, isPremium: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SennelWidgetEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SennelWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .after(Date(timeIntervalSinceNow: 300)))
        completion(timeline)
    }

    private func loadEntry() -> SennelWidgetEntry {
        let container = SennelPersistence.makeContainer()
        let context = ModelContext(container)

        let profiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        let profile = profiles.first ?? UserProfile()

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        guard profile.dailyLimit > 0 else {
            return SennelWidgetEntry(date: .now, nextSlot: nil, usedToday: 0, dailyLimit: 8, isPremium: profile.isPremium)
        }

        let windowStart = calendar.date(byAdding: .hour, value: 8, to: startOfDay) ?? startOfDay
        let windowEnd = calendar.date(byAdding: .hour, value: 22, to: startOfDay) ?? startOfDay

        let interval = windowEnd.timeIntervalSince(windowStart) / Double(profile.dailyLimit)
        let nextSlot: Date? = (0..<profile.dailyLimit).first { i in
            i >= profile.usedToday
        }.map { i in
            windowStart.addingTimeInterval(interval * Double(i))
        }

        return SennelWidgetEntry(date: .now, nextSlot: nextSlot, usedToday: profile.usedToday, dailyLimit: profile.dailyLimit, isPremium: profile.isPremium)
    }
}

struct SennelWidgetEntry: TimelineEntry {
    let date: Date
    let nextSlot: Date?
    let usedToday: Int
    let dailyLimit: Int
    let isPremium: Bool
}
