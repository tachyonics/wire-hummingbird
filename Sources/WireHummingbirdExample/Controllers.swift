import Hummingbird
import Wire
import WireHummingbird

// An injected app service.
@Singleton
struct Greeter {
    @Inject init() {}
    func greeting(_ name: String) -> String { "Hello, \(name)!" }
}

// The "instance is the contributor" path (M2.2): raw Wire annotations, no
// `@HummingbirdRoute` macro. `@Singleton` makes it a binding, `@Contributes` fans
// it into the routes key, and it conforms to `RouteContributor` directly — so the
// generated `HummingbirdComposable` conformance surfaces it, and `apply` calls its
// `addRoutes`.
@Singleton
@Contributes(to: HummingbirdKeys.routes)
struct HelloController: RouteContributor {
    typealias Context = BasicRequestContext
    private let greeter: Greeter

    @Inject init(greeter: Greeter) {
        self.greeter = greeter
    }

    func addRoutes(to router: some RouterMethods<BasicRequestContext>) {
        router.get("hello/:name") { _, context in
            self.greeter.greeting(context.parameters.get("name") ?? "world")
        }
    }
}
