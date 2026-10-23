//
//  EndTransitionView.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//
import SwiftUI

struct EndTransition: View {

    let onContinue: () -> Void

    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("✨ Well Done ✨")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Take a breath.\nYou solved the puzzle.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .opacity(0.8)

                ZenButton(title: "Continue") {
                    onContinue()
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
            )
            .offset(y: appear ? 0 : 40)
            .opacity(appear ? 1 : 0)
            .animation(.easeOut(duration: 0.4), value: appear)
        }
        .onAppear {
            appear = true
        }
    }
}
