import ServiceLifecycle
import Synchronization
import Wire
import WireHummingbird

// A shared timeline so the harness can assert app-scope teardown runs *after* services
// have stopped — the prepend-first / shut-down-last property of `teardownService`.
let eventLog = Mutex<[String]>([])

// A resource with a producer-form `@Teardown` — the app-scope-resource shape (an HTTP or
// AWS client). It's injected into the service (so it's a live binding, not dead), and its
// `shutdown` logs to the timeline. The `@Teardown` closure stays a bare `resource.shutdown()`
// so the generated teardown never names the log.
final class ExampleResource: Sendable {
    func shutdown() async throws { eventLog.withLock { $0.append("resource-torn") } }
}

@Provides
@Teardown({ (resource: ExampleResource) in try await resource.shutdown() })
func makeExampleResource() -> ExampleResource { ExampleResource() }

// A fake app-scoped ServiceLifecycle service, in its natural shape: a `@Singleton`
// binding (it `@Inject`s the resource, as a real one would a pool/client) marked
// `@HummingbirdService`, which adds the `Service` conformance and aliases
// `@Contributes(to: HummingbirdKeys.services)`. WireHummingbird collates it into the
// graph's `services`, which `apply` returns for `Application(services:)`. It records
// that it started and stopped so the harness can assert the lifecycle fired end-to-end.
@Singleton
@HummingbirdService
final class HeartbeatService {
    let started = Mutex(false)
    let stopped = Mutex(false)
    let resource: ExampleResource

    @Inject init(resource: ExampleResource) { self.resource = resource }

    func run() async throws {
        started.withLock { $0 = true }
        try? await gracefulShutdown()
        stopped.withLock { $0 = true }
        eventLog.withLock { $0.append("service-stopped") }
    }
}
