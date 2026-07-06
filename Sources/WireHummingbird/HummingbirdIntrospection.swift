import Hummingbird
import Wire

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// The introspection feature: a mountable endpoint serving the graph's WiringModel as
// JSON. The app computes `graph.introspect()` in its own module and mounts this where
// it wants — behind its own auth — since the model exposes the DI graph.
extension WireHummingbird {
    /// Mount a GET endpoint on `router` serving `model` as JSON. Mount it on a group
    /// the app controls (e.g. an authed `router.group("admin")`), so the wiring the
    /// model exposes isn't public by default; the endpoint sits at the router's root,
    /// so the group's path is the endpoint's path.
    public static func mountIntrospection<Context: RequestContext>(
        _ model: WiringModel,
        on router: some RouterMethods<Context>
    ) {
        router.get { _, _ in
            let data = try JSONEncoder().encode(model)
            var buffer = ByteBuffer()
            buffer.writeBytes(data)
            return Response(
                status: .ok,
                headers: [.contentType: "application/json"],
                body: ResponseBody(byteBuffer: buffer)
            )
        }
    }
}
