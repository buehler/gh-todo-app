import Flutter
@testable import Runner
import Security
import UIKit
import XCTest

class RunnerTests: XCTestCase {

  func testTodoFeedIncludesAllOpenIssues() {
    XCTAssertTrue(
      shouldIncludeInTodoFeed(
        closed: false,
        closedAtRaw: "not-a-timestamp",
        updatedAt: Date.distantPast,
        now: Date(timeIntervalSince1970: 1_000_000)
      )
    )
  }

  func testTodoFeedIncludesRecentlyClosedIssue() {
    let now = Date(timeIntervalSince1970: 1_000_000)
    let closedAt = now.addingTimeInterval(-3 * 24 * 60 * 60 + 1)

    XCTAssertTrue(
      shouldIncludeInTodoFeed(
        closed: true,
        closedAtRaw: ISO8601DateFormatter().string(from: closedAt),
        updatedAt: Date.distantPast,
        now: now
      )
    )
  }

  func testTodoFeedExcludesClosedIssueOlderThanThreeDays() {
    let now = Date(timeIntervalSince1970: 1_000_000)
    let closedAt = now.addingTimeInterval(-3 * 24 * 60 * 60 - 1)

    XCTAssertFalse(
      shouldIncludeInTodoFeed(
        closed: true,
        closedAtRaw: ISO8601DateFormatter().string(from: closedAt),
        updatedAt: now,
        now: now
      )
    )
  }

  func testTodoFeedFallsBackToUpdatedAtWhenClosedAtIsMissing() {
    let now = Date(timeIntervalSince1970: 1_000_000)

    XCTAssertTrue(
      shouldIncludeInTodoFeed(
        closed: true,
        closedAtRaw: nil,
        updatedAt: now.addingTimeInterval(-60),
        now: now
      )
    )
  }

  func testTodoFeedExcludesMalformedClosedTimestamp() {
    XCTAssertFalse(
      shouldIncludeInTodoFeed(
        closed: true,
        closedAtRaw: "not-a-timestamp",
        updatedAt: Date(),
        now: Date()
      )
    )
  }

  func testPATAccessibilityMigrationOutcomes() {
    XCTAssertEqual(PATAccessibilityMigrator.outcome(for: errSecSuccess), .migrated)
    XCTAssertEqual(PATAccessibilityMigrator.outcome(for: errSecItemNotFound), .noItem)
    XCTAssertEqual(
      PATAccessibilityMigrator.outcome(for: errSecInteractionNotAllowed),
      .deferredForProtectedData
    )
    XCTAssertEqual(
      PATAccessibilityMigrator.outcome(for: errSecMissingEntitlement),
      .failed(errSecMissingEntitlement)
    )
  }

  func testPATMigrationUpdatesOnlyAccessibility() {
    let attributes = PATAccessibilityMigrator.updateAttributes()

    XCTAssertEqual(
      attributes[kSecAttrAccessible] as? CFString,
      kSecAttrAccessibleAfterFirstUnlock
    )
    XCTAssertNil(attributes[kSecValueData])
  }

}
