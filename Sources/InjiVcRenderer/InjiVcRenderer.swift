import Foundation

public class InjiVcRenderer {
    
    private let traceabilityId: String
    
    public init(traceabilityId: String) {
        self.traceabilityId = traceabilityId
    }
    /**
     Renders SVG templates defined in the VC's renderMethod section.
     Supports fetching templates from URLs and data URIs.
     Replaces placeholders in the templates with values from the VC JSON.

     - Parameter vcJsonString: The Verifiable Credential as a JSON string.
     - Returns: A list of rendered SVG strings. Empty list if no valid render methods found or on error.  Return is List<Any> to accommodate future extensions.
     */
    public func renderVC(vcJsonString: String) throws -> [Any] {
        let vcJsonObject = try parseVcJson(vcJsonString: vcJsonString)

        let renderMethodArray = try Utils.parseRenderMethod(vcJsonObject, traceabilityId: traceabilityId)
        
        var results: [String] = []

        for case let renderMethod in renderMethodArray {
            let svgTemplate = try Utils.extractSvgTemplate(renderMethod: renderMethod, vcJsonString: vcJsonString, traceabilityId: traceabilityId)
                   
                   let renderProperties = (renderMethod[Constants.TEMPLATE] as? [String: Any])?[Constants.RENDER_PROPERTY] as? [String]
                   
                   let renderedSvg = try JsonPointerResolver.replacePlaceholders(
                       svgTemplate: svgTemplate,
                       vcJson: vcJsonObject,
                       renderProperties: renderProperties,
                       traceabilityId: traceabilityId
                   )
                   
                   results.append(renderedSvg)
               }
               
               return results
       }
    
    private func parseVcJson(vcJsonString: String) throws -> [String: Any] {
        do {
            guard let data = vcJsonString.data(using: .utf8) else {
                throw VcRendererException(
                    errorCode: VcRendererErrorCodes.invalidRenderMethod,
                    message: "Invalid JSON input (data encoding failed)",
                    className: String(describing: InjiVcRenderer.self),
                    traceabilityId: traceabilityId
                )
            }
            
            guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw VcRendererException(
                    errorCode: VcRendererErrorCodes.invalidRenderMethod,
                    message: "Invalid JSON input (not a dictionary)",
                    className: String(describing: InjiVcRenderer.self),
                    traceabilityId: traceabilityId
                )
            }
            
            return parsed
        } catch {
            throw VcRendererException(
                errorCode: VcRendererErrorCodes.invalidRenderMethod,
                message: "Invalid JSON input (\(error.localizedDescription))",
                className: String(describing: InjiVcRenderer.self),
                traceabilityId: traceabilityId
            )
        }
    }
   }
