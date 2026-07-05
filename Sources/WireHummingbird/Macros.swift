/// Makes a controller a `HummingbirdRouteContributor`, mounting its `addRoutes` under `path`
/// (`router.group(path)`). The controller keeps its natural `addRoutes(to: some
/// RouterMethods<some RequestContext>)`; the macro generates the `addWireRoutes`
/// witness. Pair with `@Singleton @Contributes(to: HummingbirdKeys.routes)`.
@attached(extension, conformances: HummingbirdRouteContributor, names: named(addWireRoutes(to:)))
public macro HummingbirdRoute(_ path: String) =
    #externalMacro(module: "WireHummingbirdMacros", type: "HummingbirdRouteMacro")

/// Makes a controller a `HummingbirdRouteContributor` mounted at the router root (no group).
@attached(extension, conformances: HummingbirdRouteContributor, names: named(addWireRoutes(to:)))
public macro HummingbirdRoute() =
    #externalMacro(module: "WireHummingbirdMacros", type: "HummingbirdRouteMacro")
