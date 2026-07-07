import ServiceLifecycle
import Wire

// The service collation feature: the collation key, the `@HummingbirdService` macro,
// and the contribution alias. `Service` is used in the key's `CollectedKey<any
// Service>` (an indexed declaration), so `import ServiceLifecycle` is genuinely used
// here — the macro's `conformances: Service` reference alone wouldn't satisfy
// SwiftLint's `unused_import` analyzer.

extension HummingbirdKeys {
    /// App-scoped `ServiceLifecycle` services (a DB client, a connection pool) a binding
    /// `@HummingbirdService` runs alongside the server. Context-free — `any Service`
    /// carries no request context — so it collates the way routes do.
    public static let services = CollectedKey<any Service>()
}

/// Marks a binding as a `ServiceLifecycle.Service` collated into the graph's services.
/// Adds the `Service` conformance if absent (the type still writes its own `run()`), and
/// aliases `@Contributes(to: HummingbirdKeys.services)` — so `@Singleton
/// @HummingbirdService` is all a service needs. Parallels `@HummingbirdController`.
@attached(extension, conformances: Service)
public macro HummingbirdService() =
    #externalMacro(module: "WireHummingbirdMacros", type: "HummingbirdServiceMacro")

/// Tells Wire that `@HummingbirdService` aliases `@Contributes(to: HummingbirdKeys.services)`,
/// so a service needs only `@Singleton @HummingbirdService` — the plugin collates it
/// without a separate `@Contributes`.
public let wireHummingbirdServiceAlias = WireAdapterAnnotationV1(
    annotation: "HummingbirdService",
    contributesTo: HummingbirdKeys.services
)
