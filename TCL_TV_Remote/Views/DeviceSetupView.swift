//
//  DeviceSetupView.swift
//  TCL_TV_Remote
//

import SwiftUI

struct DeviceSetupView: View {
    @Bindable var viewModel: RemoteViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if viewModel.discovery.isSearching {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Searching your Wi-Fi network…")
                        }
                    }
                    Text(viewModel.discovery.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Discovered TVs") {
                    if viewModel.discovery.devices.isEmpty {
                        Text(viewModel.discovery.isSearching ? "Looking for your TV…" : "Nothing found yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.discovery.devices) { device in
                            Button {
                                viewModel.connect(to: device)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(device.name)
                                        .font(.headline)
                                    Text(device.host)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section {
                    Text("Manual IP (recommended if discovery is empty)")
                        .font(.headline)
                    TextField("192.168.1.91", text: $viewModel.manualIP)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button("Connect with IP") {
                        viewModel.connectManualIP()
                    }
                    .disabled(viewModel.manualIP.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("Tips") {
                    Label("Same Wi-Fi for iPhone and TV", systemImage: "wifi")
                    Label("TV IP: Settings → Network on the TV", systemImage: "tv")
                    Label("Allow Local Network for this app in iPhone Settings", systemImage: "hand.raised")
                    Label("Discovery often fails on real iPhones — Manual IP still works", systemImage: "info.circle")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .navigationTitle("Connect TV")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        viewModel.showSetup = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.discovery.isSearching ? "Stop" : "Search") {
                        if viewModel.discovery.isSearching {
                            viewModel.stopDiscovery()
                        } else {
                            viewModel.startDiscovery()
                        }
                    }
                }
            }
            .onAppear {
                viewModel.startDiscovery()
            }
            .onDisappear {
                viewModel.stopDiscovery()
            }
        }
    }
}
