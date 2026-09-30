import Flutter
@testable import Runner
import UIKit
import XCTest

class RunnerTests: XCTestCase {

  private let mappedProject = WidgetProject(
    id: "project-id",
    name: "Project",
    ownerLogin: "owner",
    dueDateFieldId: "custom-date-field",
    priorityFieldId: "custom-priority-field",
    priorityOptionMap: [
      "option-urgent": "urgent",
      "option-high": "high",
      "option-medium": "medium",
      "option-low": "low",
      "option-trivial": "trivial",
      "option-invalid": "not-a-priority",
    ]
  )

  func testWidgetResolvesCustomPriorityNamesThroughConfiguredIds() {
    let result = resolveMappedFields(
      fieldValues: [
        WidgetProjectFieldValue(
          typeName: "ProjectV2ItemFieldSingleSelectValue",
          fieldId: "custom-priority-field",
          fieldName: "Impact level",
          optionId: "option-urgent",
          optionName: "P0 - Drop everything",
          date: nil
        )
      ],
      project: mappedProject
    )

    XCTAssertEqual(result.priority, .urgent)
  }

  func testWidgetResolvesEveryConfiguredPriorityLevel() {
    let mappings: [(String, TodoPriority)] = [
      ("option-urgent", .urgent),
      ("option-high", .high),
      ("option-medium", .medium),
      ("option-low", .low),
      ("option-trivial", .trivial),
    ]

    for (optionId, expected) in mappings {
      let result = resolveMappedFields(
        fieldValues: [priorityFieldValue(optionId: optionId)],
        project: mappedProject
      )
      XCTAssertEqual(result.priority, expected)
    }
  }

  func testWidgetIgnoresWrongPriorityFieldAndUnmappedOptions() {
    let wrongField = WidgetProjectFieldValue(
      typeName: "ProjectV2ItemFieldSingleSelectValue",
      fieldId: "other-field",
      fieldName: "Priority",
      optionId: "option-high",
      optionName: "High",
      date: nil
    )
    let unmappedOption = priorityFieldValue(optionId: "unknown-option")
    let invalidMapping = priorityFieldValue(optionId: "option-invalid")

    XCTAssertNil(resolveMappedFields(fieldValues: [wrongField], project: mappedProject).priority)
    XCTAssertNil(resolveMappedFields(fieldValues: [unmappedOption], project: mappedProject).priority)
    XCTAssertNil(resolveMappedFields(fieldValues: [invalidMapping], project: mappedProject).priority)
  }

  func testWidgetResolvesCustomDueDateNameThroughConfiguredId() {
    let result = resolveMappedFields(
      fieldValues: [
        WidgetProjectFieldValue(
          typeName: "ProjectV2ItemFieldDateValue",
          fieldId: "custom-date-field",
          fieldName: "Target delivery",
          optionId: nil,
          optionName: nil,
          date: "2026-08-20"
        )
      ],
      project: mappedProject
    )

    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
    XCTAssertEqual(
      calendar.dateComponents([.year, .month, .day], from: result.dueDate!),
      DateComponents(year: 2026, month: 8, day: 20)
    )
  }

  func testWidgetProjectDecodesSharedPriorityConfiguration() throws {
    let json = """
      {
        "id": "project-id",
        "name": "Project",
        "ownerLogin": "owner",
        "dueDateFieldId": "custom-date-field",
        "priorityFieldId": "custom-priority-field",
        "priorityOptionMap": {"github-option": "high"}
      }
      """

    let project = try JSONDecoder().decode(WidgetProject.self, from: Data(json.utf8))

    XCTAssertEqual(project.priorityFieldId, "custom-priority-field")
    XCTAssertEqual(project.dueDateFieldId, "custom-date-field")
    XCTAssertEqual(project.priorityOptionMap["github-option"], "high")
  }

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

  private func priorityFieldValue(optionId: String) -> WidgetProjectFieldValue {
    WidgetProjectFieldValue(
      typeName: "ProjectV2ItemFieldSingleSelectValue",
      fieldId: "custom-priority-field",
      fieldName: "Custom priority",
      optionId: optionId,
      optionName: "Custom option",
      date: nil
    )
  }

}
