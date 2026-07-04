//
//  DirectionPad.swift
//  TCL_TV_Remote
//

import SwiftUI

struct DirectionPad: View {
    let onKey: (TVKey) -> Void

    var body: some View {
        VStack(spacing: 10) {
            RemoteCircleButton(systemImage: "chevron.up") {
                onKey(.dpadUp)
            }

            HStack(spacing: 10) {
                RemoteCircleButton(systemImage: "chevron.left") {
                    onKey(.dpadLeft)
                }

                RemoteCircleButton(systemImage: "circle.fill") {
                    onKey(.dpadCenter)
                }

                RemoteCircleButton(systemImage: "chevron.right") {
                    onKey(.dpadRight)
                }
            }

            RemoteCircleButton(systemImage: "chevron.down") {
                onKey(.dpadDown)
            }
        }
    }
}
