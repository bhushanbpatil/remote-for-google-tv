//
//  TVDevice.swift
//  TCL_TV_Remote
//

import Foundation

struct TVDevice: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let host: String
    let port: Int

    init(name: String, host: String, port: Int = 6466) {
        self.id = "\(host):\(port)"
        self.name = name
        self.host = host
        self.port = port
    }
}

enum ConnectionPhase: Equatable {
    case disconnected
    case connecting
    case needsPairing
    case waitingForCode
    case paired
    case connected
    case error(String)
}

struct StreamingApp: Identifiable {
    let id: String
    let name: String
    let deepLink: String
}

extension StreamingApp {
    static let defaults: [StreamingApp] = [
        StreamingApp(id: "youtube", name: "YouTube", deepLink: "https://www.youtube.com"),
        StreamingApp(id: "netflix", name: "Netflix", deepLink: "https://www.netflix.com/title"),
        StreamingApp(id: "disney", name: "Disney+", deepLink: "https://www.disneyplus.com"),
        StreamingApp(id: "prime", name: "Prime Video", deepLink: "https://app.primevideo.com"),
        StreamingApp(id: "appletv", name: "Apple TV", deepLink: "com.apple.atve.androidtv.appletv"),
        StreamingApp(id: "hbo", name: "HBO Max", deepLink: "com.wbd.stream"),
        StreamingApp(id: "hulu", name: "Hulu", deepLink: "com.hulu.livingroomplus"),
        StreamingApp(id: "espn", name: "ESPN", deepLink: "com.espn.gtv"),
        StreamingApp(id: "sling", name: "Sling", deepLink: "com.sling"),
        StreamingApp(id: "foxone", name: "Fox One", deepLink: "com.fox.foxone")
    ]
}
