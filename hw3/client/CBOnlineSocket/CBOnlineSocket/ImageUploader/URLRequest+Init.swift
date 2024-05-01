//
//  URLRequest+Init.swift
//  CBOnline
//
//  Created by HU Siyan on 24/4/2024.
//

import Foundation

extension URLRequest {

    init(url: URL, method: String, headers: HTTPHeaders?) {
        self.init(url: url)
        httpMethod = method

        if let headers = headers {
            headers.forEach {
                setValue($0.1, forHTTPHeaderField: $0.0)
            }
        }
    }
}
