# WireHummingbird

A [swift-wire](https://github.com/tachyonics/swift-wire) adapter for
[Hummingbird](https://github.com/hummingbird-project/hummingbird).

Controllers are ordinary Wire bindings that `@Contributes` into a routes key; Wire
emits a `HummingbirdComposable` conformance on the generated graph (knowing nothing
about HTTP), and `WireHummingbird.apply` applies the collated routes to a `Router`
that stays **outside** the graph. The collation surface is **context-free** — a
controller's routing is a generic method, so the app's request context binds at
`apply`, not on the controller:

```swift
@Singleton
@Contributes(to: HummingbirdKeys.routes)
struct HelloController {
    @Inject init(greeter: Greeter) { self.greeter = greeter }
    // Your natural routing, relative to whatever group it's handed.
    func addRoutes(to router: some RouterMethods<some RequestContext>) {
        router.get(":name") { _, ctx in greeter.greeting(ctx.parameters.get("name") ?? "world") }
    }
}

// The conformance the `@HummingbirdRoute("hello")` macro will generate for you —
// it owns the mount and delegates to `addRoutes`:
extension HelloController: RouteContributor {
    func addWireRoutes<Context: RequestContext>(to router: some RouterMethods<Context>) {
        addRoutes(to: router.group("hello"))
    }
}

let graph = try await Wire.bootstrap()
let router = Router(context: BasicRequestContext.self)   // the app picks its context
WireHummingbird.apply(graph, to: router)                 // applies collated routes
let app = Application(router: router)
```

Status: **M2 slice, step one** — the context-free `RouteContributor` surface with a
hand-written conformance. The `@HummingbirdRoute("path")` macro that generates the
conformance is step two. Controllers that need typed request-scoped state (auth via
`context.identity`) belong in WireMVC, not here.

Depends on pushed `swift-wire` main. Run the end-to-end example:

```
swift run WireHummingbirdExample
```
