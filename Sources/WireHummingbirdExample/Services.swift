import ServiceLifecycle
import Synchronization
import Wire
import WireHummingbird

// A fake app-scoped ServiceLifecycle service, in its natural shape: a `@Singleton`
// binding (it could `@Inject` a DB config, a pool, etc.) marked `@HummingbirdService`,
// which adds the `Service` conformance and aliases `@Contributes(to:
// HummingbirdKeys.services)`. WireHummingbird collates it into the graph's `services`,
// which `apply` returns for `Application(services:)`. It records that it started and
// shut down so the harness can assert the lifecycle fired end-to-end.
@Singleton
@HummingbirdService
final class HeartbeatService {
    let started = Mutex(false)
    let stopped = Mutex(false)

    @Inject init() {}

    func run() async throws {
        started.withLock { $0 = true }
        try? await gracefulShutdown()
        stopped.withLock { $0 = true }
    }
}
