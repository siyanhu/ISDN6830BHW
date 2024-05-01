//
//  ImageUploader.swift
//  CBOnline
//
//  Created by HU Siyan on 24/4/2024.
//

import Foundation
import UIKit

typealias HTTPHeaders = [String: String]

final class ImageUploader {

    let uploadImage: UIImage
    let number: Int
    let boundary = "example.boundary.\(ProcessInfo.processInfo.globallyUniqueString)"
    let fieldName = "cache"
    let endpointURI = URL(string: "http://143.89.144.130:2333/cache")

    var parameters: Parameters? {
        return [
            "number": number
        ]
    }
    var headers: HTTPHeaders {
        return [
            "Content-Type": "multipart/form-data",
        ]
    }

    init(uploadImage: UIImage, number: Int) {
        self.uploadImage = uploadImage
        self.number = number
    }
    
    func uploadImage(completionHandler: @escaping (ImageUploadResult) -> Void) {
        print(endpointURI!)
        let imageData = self.uploadImage.jpegData(compressionQuality: 1)!
        let mimeType = imageData.mimeType!

        var request = URLRequest(url: endpointURI!, method: "POST", headers: headers)
        
        let imageBase64 = imageData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        var encodeImg = imageBase64.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        encodeImg = encodeImg! + String("%")
        
        request.httpBody = imageData
//        createHttpBody(binaryData: imageData, mimeType: mimeType)
//        request.httpBody = imageData
        
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { (data, urlResponse, error) in
            let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode ?? 0
            if let data = data, case (200..<300) = statusCode {
                do {
                    let value = try Response(from: data, statusCode: statusCode)
                    completionHandler(.success(value))
                } catch {
                    let _error = ResponseError(statusCode: statusCode, error: AnyError(error))
                    completionHandler(.failure(_error))
                }
            }
            let tmpError = error ?? NSError(domain: "Unknown", code: 499, userInfo: nil)
            let _error = ResponseError(statusCode: statusCode, error: AnyError(error ?? tmpError))
            completionHandler(.failure(_error))
        }
        task.resume()
    }
    
    private func createHttpBody(binaryData: Data, mimeType: String) -> Data {
        var postContent = "--\(boundary)\r\n"
        let fileName = "\(UUID().uuidString).jpeg"
        postContent += "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n"
        postContent += "Content-Type: \(mimeType)\r\n\r\n"
        
        let imageBase64 = binaryData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        var encodeImg = imageBase64.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        encodeImg = encodeImg! + String("%")
        
        var data = Data()
//        guard let postData = postContent.data(using: .utf8) else { return data }
//        data.append(postData)


        if let parameters = parameters {
            var content = ""
            parameters.forEach {
                content += "\r\n--\(boundary)\r\n"
                content += "Content-Disposition: form-data; name=\"\($0.key)\"\r\n\r\n"
                content += "\($0.value)"
            }
        }


        guard let endData = "\r\n--\(boundary)--\r\n".data(using: .utf8) else { return data }
//        data.append(endData)
        return data
    }
}
