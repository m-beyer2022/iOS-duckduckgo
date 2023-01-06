//
//  DuckMailSharingPanel.swift
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

import SwiftUI
import UIKit
import CoreImage
import BrowserServicesKit
import DuckUI

class DuckMailSharingPanel {

    static func presentOver(_ controller: UIViewController) {
        let emailManager = EmailManager()
        let requestDelegate = EmailAPIRequestDelegate()
        emailManager.requestDelegate = requestDelegate

        let model = PanelModel()

        var panel: UIHostingController<Panel>?
        panel = UIHostingController(rootView: Panel(model: model) {

        } dismiss: {
            panel?.dismiss(animated: true)
        })
        controller.modalPresentationStyle = .overFullScreen
        controller.present(panel!, animated: true)

        emailManager.getAliasIfNeededAndConsume { alias, _ in
            guard let alias = alias else {
                panel?.dismiss(animated: true)
                return
            }

            Task { @MainActor in
                model.email = emailManager.emailAddressFor(alias)
            }
        }

    }

}

private class PanelModel: ObservableObject {

    @Published var email: String?

    init(email: String? = nil) {
        self.email = email
    }

    func copy() {
        guard let email = email else { return }
        let pasteBoard = UIPasteboard.general
        pasteBoard.string = email
    }

}

private struct Panel: View {

    @StateObject var model: PanelModel

    @Environment(\.verticalSizeClass) var verticalSizeClass

    let share: () -> Void
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Header(dismiss: dismiss)

            Spacer()

            if let email = model.email {

                let emailView = Text(email)
                    .lineLimit(1)
                    .font(.largeTitle.weight(.semibold))
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal)

                let qrcodeView = QRCode(string: email)

                if verticalSizeClass == .compact {
                    HStack {
                        emailView
                        qrcodeView
                    }
                }

                if verticalSizeClass == .regular {
                    VStack {
                        emailView
                        Spacer()
                        qrcodeView
                            .background(Rectangle())
                        Spacer()
                    }
                    .padding(.top, 64)
                }

            } else {

                SwiftUI.ProgressView()

            }


            if model.email != nil {
                let shareButton = Button {
                    share()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(SecondaryButtonStyle())

                let copyAndCloseButton = Button {
                    model.copy()
                    dismiss()
                } label: {
                    Text("Copy and Close")
                }
                .buttonStyle(PrimaryButtonStyle())

                if verticalSizeClass == .compact {

                    HStack {
                        copyAndCloseButton
                        shareButton
                    }

                } else {

                    shareButton
                    copyAndCloseButton

                }

            }
        }
        .padding()
    }

}

struct Header: View {

    let dismiss: () -> Void

    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                Image("LogoPanel")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200)
                    .offset(y: 24)

                Text("Email by")
                    .font(.caption)
                    .offset(x: 64)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .fontWeight(.bold)
            }
        }
    }

}

struct QRCode: View {

    let context = CIContext()

    let string: String

    var body: some View {
        Image(uiImage: generateQRCode(from: string))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: 200)
    }

    func generateQRCode(from text: String) -> UIImage {
        var qrImage = UIImage(systemName: "xmark.circle") ?? UIImage()
        let data = Data(text.utf8)
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")

        let transform = CGAffineTransform(scaleX: 20, y: 20)
        if let outputImage = filter.outputImage?.transformed(by: transform) {
            if let image = context.createCGImage(
                outputImage,
                from: outputImage.extent) {
                qrImage = UIImage(cgImage: image)
            }
        }
        return qrImage
    }

}

extension CIFilter {

    static func qrCodeGenerator() -> CIFilter {
        CIFilter(name: "CIQRCodeGenerator", parameters: [
            "inputCorrectionLevel": "H"
        ])!
    }

}

struct Panel_Previews: PreviewProvider {
    static var previews: some View {
        Panel(model: PanelModel(email: "666123@duck.com")) {
        } dismiss: {
        }

        Panel(model: PanelModel()) {
        } dismiss: {
        }
    }
}
