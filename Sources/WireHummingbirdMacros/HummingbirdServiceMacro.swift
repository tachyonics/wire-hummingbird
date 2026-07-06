import SwiftSyntax
import SwiftSyntaxMacros

/// `@HummingbirdService` adds the `ServiceLifecycle.Service` conformance for a binding
/// (if it isn't already stated) — the type still writes its own `run()`. Wire reads
/// the attribute as an alias for `@Contributes(to: HummingbirdKeys.services)`; the
/// conformance is the framework surface, generated at expansion.
public struct HummingbirdServiceMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let conformance: DeclSyntax = "extension \(type.trimmed): Service {}"
        return [conformance.cast(ExtensionDeclSyntax.self)]
    }
}
