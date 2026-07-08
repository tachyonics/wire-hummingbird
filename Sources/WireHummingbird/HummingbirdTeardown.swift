import Logging
import ServiceLifecycle
import Wire

// The teardown feature: a `ServiceLifecycle.Service` that runs the graph's `teardown()`
// at app-scope shutdown. Teardown is a *graph* concern (every Wire graph is
// `Teardownable`), not tied to any adapter's `apply`, so it's a standalone facade the app
// prepends to its service list — independent of whether `WireHummingbird.apply` /
// `WireOpenAPI.apply` are also called.

extension WireHummingbird {
    /// A service that runs `graph.teardown()` at shutdown. **Prepend** it to the services
    /// handed to `Application(services:)` / a `ServiceGroup`: ServiceLifecycle shuts
    /// services down in reverse registration order, so the first-registered teardown
    /// service shuts down *last* — resources drain only after every other service (the
    /// HTTP server included) has stopped. Teardown errors are collected and logged; they
    /// don't fail shutdown.
    public static func teardownService(_ graph: some Teardownable & Sendable, logger: Logger) -> some Service {
        GraphTeardownService(graph: graph, logger: logger)
    }
}

/// Runs `graph.teardown()` once graceful shutdown is triggered for it — which, prepended,
/// is after the services registered after it have stopped. The graph is `Sendable` (as any
/// graph run in a `ServiceGroup` must be); `Teardownable` itself stays Sendable-free so a
/// non-`Sendable` graph still conforms.
struct GraphTeardownService: Service {
    let graph: any Teardownable & Sendable
    let logger: Logger

    func run() async throws {
        // Suspend until this service is asked to shut down (gracefully or via
        // cancellation); either way, run teardown afterwards.
        try? await gracefulShutdown()
        for error in await graph.teardown() {
            logger.error("Wire graph teardown action failed", metadata: ["error": "\(error)"])
        }
    }
}
