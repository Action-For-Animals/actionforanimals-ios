//
//  Welcome.swift
//  ActionForAnimals
//
//  Created by Christopher Selin on 10/21/23.
//  Copyright © 2023 5calls. All rights reserved.
//

import SwiftUI

struct Welcome: View {
    @AppStorage(UserDefaultsKey.hasShownWelcomeScreen.rawValue) var hasShownWelcomeScreen = false
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    
    @State private var showLocationSheet = false
    
    var onContinue: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo section
            VStack(spacing: 24) {
                Image(decorative: R.image.afaLogotype)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250)
                
                Text("Turn your care for animals into meaningful action.")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
            
            // Location setup section
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Set Your Location to Get Started")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("We need your location to find your representatives and show relevant campaigns.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Button(action: {
                    showLocationSheet = true
                }) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .font(.title3)
                        Text("Set Location")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .onAppear() {
            hasShownWelcomeScreen = true
            if store.state.globalCallCount == 0 {
                store.dispatch(action: .FetchStats(nil))
            }
        }
        .sheet(isPresented: $showLocationSheet) {
            LocationSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: store.state.location) { location in
            if location != nil {
                onContinue?()
                dismiss()
            }
        }
    }
}

struct Welcome_Previews: PreviewProvider {
    static let previewState = {
        var state = AppState()
        state.globalCallCount = 12345
        return state
    }()

    static let previewStore = Store(state: previewState, middlewares: [appMiddleware()])

    static var previews: some View {
        Welcome().environmentObject(previewStore)
    }
}
