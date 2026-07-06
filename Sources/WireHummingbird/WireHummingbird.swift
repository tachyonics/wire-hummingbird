import Hummingbird
import ServiceLifecycle
import Wire

// WireHummingbird — app-scoped collation for Hummingbird. Controllers
// (`@HummingbirdRoute`) and services (`@HummingbirdService`) contribute into collation
// keys; Wire emits a `HummingbirdComposable` conformance on the generated graph
// (knowing nothing about HTTP); `apply` applies the collated routes to a user-owned
// router that stays *outside* the graph and returns the collated services.
//
// The route surface carries no `Context` — a contributor's witness is a generic method,
// so the app's request context binds at the `apply` call, not on the controller.
// Controllers that need typed request-scoped state (auth) belong in WireMVC, not here.
//
// Each collation feature lives in its own file (`HummingbirdRoute.swift`,
// `HummingbirdService.swift`), extending `HummingbirdKeys` with its key; this file
// holds the shared surface — the keys namespace, the composable protocol, the graph
// conformance, and the `apply` facade.

/// The collation keys namespace; each feature adds its key by extension. `public`, so
/// the no-consumer check stays silent — the graph conformance consumes each invisibly
/// to the plugin, and an app could consume them externally — no `allowUnused` needed.
public enum HummingbirdKeys {}

/// The surface the facade consumes — the generated graph conforms to this.
public protocol HummingbirdComposable {
    var routes: [any HummingbirdRouteContributor] { get }
    var services: [any Service] { get }
}

/// Tells Wire to emit `extension _WireGraph: HummingbirdComposable`, mapping each
/// member to its `CollectedKey`'s product.
public let wireHummingbirdConformance = WireGraphConformanceV1(
    conformsTo: (any HummingbirdComposable).self,
    members: [.init("routes", from: HummingbirdKeys.routes), .init("services", from: HummingbirdKeys.services)]
)

public enum WireHummingbird {
    /// Apply the graph's collated route contributors to a user-owned router (the
    /// router's context binds each contributor's generic witness here) and return
    /// the graph's collated `ServiceLifecycle` services to hand to
    /// `Application(services:)`. Once `@Teardown` emission lands (M4), a
    /// graph-teardown `Service` prepends here so it shuts down last.
    @discardableResult
    public static func apply<Context: RequestContext>(
        _ graph: some HummingbirdComposable,
        to router: some RouterMethods<Context>
    ) -> [any Service] {
        for contributor in graph.routes {
            contributor.addWireRoutes(to: router)
        }
        return graph.services
    }
}
