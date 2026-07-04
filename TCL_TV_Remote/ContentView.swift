//
//  ContentView.swift
//  TCL_TV_Remote
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = RemoteViewModel()
    @State private var hasBeenBackgrounded = false

    var body: some View {
        NavigationStack {
            RemoteView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showSetup) {
            DeviceSetupView(viewModel: viewModel)
        }
        .onAppear {
            ClientCertificateStore.prepareCertificates()
            if viewModel.savedDevice == nil {
                viewModel.showSetup = true
            }
            viewModel.onAppear()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                hasBeenBackgrounded = true
            }
            if newPhase == .active, hasBeenBackgrounded {
                viewModel.onReturnToForeground()
            }
        }
    }
}

#Preview {
    ContentView()
}
