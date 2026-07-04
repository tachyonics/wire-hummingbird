import Hummingbird
import HummingbirdTesting
import WireHummingbird

// End-to-end: build the app-scoped graph, apply its collated routes to a
// user-owned router (which stays *outside* the graph), construct the Application,
// and serve a request in-process. `Wire.bootstrap()` returns the concrete graph,
// which conforms to `HummingbirdComposable` via the plugin-generated extension, so
// it feeds `WireHummingbird.apply` directly.
let graph = try await Wire.bootstrap()

let router = Router(context: BasicRequestContext.self)
WireHummingbird.apply(graph, to: router)

let app = Application(router: router)

try await app.test(.router) { client in
    let body = try await client.execute(uri: "/hello/Ada", method: .get) { response in
        String(buffer: response.body)
    }
    precondition(body == "Hello, Ada!", "hello route failed: \(body)")
    print(
        "wire-hummingbird OK — @Singleton @Contributes controller (injected Greeter) served via Wire.bootstrap() + WireHummingbird.apply"
    )
}
