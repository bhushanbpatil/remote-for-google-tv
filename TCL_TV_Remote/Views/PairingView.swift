//
//  PairingView.swift
//  TCL_TV_Remote
//

import SwiftUI

struct PairingView: View {
    @Bindable var viewModel: RemoteViewModel

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv.and.mediabox")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Pair with Your TV")
                .font(.title2.bold())

            Text("A 6-character code is shown on your Google TV. Enter it below.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("A1B2C3", text: $viewModel.pairingCode)
                .font(.title.monospaced())
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

            Button("Submit Code") {
                viewModel.submitPairingCode()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.pairingCode.count != 6)

            Text(viewModel.statusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
