import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct WireHummingbirdMacrosPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [HummingbirdRouteMacro.self]
}
