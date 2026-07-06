import ServiceLifecycle

/// Makes a controller a `HummingbirdRouteContributor`, mounting its `addRoutes` under `path`
/// (`router.group(path)`). The controller keeps its natural `addRoutes(to: some
/// RouterMethods<some RequestContext>)`; the macro generates the `addWireRoutes`
/// witness. Aliases `@Contributes(to: HummingbirdKeys.routes)`, so `@Singleton
/// @HummingbirdRoute("path")` is all a controller needs.
@attached(extension, conformances: HummingbirdRouteContributor, names: named(addWireRoutes(to:)))
public macro HummingbirdRoute(_ path: String) =
    #externalMacro(module: "WireHummingbirdMacros", type: "HummingbirdRouteMacro")

/// Makes a controller a `HummingbirdRouteContributor` mounted at the router root (no group).
@attached(extension, conformances: HummingbirdRouteContributor, names: named(addWireRoutes(to:)))
public macro HummingbirdRoute() =
    #externalMacro(module: "WireHummingbirdMacros", type: "HummingbirdRouteMacro")

/// Marks a binding as a `ServiceLifecycle.Service` collated into the graph's
/// services. Adds the `Service` conformance if absent (the type still writes its own
/// `run()`), and aliases `@Contributes(to: HummingbirdKeys.services)` — so `@Singleton
/// @HummingbirdService` is all a service needs. Parallels `@HummingbirdRoute`.
@attached(extension, conformances: Service)
public macro HummingbirdService() =
    #externalMacro(module: "WireHummingbirdMacros", type: "HummingbirdServiceMacro")
