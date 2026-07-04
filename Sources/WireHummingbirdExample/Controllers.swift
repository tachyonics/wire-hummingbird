import Hummingbird
import Wire
import WireHummingbird

// An injected app service.
@Singleton
struct Greeter {
    @Inject init() {}
    func greeting(_ name: String) -> String { "Hello, \(name)!" }
}

// A controller in its natural shape (as in hummingbird-examples): `@Inject`ed app
// deps, and a hand-written `addRoutes` that adds routes relative to whatever group
// it's handed. `@Singleton` makes it a binding; `@Contributes` fans it into the
// routes key.
@Singleton
@Contributes(to: HummingbirdKeys.routes)
struct HelloController {
    private let greeter: Greeter

    @Inject init(greeter: Greeter) {
        self.greeter = greeter
    }

    func addRoutes(to router: some RouterMethods<some RequestContext>) {
        router.get(":name") { _, context in
            self.greeter.greeting(context.parameters.get("name") ?? "world")
        }
    }
}

// Hand-written stand-in for what `@HummingbirdRoute("hello")` will codegen in step
// two: the Wire-internal witness owns the mount ("hello") and delegates to the
// controller's hand-written `addRoutes`.
extension HelloController: RouteContributor {
    // Stand-in for @HummingbirdRoute("hello") codegen.
    func addWireRoutes<Context: RequestContext>(to router: some RouterMethods<Context>) {
        addRoutes(to: router.group("hello"))
    }
}
