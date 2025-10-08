import Foundation

class NetworkManager: NetworkManagerProtocol {
    func fetch(url: String, traceabilityId: String) throws -> TemplateResponse {
        guard let url = URL(string: url) else {
            throw VcRendererException(
                errorCode: VcRendererErrorCodes.svgFetchError,
                message: "Invalid URL: \(url)",
                className: String(describing: NetworkManager.self),
                traceabilityId: traceabilityId
            )
        }

        var result: TemplateResponse?
        var fetchError: VcRendererException?

        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { semaphore.signal() }

            if let error = error {
                fetchError = SvgFetchException(
                    traceabilityId: traceabilityId,
                    className: String(describing: NetworkManager.self),
                    exceptionMessage: "Network error: \(error.localizedDescription)"
                )
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                fetchError = SvgFetchException(
                    traceabilityId: traceabilityId,
                    className: String(describing: NetworkManager.self),
                    exceptionMessage: "Invalid HTTP response"
                )
                return
            }

            guard httpResponse.statusCode == 200 else {
                fetchError = SvgFetchException(
                    traceabilityId: traceabilityId,
                    className: String(describing: NetworkManager.self),
                    exceptionMessage: "Unexpected response code: \(httpResponse.statusCode)"
                )
                return
            }

            let mimeType = httpResponse.allHeaderFields["Content-Type"] as? String

            do {
                let contentType = try ContentType.fromType(
                    mimeType: mimeType,
                    traceabilityId: traceabilityId,
                    className: String(describing: NetworkManager.self)
                )

                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""

                result = TemplateResponse(contentType: contentType, body: body)
            } catch let e as VcRendererException {
                fetchError = e
            } catch {
                fetchError = SvgFetchException(
                    traceabilityId: traceabilityId,
                    className: String(describing: NetworkManager.self),
                    exceptionMessage: error.localizedDescription
                )
            }
        }

        task.resume()
        semaphore.wait()

        if let error = fetchError {
            throw error
        }

        guard let templateResponse = result else {
            throw SvgFetchException(
                traceabilityId: traceabilityId,
                className: String(describing: NetworkManager.self),
                exceptionMessage: "Failed to fetch SVG for unknown reasons"
            )
        }

        return templateResponse
    }
}

protocol NetworkManagerProtocol {
    func fetch(url: String, traceabilityId: String) throws -> TemplateResponse
}
