//
//  RemoteView.swift
//  TCL_TV_Remote
//

import SwiftUI

struct RemoteView: View {
    @Bindable var viewModel: RemoteViewModel
    @State private var isStatusExpanded = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statusHeader

                if viewModel.needsPairingCode {
                    PairingView(viewModel: viewModel)
                } else {
                    remoteControls
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("TV") {
                    viewModel.showSetup = true
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Reconnect") { viewModel.reconnect() }
                    Button("Forget TV", role: .destructive) { viewModel.forgetTV() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onChange(of: viewModel.isConnected) { _, connected in
            if connected {
                isStatusExpanded = false
            }
        }
        .onChange(of: viewModel.phase) { _, phase in
            if case .error = phase {
                isStatusExpanded = true
            }
        }
    }

    private var statusHeader: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.snappy) {
                    isStatusExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.isConnected ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)

                    Text(statusTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)

                    if viewModel.isConnected, let device = viewModel.savedDevice, !isStatusExpanded {
                        Text("· \(device.host)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: isStatusExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isStatusExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    if let device = viewModel.savedDevice {
                        Text(device.name)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(device.host)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let app = viewModel.currentApp, !app.isEmpty {
                        Text("Running: \(friendlyAppName(app))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !viewModel.statusMessage.isEmpty {
                        Text(viewModel.statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusTitle: String {
        if viewModel.isConnected { return "Connected" }
        switch viewModel.phase {
        case .connecting: return "Connecting…"
        case .needsPairing, .waitingForCode: return "Pairing…"
        case .error: return "Error"
        default: return "Not connected"
        }
    }

    private func friendlyAppName(_ bundleID: String) -> String {
        switch bundleID {
        case let id where id.contains("youtube"): return "YouTube"
        case let id where id.contains("netflix"): return "Netflix"
        case let id where id.contains("disney"): return "Disney+"
        case let id where id.contains("amazon"): return "Prime Video"
        case let id where id.contains("apple"): return "Apple TV"
        case let id where id.contains("wbd"): return "HBO Max"
        case let id where id.contains("hulu"): return "Hulu"
        case let id where id.contains("espn"): return "ESPN"
        case let id where id.contains("sling"): return "Sling"
        case let id where id.contains("foxone") || id.contains("fox.fox"): return "Fox One"
        default: return bundleID.split(separator: ".").last.map(String.init) ?? bundleID
        }
    }

    private var remoteControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                RemoteButton(title: "Home", systemImage: "house.fill", prominent: true) {
                    viewModel.sendKey(.home)
                }
                RemoteButton(title: "Back", systemImage: "arrow.uturn.backward") {
                    viewModel.sendKey(.back)
                }
                RemoteButton(title: "Power", systemImage: "power") {
                    viewModel.sendKey(.power)
                }
            }

            DirectionPad { key in
                viewModel.sendKey(key)
            }

            HStack(spacing: 12) {
                RemoteButton(title: "Vol −", systemImage: "speaker.wave.1.fill") {
                    viewModel.sendKey(.volumeDown)
                }
                RemoteButton(title: "Mute", systemImage: "speaker.slash.fill") {
                    viewModel.sendKey(.volumeMute)
                }
                RemoteButton(title: "Vol +", systemImage: "speaker.wave.3.fill") {
                    viewModel.sendKey(.volumeUp)
                }
            }

            actionSection(title: "Playback", actions: [
                RemoteAction(id: "prev", title: "Previous", systemImage: "backward.end.fill", key: .mediaPrevious),
                RemoteAction(id: "play", title: "Play/Pause", systemImage: "playpause.fill", key: .mediaPlayPause),
                RemoteAction(id: "next", title: "Next", systemImage: "forward.end.fill", key: .mediaNext)
            ])

            actionSection(title: "Google TV", actions: RemoteAction.googleTV)

            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Launch")
                    .font(.headline)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(StreamingApp.defaults) { app in
                        RemoteButton(title: app.name, systemImage: "play.tv.fill") {
                            viewModel.launchApp(app)
                        }
                    }
                }
            }

            if !viewModel.isConnected {
                Button("Connect to TV") {
                    viewModel.showSetup = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func actionSection(title: String, actions: [RemoteAction]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(actions) { action in
                    RemoteButton(title: action.title, systemImage: action.systemImage) {
                        viewModel.sendKey(action.key)
                    }
                }
            }
        }
    }
}
