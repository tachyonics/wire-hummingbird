import Hummingbird
import HummingbirdTesting
import Logging
import ServiceLifecycle
import Wire
import WireHummingbird

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// End-to-end: build the app-scoped graph, apply its collated routes to a
// user-owned router (which stays *outside* the graph), and get back the collated
// `ServiceLifecycle` services. `Wire.bootstrap()` returns the concrete graph, which
// conforms to `HummingbirdComposable` via the plugin-generated extension, so it
// feeds `WireHummingbird.apply` directly.
let graph = try await Wire.bootstrap()

let router = Router(context: BasicRequestContext.self)
let services = WireHummingbird.apply(graph, to: router)

// Introspection endpoint (M2.7): the app computes `graph.introspect()` and mounts it
// on a group it controls — here "wiring"; in production, behind auth — serving the
// framework-agnostic wiring model as JSON.
WireHummingbird.mountIntrospection(graph, on: router.group("wiring"))

// Route slice (M2.2/M2.3) + introspection (M2.7): served in-process.
let app = Application(router: router)
try await app.test(.router) { client in
    let body = try await client.execute(uri: "/hello/Ada", method: .get) { response in
        String(buffer: response.body)
    }
    precondition(body == "Hello, Ada!", "hello route failed: \(body)")

    let wiring = try await client.execute(uri: "/wiring", method: .get) { response in
        precondition(response.status == .ok, "wiring status \(response.status)")
        return try JSONDecoder().decode(WiringModel.self, from: Data(response.body.readableBytesView))
    }
    precondition(
        wiring.bindings.contains { $0.type == "Greeter" && $0.kind == .singleton },
        "wiring missing Greeter singleton"
    )
    precondition(
        wiring.bindings.contains { $0.type == "HelloController" },
        "wiring missing HelloController"
    )
    precondition(
        wiring.bindings.contains { $0.kind == .aggregate },
        "wiring missing a collated aggregate (routes/services)"
    )
    precondition(
        wiring.bindings.allSatisfy { !$0.location.module.isEmpty },
        "wiring binding missing source location"
    )
}

// Service lifecycle (M2.5): the @HummingbirdService HeartbeatService is collated
// into `apply`'s return, so an app hands it to `Application(services:)`.
// Run the collated services in a group and trigger graceful shutdown once started —
// proving the collation delivers a real, runnable service that starts and stops.
precondition(services.count == 1, "expected 1 collated service, got \(services.count)")

// Teardown (M4): the graph's `@Teardown` actions run at shutdown via a service prepended
// to the list so it shuts down *last* — after every other service has stopped. `graph`
// feeds it as `some Teardownable` (the plugin-generated conformance).
let logger = Logger(label: "wire-hummingbird-example")
let allServices: [any Service] = [WireHummingbird.teardownService(graph, logger: logger)] + services

let serviceGroup = ServiceGroup(
    configuration: .init(
        services: allServices.map { .init(service: $0) },
        logger: logger
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

// The graph's teardown ran, and it ran *after* the service stopped (prepended → last).
let events = eventLog.withLock { $0 }
let serviceStopped = events.firstIndex(of: "service-stopped")
let resourceTorn = events.firstIndex(of: "resource-torn")
precondition(resourceTorn != nil, "graph teardown never ran")
precondition(
    serviceStopped != nil && serviceStopped! < resourceTorn!,
    "teardown ran before the service stopped: \(events)"
)

print(
    "wire-hummingbird OK — @HummingbirdController controller served + @HummingbirdService "
        + "collated + /wiring introspection + @Teardown ran at shutdown, after the service stopped"
)
