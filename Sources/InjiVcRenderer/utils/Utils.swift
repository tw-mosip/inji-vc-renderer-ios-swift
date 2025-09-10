import Foundation
class Utils {
    static var networkHandler: NetworkManagerProtocol = NetworkManager() as NetworkManagerProtocol
    static var qrCodeGenerator: QrCodeGeneratorProtocol = QrCodeGenerator() as QrCodeGeneratorProtocol

    public static let className = String(describing: Utils.self)
    
    

    /// Extracts an SVG template after validation and QR injection
    static func extractSvgTemplate(renderMethod: [String: Any],
                                   vcJsonString: String,
                                   traceabilityId: String) throws -> String {

        try ensureSvgMustacheRenderSuite(renderMethod: renderMethod, traceabilityId: traceabilityId)
        try ensureTemplateRenderMethodType(renderMethod: renderMethod, traceabilityId: traceabilityId)

        guard let templateValue = renderMethod[Constants.TEMPLATE] as? [String: Any] else {
            throw InvalidRenderMethodTypeException(traceabilityId: traceabilityId, className: className)
        }

        guard let templateId = templateValue[Constants.ID] as? String else {
            throw MissingTemplateIdException(traceabilityId: traceabilityId, className: className)
        }

        var rawSvg: String
           do {
               rawSvg = try networkHandler.fetchSvgAsText(url: templateId, traceabilityId: traceabilityId)
           } catch {
               throw SvgFetchException(traceabilityId: traceabilityId, className: className, exceptionMessage: error.localizedDescription)
           }

        rawSvg = try injectQrCodeIfNeeded(svg: rawSvg, vcJsonString: vcJsonString, traceabilityId: traceabilityId)
        return rawSvg
    }
    
    private static func injectQrCodeIfNeeded(
        svg: String,
        vcJsonString: String,
        traceabilityId: String
    ) throws -> String {
        guard svg.contains(Constants.QR_CODE_PLACEHOLDER) else {
            return svg
        }

        do {
            let qrBase64 = try qrCodeGenerator.generateQRCodeImage(vcJson: vcJsonString, traceabilityId: traceabilityId)
            let qrImageTag = "\(Constants.QR_IMAGE_PREFIX),\(qrBase64)"
            return svg.replacingOccurrences(of: Constants.QR_CODE_PLACEHOLDER, with: qrImageTag)
        } catch {
            let fallbackBase64 = Constants.FALLBACK_QR_CODE
            let qrImageTag = "\(Constants.QR_IMAGE_PREFIX),\(fallbackBase64)"
            return svg.replacingOccurrences(of: Constants.QR_CODE_PLACEHOLDER, with: qrImageTag)
        }
    }


    /// Ensures render suite is SVG Mustache
    static func ensureSvgMustacheRenderSuite(renderMethod: [String: Any],
                                             traceabilityId: String) throws {
        let renderSuite = renderMethod[Constants.RENDER_SUITE] as? String ?? ""
        if renderSuite != Constants.SVG_MUSTACHE {
            throw InvalidRenderSuiteException(traceabilityId: traceabilityId, className: className)
        }
    }

    /// Ensures render method type is Template
    static func ensureTemplateRenderMethodType(renderMethod: [String: Any],
                                               traceabilityId: String) throws {
        let type = renderMethod[Constants.TYPE] as? String ?? ""
        if type != Constants.TEMPLATE_RENDER_METHOD {
            throw InvalidRenderMethodTypeException(traceabilityId: traceabilityId, className: className)
        }
    }

    static func parseRenderMethod(_ jsonObject: [String: Any],
                                  traceabilityId: String) throws -> [[String: Any]] {
        guard let renderMethodValue = jsonObject[Constants.RENDER_METHOD] else {
            throw InvalidRenderMethodException(traceabilityId: traceabilityId, className: className)
        }

        if let array = renderMethodValue as? [[String: Any]] {
            if array.isEmpty || array.contains(where: { $0.isEmpty }) {
                throw InvalidRenderMethodException(traceabilityId: traceabilityId, className: className)
            }
            return array
        } else if let dict = renderMethodValue as? [String: Any] {
            if dict.isEmpty {
                throw InvalidRenderMethodException(traceabilityId: traceabilityId, className: className)
            }
            return [dict]
        } else {
            throw InvalidRenderMethodException(traceabilityId: traceabilityId, className: className)
        }
    }
}


