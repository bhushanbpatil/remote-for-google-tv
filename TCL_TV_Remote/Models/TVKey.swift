//
//  TVKey.swift
//  TCL_TV_Remote
//

import Foundation

enum TVKey: UInt {
    case home = 3
    case back = 4
    case dpadUp = 19
    case dpadDown = 20
    case dpadLeft = 21
    case dpadRight = 22
    case dpadCenter = 23
    case volumeUp = 24
    case volumeDown = 25
    case power = 26
    case menu = 82
    case mediaPlayPause = 85
    case mediaStop = 86
    case mediaNext = 87
    case mediaPrevious = 88
    case mediaRewind = 89
    case mediaFastForward = 90
    case info = 165
    case channelUp = 166
    case channelDown = 167
    case guide = 172
    case captions = 175
    case settings = 176
    case tvInput = 178
    case voiceAssist = 231
    case allApps = 284
    case volumeMute = 164
}

struct RemoteAction: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let key: TVKey

    static let googleTV: [RemoteAction] = [
        RemoteAction(id: "settings", title: "Settings", systemImage: "gearshape.fill", key: .settings),
        RemoteAction(id: "input", title: "Input", systemImage: "rectangle.connected.to.line.below", key: .tvInput),
        RemoteAction(id: "menu", title: "Menu", systemImage: "line.3.horizontal", key: .menu),
        RemoteAction(id: "captions", title: "CC", systemImage: "captions.bubble.fill", key: .captions)
    ]
}
