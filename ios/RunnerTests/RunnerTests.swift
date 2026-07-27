import Flutter
@testable import Runner
import Security
import UIKit
import XCTest

class RunnerTests: XCTestCase {

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
