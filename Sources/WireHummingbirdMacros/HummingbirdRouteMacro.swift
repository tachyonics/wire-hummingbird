import SwiftSyntax
import SwiftSyntaxMacros

/// `@HummingbirdRoute("path")` generates a `RouteContributor` conformance whose
/// `addWireRoutes` witness owns the mount — `router.group("path")` — and delegates
/// to the controller's hand-written `addRoutes`. With no argument it mounts at the
/// router root (`addRoutes(to: router)`).
public struct HummingbirdRouteMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // The mount target: a named group if a path was given, else the router root.
        let target: String
        if let path = firstStringLiteral(node.arguments) {
            target = "router.group(\"\(path)\")"
        } else {
            target = "router"
        }

        let conformance: DeclSyntax =
            """
            extension \(type.trimmed): RouteContributor {
                func addWireRoutes<Context: RequestContext>(to router: some RouterMethods<Context>) {
                    addRoutes(to: \(raw: target))
                }
            }
            """
        return [conformance.cast(ExtensionDeclSyntax.self)]
    }

    /// The first positional string-literal argument's value, or `nil` if the
    /// attribute has no arguments.
    private static func firstStringLiteral(_ arguments: AttributeSyntax.Arguments?) -> String? {
        guard case let .argumentList(list) = arguments, let first = list.first else { return nil }
        return first.expression.as(StringLiteralExprSyntax.self)?.representedLiteralValue
    }
}
