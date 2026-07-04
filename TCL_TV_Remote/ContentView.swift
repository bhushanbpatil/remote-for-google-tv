//
//  ContentView.swift
//  TCL_TV_Remote
//

import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = RemoteViewModel()

    var body: some View {
        NavigationStack {
            RemoteView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showSetup) {
            DeviceSetupView(viewModel: viewModel)
        }
        .onAppear {
            ClientCertificateStore.prepareCertificates()
            viewModel.ensureIdleOnLaunch()
            if viewModel.savedDevice == nil {
                viewModel.showSetup = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .inactive:
                viewModel.onEnterInactive()
            case .background:
                viewModel.onEnterBackground()
            case .active:
                viewModel.onBecomeActive()
            @unknown default:
                break
            }
        }
        // scenePhase alone is unreliable for app-switcher resume; UIKit notifications
        // are a backup so we always tear down when leaving / returning.
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            viewModel.onEnterBackground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.onBecomeActive()
        }
    }
}

#Preview {
    ContentView()
}
