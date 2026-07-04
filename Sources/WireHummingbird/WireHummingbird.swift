import Hummingbird
import Wire

// WireHummingbird — the app-scoped route collation. Routes collate as `[any
// RouteContributor<Context>]`; the generated graph conforms to
// `HummingbirdComposable` via the `WireGraphConformanceV1` below; `apply` applies
// the collated contributors to a user-owned router that stays *outside* the graph.
//
// Context is pinned to `BasicRequestContext` here (the common case) — the routes
// key carries it, so the emitted conformance's associated `Context` infers to it.
// A custom-context app declares its own key + conformance.

/// A controller that registers its routes onto any `RouterMethods` of the app's
/// context. Generic over the router so the facade can apply it to a `Router` or a
/// `RouterGroup`; the app context is pinned as a primary associated type.
public protocol RouteContributor<Context> {
    associatedtype Context: RequestContext
    func addRoutes(to router: some RouterMethods<Context>)
}

/// The collation key route controllers `@Contributes(to:)`. `allowUnused` because
/// it's consumed by the generated conformance, not `@Inject`ed.
public enum HummingbirdKeys {
    public static let routes = CollectedKey<any RouteContributor<BasicRequestContext>>(allowUnused: true)
}

/// The surface the facade consumes — the generated graph conforms to this.
public protocol HummingbirdComposable {
    associatedtype Context: RequestContext
    var routes: [any RouteContributor<Context>] { get }
}

/// Tells Wire to emit `extension _WireGraph: HummingbirdComposable`, mapping
/// `routes` to the routes `CollectedKey`'s product.
public let wireHummingbirdConformance = WireGraphConformanceV1(
    conformsTo: (any HummingbirdComposable).self,
    members: [.init("routes", from: HummingbirdKeys.routes)]
)

public enum WireHummingbird {
    /// Apply the graph's collated route contributors to a user-owned router.
    public static func apply<Graph: HummingbirdComposable>(
        _ graph: Graph,
        to router: some RouterMethods<Graph.Context>
    ) {
        for contributor in graph.routes {
            contributor.addRoutes(to: router)
        }
    }
}
