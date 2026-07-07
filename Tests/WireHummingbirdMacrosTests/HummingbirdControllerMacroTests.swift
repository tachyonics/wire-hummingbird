import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import WireHummingbirdMacros

final class HummingbirdControllerMacroTests: XCTestCase {
    private let macros: [String: any Macro.Type] = ["HummingbirdController": HummingbirdControllerMacro.self]

    func testGroupMount() {
        assertMacroExpansion(
            """
            @HummingbirdController("todos")
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
            @HummingbirdController
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

    func testPackageAccessWitness() {
        assertMacroExpansion(
            """
            @HummingbirdController("todos")
            package struct TodoController {}
            """,
            expandedSource: """
                package struct TodoController {}

                extension TodoController: HummingbirdRouteContributor {
                    package func addWireRoutes<Context: RequestContext>(to router: some RouterMethods<Context>) {
                        addRoutes(to: router.group("todos"))
                    }
                }
                """,
            macros: macros
        )
    }
}
