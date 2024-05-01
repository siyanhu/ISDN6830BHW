//
//  Response.swift
//  CBOnline
//
//  Created by HU Siyan on 24/4/2024.
//

import Foundation

typealias ImageUploadResult = Result<Response, ResponseError>

typealias Parameters = [String: Any]

struct Response {

    let statusCode: Int
    let body: Parameters?

    init(from data: Data, statusCode: Int) throws {
        self.statusCode = statusCode
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? Parameters
        self.body = jsonObject
    }
}

struct ResponseError: Error {

    let statusCode: Int
    let error: AnyError
}
