//
//  PermissionRequiredView.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import SwiftUI

struct PermissionRequiredView: View {
    let message: String
    let onRequestPermission: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)

            VStack(spacing: 12) {
                Text("Permission Required")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 12) {
                Button {
                    onRequestPermission()
                } label: {
                    Text("Request Permission")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Go Back")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    PermissionRequiredView(
        message: "카메라 권한이 필요합니다",
        onRequestPermission: {},
        onDismiss: {}
    )
}
