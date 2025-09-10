## InjiVcRenderer - Swift Library
- A Swift library to convert SVG Template to SVG Image by replacing the placeholders in the SVG Template with actual Verifiable Credential Json Data. Strictly follows JSON Pointer Algorithm RFC6901 to extract the values from the VC.

## Installation
To include InjiVcRenderer in your Swift project:

- Create a new Swift project.
- Add package dependency: Enter Package URL of InjiVcRenderer repo

### API
- `renderVC(vcJsonString: String): [Any]` - expects the Verifiable Credential as parameter and returns the replaced SVG Template.
    - `vcJsonData` - VC Downloaded in stringified format.
- This method takes entire VC data as input.
- Example :
```
        let vcJson = """{
            "credentialSubject": {
                "fullName": "John",
                "gender": [
                    "language": "eng",
                    "value": "Male"
                ] 
            },
            "renderMethod": {
                    "type": "TemplateRenderMethod",
                    "renderSuite": "svg-mustache",
                      "template": {
                        "id": "https://degree.example/credential-templates/sample.svg",
                        "mediaType": "image/svg+xml",
                        "digestMultibase": "zQmerWC85Wg6wFl9znFCwYxApG270iEu5h6JqWAPdhyxz2dR"
                      }
                  }
              }
        }"""
        // Assume SVG Template hosted is "<svg>{{/credentialSubject/gender}}##{{/credentialSubject/fullName}}</svg>"
    Result will be => [<svg>Male##John</svg>]
```
- Returns the Replaced svg template to render proper SVG Image. It returns the list of SVG Template if multiple render methods are present in the VC.

## Package Structure

```
Sources
├── InjiVcRenderer.swift              # Main library class with public API
├── constants/         # Constants used across the library
│   ├── Constants.swift   
│   ├── NetworkConstants.swift      
│   └── VcRendererErrorCodes.swift #Error codes used for Custom Exceptions              
│   |
├── exceptions/        # Exceptions
│   ├── VcRendererExceptions.swift  # Centralized exception definitions
│   │
│── qrCode/          
│   │   ├── QRCodeGenerator.swift  # QR code generation utility
│── templateEngine/svg/        # Json Pointer Algorithm implementation
    |--JsonPointerResolver.swift    
├── utils      # Utility classes
|    ├── Utils.kt               # SVG related utilities
├── networkManager      
|   ├── NetworkManager.kt       # Network related utilities
```

###### Exceptions

1. InvalidRenderSuiteException is thrown if render suite is not `svg-mustache`
2. InvalidRenderMethodTypeException is thrown if render method type is not `TemplateRenderMethod`
3. QRCodeGenerationFailureException is thrown if QR code generation fails
4. MissingTemplateIdException is thrown if template id is missing in render method
5. SvgFetchException is thrown if fetching SVG from the URL fails
6. InvalidRenderMethodException is thrown if render method object is invalid

### Steps involved in SVG Template to SVG Image Conversion
- Render Method Extraction from VC
  - Extracts the render method from the VC Json data.
  - If multiple render methods are present, it will process all the render methods and return the list of replaced SVG Templates.


#### Downloading SVG Template from URL in VC
  - If Render Method object has `template` field as object with `id` field as url and `mediaType` as `image/svg+xml`, SVG Template needs to be downloaded from the URL and then replace the placeholders.
      ```
          "renderMethod": {
          "type": "TemplateRenderMethod",
          "renderSuite": "svg-mustache",
          "template": {
                  "id": "https://degree.example/credential-templates/bachelors",
                  "mediaType": "image/svg+xml",
                  "digestMultibase": "zQmerWC85Wg6wFl9znFCwYxApG270iEu5h6JqWAPdhyxz2dR"
              }
          }
      ```
  - Render method type should be `TemplateRenderMethod` and render suite should be `svg-mustache`.
  - Note : Embedded SVG Template and hosting render method as jsonld document are not supported in this library. Hosting the SVG Template as URL is supported.


#### Preprocessing the SVG Template

