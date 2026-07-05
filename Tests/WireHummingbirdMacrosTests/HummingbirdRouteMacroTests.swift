import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import WireHummingbirdMacros

final class HummingbirdRouteMacroTests: XCTestCase {
    private let macros: [String: any Macro.Type] = ["HummingbirdRoute": HummingbirdRouteMacro.self]

    func testGroupMount() {
        assertMacroExpansion(
            """
            @HummingbirdRoute("todos")
            struct TodoController {}
            """,
            expandedSource: """
                struct TodoController {}

                extension TodoController: HummingbirdRouteContributor {
                    func addWireRoutes<Context: RequestContext>(to router: some RouterMethods<Context>) {
                        addRoutes(to: router.group("todos"))
                    }
                }
                """,
            macros: macros
        )
    }

    func testRootMount() {
        assertMacroExpansion(
            """
            @HummingbirdRoute
            struct RootController {}
            """,
            expandedSource: """
                struct RootController {}

                extension RootController: HummingbirdRouteContributor {
                    func addWireRoutes<Context: RequestContext>(to router: some RouterMethods<Context>) {
                        addRoutes(to: router)
                    }
                }
                """,
            macros: macros
        )
    }
}
