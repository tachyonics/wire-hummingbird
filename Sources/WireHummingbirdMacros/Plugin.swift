import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct WireHummingbirdMacrosPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [HummingbirdControllerMacro.self, HummingbirdServiceMacro.self]
}
