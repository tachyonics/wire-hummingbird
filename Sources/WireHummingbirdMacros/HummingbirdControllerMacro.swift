import SwiftSyntax
import SwiftSyntaxMacros

/// `@HummingbirdController("path")` generates a `HummingbirdRouteContributor` conformance whose
/// `addWireRoutes` witness owns the mount — `router.group("path")` — and delegates
/// to the controller's hand-written `addRoutes`. With no argument it mounts at the
/// router root (`addRoutes(to: router)`).
public struct HummingbirdControllerMacro: ExtensionMacro {
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

        // The witness must be at least as accessible as the controller — it satisfies a public
        // protocol requirement, so a `public` or `package` controller needs a matching witness.
        let access = accessModifier(declaration.modifiers)

        let conformance: DeclSyntax =
            """
            extension \(type.trimmed): HummingbirdRouteContributor {
                \(raw: access)func addWireRoutes<Context: RequestContext>(to router: some RouterMethods<Context>) {
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

    /// The access-control modifier (with a trailing space) the witness must carry to match the
    /// controller's, or `""` for internal/private controllers where a default-access witness
    /// already satisfies the requirement. `open` maps to `public` — a struct witness can't be `open`.
    private static func accessModifier(_ modifiers: DeclModifierListSyntax) -> String {
        for modifier in modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.public), .keyword(.open): return "public "
            case .keyword(.package): return "package "
            default: continue
            }
        }
        return ""
    }
}
