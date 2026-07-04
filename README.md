# WireHummingbird

A [swift-wire](https://github.com/tachyonics/swift-wire) adapter for
[Hummingbird](https://github.com/hummingbird-project/hummingbird).

Controllers are ordinary Wire bindings that `@Contributes` their routes into a
collation key; Wire emits a `HummingbirdComposable` conformance on the generated
graph (knowing nothing about HTTP), and `WireHummingbird.apply` applies the
collated routes to a `Router` that stays **outside** the graph:

```swift
@Singleton
@Contributes(to: HummingbirdKeys.routes)
struct HelloController: RouteContributor {
    typealias Context = BasicRequestContext
    @Inject init(greeter: Greeter) { self.greeter = greeter }
    func addRoutes(to router: some RouterMethods<BasicRequestContext>) {
        router.get("hello/:name") { _, ctx in greeter.greeting(ctx.parameters.get("name") ?? "world") }
    }
}

let graph = try await Wire.bootstrap()
let router = Router(context: BasicRequestContext.self)
WireHummingbird.apply(graph, to: router)          // applies collated routes
let app = Application(router: router)
```

Status: **M2.2 slice** — the "instance is the contributor" path with raw
annotations. `@HummingbirdRoute` (a `@Contributes` alias) and the proxy path for
signature-mismatched controllers come with swift-wire's M2.3 contribution contract.

Depends on pushed `swift-wire` main. Run the end-to-end example:

```
swift run WireHummingbirdExample
```