##### QR Code Placeholder
  - If the SVG Template has `{{/qrCodeImage}}` placeholder, it will generate the QR code using Pixelpass library and replace the placeholder with generated QR code image in base64 format.
    - Example:
        ```
        let vcJson = {"credentialSubject" : "id": "did:example:123456789", "name": "Tester"}
        
        let svgTempalte = "<svg>{{/qrCodeImage}}</svg>"
        
        //result => <svg><image id = "qrCodeImage" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMgAAADICAYAAACtWK6eAAAABmJLR0QA/wD/AP+gvaeTAAAIKklEQVR4nO3de5QdZZnv8e9M7MzMzM7szszM7s"
        ```
- Note: It is mandatory to have `id` field in the `<image>` as `qrCodeImage` and placeholder as `{{/qrCodeImage}}` to generate the QR code.

##### Handling Render Property
  - If the `template` field is an object and has `renderMethod` property. Property in the `renderMethod` will be taken into consideration for further processing and rest of the fields placeholders will be replaced with empty string.
    - Example:
        ```
          "renderMethod": {
              "type": "TemplateRenderMethod",
              "renderSuite": "svg-mustache",
              "template": {
                      "id": "https://example.edu/credential-templates/BachelorDegree",
                      "mediaType": "image/svg+xml",
                      "digestMultibase": "zQmerWC85Wg6wFl9znFCwYxApG270iEu5h6JqWAPdhyxz2dR",
                      "renderProperty": [
                        "/issuer", "/validFrom", "/credentialSubject/degree/name"
                      ]
                  }
          }
        ```
    - In the above example, only the fields `issuer`, `validFrom` and `credentialSubject/degree/name` will be considered for replacing the placeholders in the SVG Template.
  - If `renderProperty` is not present, all the fields in the VC will be considered for replacing the placeholders in the SVG Template.

##### Array Fields Handling
- For array fields in the VC, index based approach will be followed.
- Example:
    ```
    let vcJson = {"credentialSubject" : "benefits": ["Critical Surgery", "Full Health Checkup", "Testing"]}
    
    let svgTempalte = "<svg>{{/benefits}}</svg>"
    
    //result => <svg><text><tspan>Critical Surgery, Full</tspan><tspan>Health Checkup, Testing</tspan></text></svg>
    ```
- Example for array of objects:
    ```
    val vcJson = {      "credentialSubject": {          "awards": [              {"title": "Award1", "year": "2020"},              {"title": "Award2", "year": "2021"}          ]      }  }
    
    val svgTemplate = "<svg>{{/credentialSubject/awards/0/title}} - {{/credentialSubject/awards/0/year}}, {{/credentialSubject/awards/1/title}} - {{/credentialSubject/awards/1/year}}</svg>"
    
    //result => <svg>Award1 - 2020, Award2 - 2021</svg>
    ```
    
    
##### Locale Handling
- For locale handling, same JSON Pointer Algorithm is used to extract the value from the VC.
- Example:
    ```
    let vcJson = {      "credentialSubject": { "fullName": "Tester", "city": [{"value": "TestCITY", "language": "eng"},{"value": "VilleTest", "language": "fr"}]}
          
      let svgTempalte = "<svg>{{/credentialSubject/fullName}} - {{/credentialSubject/city}}</svg>"
          
      //result => <svg>Tester - TestCITY</svg>
  ```


#### Replacing Placeholders in SVG Template
- Replaces the placeholders in the SVG Template with actual VC Json Data strictly follows JSON Pointer Algorithm RFC6901.
- Returns the list of replaced SVG Templates if multiple render methods are present in the VC.


### References
- [JSON Pointer Algorithm - RFC6901](https://www.rfc-editor.org/rfc/rfc6901)
- [Draft Implementation of Verifiable Credential Rendering Methods](https://w3c-ccg.github.io/vc-render-method/#the-rendermethod-property)
- [Data model 2.0 implementation](https://www.w3.org/TR/vc-data-model-2.0/#reserved-extension-points)
