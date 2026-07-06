import Hummingbird
import HummingbirdTesting
import Logging
import ServiceLifecycle
import WireHummingbird

// End-to-end: build the app-scoped graph, apply its collated routes to a
// user-owned router (which stays *outside* the graph), and get back the collated
// `ServiceLifecycle` services. `Wire.bootstrap()` returns the concrete graph, which
// conforms to `HummingbirdComposable` via the plugin-generated extension, so it
// feeds `WireHummingbird.apply` directly.
let graph = try await Wire.bootstrap()

let router = Router(context: BasicRequestContext.self)
let services = WireHummingbird.apply(graph, to: router)

// Route slice (M2.2/M2.3): the @HummingbirdRoute controller serves in-process.
let app = Application(router: router)
try await app.test(.router) { client in
    let body = try await client.execute(uri: "/hello/Ada", method: .get) { response in
        String(buffer: response.body)
    }
    precondition(body == "Hello, Ada!", "hello route failed: \(body)")
}

// Service lifecycle (M2.5): the @HummingbirdService HeartbeatService is collated
// into `apply`'s return, so an app hands it to `Application(services:)`.
// Run the collated services in a group and trigger graceful shutdown once started —
// proving the collation delivers a real, runnable service that starts and stops.
precondition(services.count == 1, "expected 1 collated service, got \(services.count)")

let serviceGroup = ServiceGroup(
    configuration: .init(
        services: services.map { .init(service: $0) },
        logger: Logger(label: "wire-hummingbird-example")
    )
)
try await withThrowingTaskGroup(of: Void.self) { group in
    group.addTask { try await serviceGroup.run() }
    while !graph.heartbeatService.started.withLock({ $0 }) {
        try await Task.sleep(for: .milliseconds(1))
    }
    await serviceGroup.triggerGracefulShutdown()
    try await group.waitForAll()
}
precondition(graph.heartbeatService.started.withLock { $0 }, "service never started")
precondition(graph.heartbeatService.stopped.withLock { $0 }, "service never shut down")

print(
    "wire-hummingbird OK — @HummingbirdRoute controller served + @HummingbirdService "
        + "collated into apply() and run through its ServiceLifecycle start/stop"
)
