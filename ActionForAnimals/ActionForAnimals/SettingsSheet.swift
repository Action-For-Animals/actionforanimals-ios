//
//  SettingsSheet.swift
//  ActionForAnimals
//
//  Created by Claude on 2025-09-11.
//

import StoreKit
import SwiftUI

private let appId = "6751785020"
private let appUrl = URL(string: "https://itunes.apple.com/us/app/myapp/id\(appId)?ls=1&mt=8")

struct SettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    
    // Sheet states
    @State var showRemindersSheet = false
    @State var showEmailComposer = false
    @State var showEmailComposerAlert = false
    @State var showWelcome = false
    @State private var callingGroup: String = UserDefaults.standard.string(forKey: UserDefaultsKey.callingGroup.rawValue) ?? ""
    
    private var versionString: String? = {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }
        return "v\(version) - \(AnalyticsManager.shared.callerID)"
    }()
    
    var body: some View {
        NavigationStack {
            List {
                // General Section
                Section {
                    AboutListItem(title: R.string.localizable.menuScheduledReminders(),
                                  type: .action({
                        showRemindersSheet = true
                    }))
                    
                    AboutListItem(title: R.string.localizable.aboutItemFeedback(),
                                  type: .action({
                        if EmailComposerView.canSendEmail() {
                            showEmailComposer = true
                        } else {
                            showEmailComposerAlert = true
                        }
                    }))
                } header: {
                    Text(R.string.localizable.aboutSectionHeaderGeneral().uppercased())
                        .font(.footnote)
                        .foregroundStyle(.afaDarkGray)
                }
                
                // Social Section
                Section {
                    AboutListItem(title: "Instagram",
                                  type: .action({
                        openSocialLink("https://www.instagram.com/xfaorg/")
                    }))
                    if appUrl != nil {
                        AboutListItem(title: R.string.localizable.aboutItemShare(),
                                      type: .url(appUrl!))
                    }
                    AboutListItem(title: R.string.localizable.aboutItemRate(),
                                  type: .action({
                        requestReview()
                    }))
                } header: {
                    Text(R.string.localizable.aboutSectionHeaderSocial().uppercased())
                        .font(.footnote)
                        .foregroundStyle(.afaDarkGray)
                } footer: {
                    Text(R.string.localizable.aboutSectionFooterSocial())
                        .font(.footnote)
                        .foregroundStyle(.afaDarkGray)
                }
                
                // Credits Section
                Section {
                    AboutListItem(
                        title: R.string.localizable.aboutItem5Calls(),
                        type: .action({
                            if let url = URL(string: "https://github.com/5calls") {
                                UIApplication.shared.open(url)
                            }
                        })
                    )
                    
                    AboutListItem(title: R.string.localizable.aboutItemOpenSource(),
                                  type: .acknowledgements)
                } header: {
                    Text(R.string.localizable.aboutSectionHeaderCredits().uppercased())
                }
                
                // Version Section
                if let versionString {
                    Section(
                        footer: HStack {
                            Spacer()
                            Text(versionString)
                                .font(.footnote)
                                .foregroundStyle(.afaDarkGray)
                            Spacer()
                        },
                        content: {})
                }
            }
            .listStyle(.grouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbarBackground(.visible)
            .toolbarBackground(Color.afaDarkBlue)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.dismiss()
                    }) {
                        Text(R.string.localizable.doneButtonTitle())
                            .bold()
                    }
                }
            }
            .navigationDestination(for: WebViewContent.self) { webViewContent in
                WebView(webViewContent: webViewContent)
                    .navigationTitle(webViewContent.navigationTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.visible)
                    .toolbarBackground(Color.afaDarkBlue)
                    .toolbarColorScheme(.dark, for: .navigationBar)
            }
        }
        .accentColor(.white)
        .sheet(isPresented: $showRemindersSheet) {
            ScheduleReminders()
        }
        .sheet(isPresented: $showEmailComposer){
            EmailComposerView() { _ in }
        }
        .alert(isPresented: $showEmailComposerAlert) {
            Alert(title: Text(R.string.localizable.cantSendEmailTitle()),
                  message: Text(R.string.localizable.cantSendEmailMessage()),
                  dismissButton: .default(Text(R.string.localizable.dismissTitle())))
        }
    }
    
    // MARK: - Helper Methods
    func openSocialLink(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    func requestReview() {
        guard let currentScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        SKStoreReviewController.requestReview(in: currentScene)
    }
}