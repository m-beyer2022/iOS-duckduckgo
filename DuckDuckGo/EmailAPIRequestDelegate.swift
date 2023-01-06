//
//  EmailAPIRequestDelegate.swift
//  DuckDuckGo
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import BrowserServicesKit
import Core

class EmailAPIRequestDelegate: EmailManagerRequestDelegate {

    // swiftlint:disable function_parameter_count
    func emailManager(_ emailManager: EmailManager,
                      requested url: URL,
                      method: String,
                      headers: [String: String],
                      parameters: [String: String]?,
                      httpBody: Data?,
                      timeoutInterval: TimeInterval,
                      completion: @escaping (Data?, Error?) -> Void) {
        APIRequest.request(url: url,
                           method: APIRequest.HTTPMethod(rawValue: method) ?? .post,
                           parameters: parameters ?? [:],
                           headers: headers,
                           httpBody: httpBody,
                           timeoutInterval: timeoutInterval) { response, error in

            completion(response?.data, error)

            DispatchQueue.main.async {
                UIApplication.shared.updateDuckMailShortcut(emailManager: emailManager)
            }

        }
    }
    // swiftlint:enable function_parameter_count

    func emailManagerKeychainAccessFailed(accessType: EmailKeychainAccessType, error: EmailKeychainAccessError) {
        var parameters = [
            PixelParameters.emailKeychainAccessType: accessType.rawValue,
            PixelParameters.emailKeychainError: error.errorDescription
        ]

        if case let .keychainLookupFailure(status) = error {
            parameters[PixelParameters.emailKeychainKeychainStatus] = String(status)
            parameters[PixelParameters.emailKeychainKeychainOperation] = "lookup"
        }

        if case let .keychainDeleteFailure(status) = error {
            parameters[PixelParameters.emailKeychainKeychainStatus] = String(status)
            parameters[PixelParameters.emailKeychainKeychainOperation] = "delete"
        }

        if case let .keychainSaveFailure(status) = error {
            parameters[PixelParameters.emailKeychainKeychainStatus] = String(status)
            parameters[PixelParameters.emailKeychainKeychainOperation] = "save"
        }

        Pixel.fire(pixel: .emailAutofillKeychainError, withAdditionalParameters: parameters)
    }

}
