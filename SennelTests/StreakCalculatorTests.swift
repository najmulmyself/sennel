import XCTest
@testable import Sennel

final class StreakCalculatorTests: XCTestCase {
    func testStageBoundaries() {
        XCTAssertEqual(StreakCalculator.streakStage(forDays: 0), .stage0)
        XCTAssertEqual(StreakCalculator.streakStage(forDays: 2), .stage0)
        XCTAssertEqual(StreakCalculator.streakStage(forDays: 3), .stage1)
        XCTAssertEqual(StreakCalculator.streakStage(forDays: 7), .stage1)
        XCTAssertEqual(StreakCalculator.streakStage(forDays: 8), .stage2)
        XCTAssertEqual(StreakCalculator.streakStage(forDays: 29), .stage2)
        XCTAssertEqual(StreakCalculator.streakStage(forDays: 30), .stage3)
    }

    func testMoneySaved() {
        let result = StreakCalculator.moneySaved(daysClean: 10, pouchesPerDay: 12, costPerPouch: 0.35)
        XCTAssertEqual(result, 42.0, accuracy: 0.0001)
    }

    func testMoneySavedAtZeroDays() {
        let result = StreakCalculator.moneySaved(daysClean: 0, pouchesPerDay: 12, costPerPouch: 0.35)
        XCTAssertEqual(result, 0, accuracy: 0.0001)
    }

    func testNextEligibleTimeDividesWakingHoursEvenly() {
        let calendar = Calendar(identifier: .gregorian)
        let lastLog = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 7))!
        let next = StreakCalculator.nextEligibleTime(lastLogTime: lastLog, dailyGoal: 4, calendar: calendar)
        let expectedInterval: TimeInterval = (16 * 3600) / 4
        XCTAssertEqual(next.timeIntervalSince(lastLog), expectedInterval, accuracy: 0.0001)
    }

    func testNextEligibleTimeGuardsAgainstZeroDailyGoal() {
        let lastLog = Date()
        let next = StreakCalculator.nextEligibleTime(lastLogTime: lastLog, dailyGoal: 0)
        // max(dailyGoal, 1) guard should prevent a divide-by-zero crash and still
        // return a time strictly after lastLog.
        XCTAssertGreaterThan(next, lastLog)
    }

    func testCurrentStreakDaysCountsCalendarDaysNotRawSeconds() {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 23))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 1))!
        // Only 2 hours apart, but crosses a calendar day boundary — should count as 1 day,
        // not 0, per the technical spec's explicit timezone/DST guard (§10).
        XCTAssertEqual(StreakCalculator.currentStreakDays(from: start, now: now), 1)
    }
}
