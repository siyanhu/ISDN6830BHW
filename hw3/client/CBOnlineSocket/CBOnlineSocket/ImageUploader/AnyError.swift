//
//  AnyError.swift
//  CBOnline
//
//  Created by HU Siyan on 24/4/2024.
//

import Foundation

struct AnyError: Error {

    let error: Error

    init(_ error: Error) {
        self.error = error
    }
}
