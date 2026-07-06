import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import WireHummingbirdMacros

final class HummingbirdServiceMacroTests: XCTestCase {
    private let macros: [String: any Macro.Type] = ["HummingbirdService": HummingbirdServiceMacro.self]

    func testAddsServiceConformance() {
        assertMacroExpansion(
            """
            @HummingbirdService
            final class HeartbeatService {
                func run() async throws {}
            }
            """,
            expandedSource: """
                final class HeartbeatService {
                    func run() async throws {}
                }

                extension HeartbeatService: Service {
                }
                """,
            macros: macros
        )
    }
}
