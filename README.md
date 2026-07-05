# WireHummingbird

A [swift-wire](https://github.com/tachyonics/swift-wire) adapter for
[Hummingbird](https://github.com/hummingbird-project/hummingbird).

Controllers are ordinary Wire bindings that `@HummingbirdRoute` fans into a routes
key; Wire emits a `HummingbirdComposable` conformance on the generated graph (knowing
nothing about HTTP), and `WireHummingbird.apply` applies the collated routes to a
`Router` that stays **outside** the graph. The collation surface is **context-free** —
a controller's routing is a generic method, so the app's request context binds at
`apply`, not on the controller:

```swift
@Singleton
@HummingbirdRoute("hello")   // aliases @Contributes(to: HummingbirdKeys.routes) + mounts under /hello
struct HelloController {
    @Inject init(greeter: Greeter) { self.greeter = greeter }
    // Your natural routing, relative to the group @HummingbirdRoute hands it.
    func addRoutes(to router: some RouterMethods<some RequestContext>) {
        router.get(":name") { _, ctx in greeter.greeting(ctx.parameters.get("name") ?? "world") }
    }
}

let graph = try await Wire.bootstrap()
let router = Router(context: BasicRequestContext.self)   // the app picks its context
WireHummingbird.apply(graph, to: router)                 // applies collated routes
let app = Application(router: router)
```

`@HummingbirdRoute("path")` does two things: it **aliases `@Contributes(to:
HummingbirdKeys.routes)`** (so `@Singleton @HummingbirdRoute` is all a controller
needs), and it generates the `HummingbirdRouteContributor` conformance — owning the
mount (`router.group("path")`; no argument mounts at the root) and delegating to your
untouched `addRoutes`.

Status: **M2 slice** — the context-free `HummingbirdRouteContributor` surface with the
`@HummingbirdRoute` macro. Controllers that need typed request-scoped state (auth via
`context.identity`) belong in WireMVC, not here.

Depends on pushed `swift-wire` main. Run the end-to-end example:

```
swift run WireHummingbirdExample
```
