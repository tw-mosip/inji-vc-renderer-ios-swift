import Foundation

class NetworkManager: NetworkManagerProtocol {


    func fetchSvgAsText(url: String, traceabilityId: String) throws -> String {
        guard let url = URL(string: url) else {
            throw VcRendererException(
                errorCode: VcRendererErrorCodes.svgFetchError,
                message: "Invalid URL: \(url)",
                className: String(describing: NetworkManager.self),
                traceabilityId: traceabilityId
            )
        }

        var result: String?
        var fetchError: VcRendererException?

        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { semaphore.signal() }

            if let error = error {
                fetchError = VcRendererException(
                    errorCode: VcRendererErrorCodes.svgFetchError,
                    message: "Network error: \(error.localizedDescription)",
                    className: String(describing: NetworkManager.self),
                    traceabilityId: traceabilityId
                )
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                fetchError = VcRendererException(
                    errorCode: VcRendererErrorCodes.svgFetchError,
                    message: "Invalid HTTP response",
                    className: String(describing: NetworkManager.self),
                    traceabilityId: traceabilityId
                )
                return
            }

            guard httpResponse.statusCode == 200 else {
                fetchError = VcRendererException(
                    errorCode: VcRendererErrorCodes.svgFetchError,
                    message: "Unexpected response code: \(httpResponse.statusCode)",
                    className: String(describing: NetworkManager.self),
                    traceabilityId: traceabilityId
                )
                return
            }

            guard let mimeType = httpResponse.mimeType, mimeType == NetworkConstants.CONTENT_TYPE_SVG  else {
                fetchError = VcRendererException(
                    errorCode: VcRendererErrorCodes.svgFetchError,
                    message: "Expected image/svg+xml but got: \(httpResponse.mimeType ?? "unknown")",
                    className: String(describing: NetworkManager.self),
                    traceabilityId: traceabilityId
                )
                return
            }

            if let data = data, let text = String(data: data, encoding: .utf8) {
                result = text
            } else {
                fetchError = VcRendererException(
                    errorCode: VcRendererErrorCodes.svgFetchError,
                    message: "Empty response body",
                    className: String(describing: NetworkManager.self),
                    traceabilityId: traceabilityId
                )
            }
        }

        task.resume()
        semaphore.wait()

        if let error = fetchError {
            throw error
        }

        guard let svg = result else {
            throw VcRendererException(
                errorCode: VcRendererErrorCodes.svgFetchError,
                message: "Failed to fetch SVG for unknown reasons",
                className: String(describing: NetworkManager.self),
                traceabilityId: traceabilityId
            )
        }

        return svg
    }
}

protocol NetworkManagerProtocol {
    func fetchSvgAsText(url: String, traceabilityId: String) throws -> String
}
