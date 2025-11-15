//
//  MonthlyLeagueView.swift
//  ActionForAnimals
//
//  Created by Claude on 2024-11-06.
//

import SwiftUI

struct OutwardCurvedBottomShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start from top-left
        path.move(to: CGPoint(x: 0, y: 0))

        // Top edge
        path.addLine(to: CGPoint(x: rect.width, y: 0))

        // Right edge down to curve start
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - 60))

        // Outward curve at bottom - control point ABOVE the curve to make it bulge outward
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - 60),
            control: CGPoint(x: rect.width / 2, y: rect.height - 120)
        )

        // Left edge back up
        path.addLine(to: CGPoint(x: 0, y: 0))

        return path
    }
}

struct MonthlyLeagueView: View {
    @EnvironmentObject var store: Store
    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var isLoading = false
    @State private var showProfileDetail = false

    // Computed properties using store state directly
    private var isInLeague: Bool {
        // Check if user is registered for current month's league
        let currentMonthKey = getCurrentMonthKey()
        let lastLeagueMonth = UserDefaults.standard.string(forKey: UserDefaultsKey.lastLeagueMonth.rawValue)
        return lastLeagueMonth == currentMonthKey
    }

    private var currentLeaderboard: [LeagueParticipant] {
        return store.state.cachedCurrentLeaderboard
    }

    private var currentMeta: LeagueMeta? {
        return store.state.cachedCurrentMeta
    }

    // Keep previous month data as local state since it's not in store
    @State private var previousLeaderboard: [LeagueParticipant] = []
    @State private var previousMeta: LeagueMeta?

    var body: some View {
        NavigationStack {
            ZStack {
                // Sanctuary background with curved bottom
                VStack {
                    ZStack {
                        // Green background that extends beyond image
                        Rectangle()
                            .fill(Color.green)
                            .frame(height: 350)

                        // Sanctuary image
                        Image("sanctuary-empty")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 300)
                            .clipped()
                    }
                    .clipShape(OutwardCurvedBottomShape())

                    Spacer()
                }

                ScrollView {
                    VStack {
                        // Header with profile icon over background
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Monthly Challenge")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                HStack(spacing: 8) {
                                    Image(systemName: "clock")
                                        .foregroundColor(.white.opacity(0.8))
                                        .font(.caption)

                                    Text("\(daysRemainingInMonth()) days left")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }

                            Spacer()

                            Image(.afaStars)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20) // More spacing from top

                        // Circle overlapping more into the sanctuary background
                        if isInLeague {
                            if isLoading {
                                // Show loading state instead of 0
                                TotalAnimalsCircle(totalAnimals: nil)
                            } else {
                                TotalAnimalsCircle(totalAnimals: currentMeta?.totalAnimals)
                            }
                        } else {
                            // Show empty state circle when not in league
                            TotalAnimalsCircle(showEmptyState: true)
                        }
                    }

                    // White content area starts below circle
                    if isInLeague {
                        // Leaderboard content - now scrollable
                        VStack(spacing: 20) {
                            if isLoading {
                                ProgressView("Loading...")
                                    .padding(40)
                            } else {
                                // State 2: In League - Show leaderboard (without circle, it's above)
                                currentLeagueViewWithoutCircle
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                    } else {
                        // Join states content
                        VStack(spacing: 20) {
                            joinLeagueView
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                    }
                }
                .padding(.bottom)
                .padding(.bottom)
            }
            .navigationBarHidden(true)
            .refreshable {
                await refreshLeagueData()
            }
        }
        .sheet(isPresented: $showProfileDetail) {
            NavigationStack {
                ProfileDetailView(showDoneButton: true)
                    .onDisappear {
                        // Profile automatically updates via ProfileManager
                    }
            }
        }
        .onAppear {
            if isInLeague {
                // Always refresh in background for league members
                Task {
                    await refreshLeagueData()
                }

                if !currentLeaderboard.isEmpty {
                    print("🏆 [MonthlyLeagueView] Showing cached data while refreshing")
                } else {
                    print("🏆 [MonthlyLeagueView] No cached data - will show fresh data when loaded")
                }
            } else {
                print("🏆 [MonthlyLeagueView] User not in league - showing join view")
            }
        }
    }

    @ViewBuilder
    private var joinLeagueView: some View {
        VStack(spacing: 24) {
            // Previous month's results - only show if user participated
            if !previousLeaderboard.isEmpty && userWasInPreviousMonth() {
                VStack(spacing: 16) {
                    Text("\(monthDisplayName(previousMeta?.month)) Results")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    LazyVStack(spacing: 8) {
                        ForEach(previousLeaderboard, id: \.callerid) { participant in
                            LeaderboardRow(
                                participant: participant,
                                isCurrentUser: participant.callerid == AnalyticsManager.shared.callerID
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
            }

            // Current month join section
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    if !profileManager.currentProfile.hasLeagueRequiredInfo {
                        Text("Let's get your profile ready!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)

                        Text("Add your nickname and email to participate in this month's challenge!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else if store.state.animalsHelpedThisMonth == 0 {
                        Text("Ready to make a difference!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)

                        Text("Take your first action to join the challenge!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Text("Ready to compete!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)

                        Text(userWasInPreviousMonth()
                             ? "Continue your streak in this month's challenge!"
                             : "Join this month's challenge!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

                // Narrower buttons that don't take full width
                HStack {
                    Spacer()
                    if profileManager.currentProfile.hasLeagueRequiredInfo && store.state.animalsHelpedThisMonth > 0 {
                        Button(action: {
                            Task {
                                await joinLeague()
                            }
                        }) {
                            Text("Join Challenge")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .disabled(isLoading)
                    } else {
                        if !profileManager.currentProfile.hasLeagueRequiredInfo {
                            Button(action: {
                                showProfileDetail = true
                            }) {
                                Text("Complete Profile")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(Color.orange)
                                    .cornerRadius(12)
                            }
                        } else if store.state.animalsHelpedThisMonth == 0 {
                            Button(action: {
                                // Navigate to campaigns tab
                                store.objectWillChange.send()
                                store.state.selectedTab = "issues"
                            }) {
                                Text("View Campaigns")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    Spacer()
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var currentLeagueView: some View {
        VStack(spacing: 24) {
            // Total animals circle
            TotalAnimalsCircle(totalAnimals: currentMeta?.totalAnimals)

            // Current leaderboard
            if currentLeaderboard.isEmpty {
                LeagueEmptyState(
                    title: "League Starting Soon",
                    message: "Be the first to take an action this month!"
                )
            } else {
                VStack(spacing: 16) {
                    HStack {
                        Text("Leaderboard")
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        HStack(spacing: 4) {
                            Text("\(currentMeta?.participantCount ?? 0)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text("advocates")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)

                    LazyVStack(spacing: 8) {
                        ForEach(currentLeaderboard, id: \.callerid) { participant in
                            LeaderboardRow(
                                participant: participant,
                                isCurrentUser: participant.callerid == AnalyticsManager.shared.callerID
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    @ViewBuilder
    private var currentLeagueViewWithoutCircle: some View {
        VStack(spacing: 24) {
            // Current leaderboard (without circle - it's rendered above)
            if currentLeaderboard.isEmpty {
                LeagueEmptyState(
                    title: "League Starting Soon",
                    message: "Be the first to take an action this month!"
                )
            } else {
                VStack(spacing: 16) {
                    HStack {
                        Text("Leaderboard")
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        HStack(spacing: 4) {
                            Text("\(currentMeta?.participantCount ?? 0)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text("advocates")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 8) {
                        ForEach(currentLeaderboard, id: \.callerid) { participant in
                            LeaderboardRow(
                                participant: participant,
                                isCurrentUser: participant.callerid == AnalyticsManager.shared.callerID
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .padding(.top, 20) // Reduce empty space above leaderboard
    }

    // MARK: - Helper Functions
    private func monthDisplayName(_ monthKey: String?) -> String {
        guard let monthKey = monthKey else { return "Previous Month" }

        let components = monthKey.split(separator: "-")
        guard components.count == 2,
              let month = Int(components[1]) else {
            return "Previous Month"
        }

        let monthNames = ["January", "February", "March", "April", "May", "June",
                         "July", "August", "September", "October", "November", "December"]
        return (month > 0 && month <= monthNames.count) ? monthNames[month - 1] : "Previous Month"
    }

    // MARK: - Data Fetching Functions
    private func checkLeagueStatusAndFetchData(hasCachedData: Bool = false) async {
        // Only show loading if we don't have cached data
        if !hasCachedData {
            isLoading = true
        }

        // Check league status locally
        checkLeagueStatusLocally()
        await fetchLeaderboard()

        await MainActor.run {
            isLoading = false
        }
    }

    private func refreshLeagueData() async {
        // Don't show loading spinner during pull-to-refresh - user can see the refresh indicator
        checkLeagueStatusLocally()
        await fetchLeaderboard() // This will now smartly fetch based on league status
    }

    private func fetchLeaderboard() async {
        if isInLeague {
            // User is in current league - only fetch current month data
            await fetchCurrentMonthLeaderboard()
        } else {
            // User is not in current league - check if they were in previous month
            if userWasInPreviousMonth() {
                // User participated last month - show their results
                await fetchPreviousMonthLeaderboard()
            }
            // If user wasn't in previous month, show simple join screen with no data
        }
    }

    private func userWasInPreviousMonth() -> Bool {
        // Use UTC to match backend month calculations
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let now = Date()

        // Calculate previous month properly
        let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let previousMonthKey = String(format: "%04d-%02d",
                                    calendar.component(.year, from: previousMonthDate),
                                    calendar.component(.month, from: previousMonthDate))

        let lastLeagueMonth = UserDefaults.standard.string(forKey: UserDefaultsKey.lastLeagueMonth.rawValue)
        let wasInPreviousMonth = lastLeagueMonth == previousMonthKey

        print("Checking previous month participation: lastLeagueMonth=\(lastLeagueMonth ?? "nil"), previousMonthKey=\(previousMonthKey), result=\(wasInPreviousMonth)")

        return wasInPreviousMonth
    }

    private func daysRemainingInMonth() -> Int {
        let calendar = Calendar.current
        let now = Date()

        // Get the last day of current month
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now

        // Calculate days remaining
        let components = calendar.dateComponents([.day], from: now, to: endOfMonth)
        return max(0, components.day ?? 0)
    }

    private func fetchCurrentMonthLeaderboard() async {
        let operation = FetchCurrentMonthLeaderboardOperation()
        let queue = OperationQueue()
        queue.addOperation(operation)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            operation.completionBlock = {
                Task { @MainActor in
                    if let error = operation.error {
                        print("Failed to fetch current month leaderboard: \(error)")
                    } else {
                        // Update store cache via dispatch - computed properties will automatically reflect changes
                        store.dispatch(action: .SetCurrentLeaderboard(operation.currentLeaderboard, operation.currentMeta))
                        print("🏆 [MonthlyLeagueView] Updated cache with \(operation.currentLeaderboard.count) participants")

                        // Debug: Check if user's avatar updated
                        let userProfile = ProfileManager.shared.currentProfile
                        if let userParticipant = operation.currentLeaderboard.first(where: { $0.nickname == userProfile.displayNickname }) {
                            print("🏆 [Debug] User in leaderboard - avatar: \(userParticipant.avatar), expected: \(userProfile.avatarIconName)")
                        }

                    }
                    continuation.resume()
                }
            }
        }
    }

    private func fetchPreviousMonthLeaderboard() async {
        let operation = FetchPreviousMonthLeaderboardOperation()
        let queue = OperationQueue()
        queue.addOperation(operation)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            operation.completionBlock = {
                Task { @MainActor in
                    if let error = operation.error {
                        print("Failed to fetch previous month leaderboard: \(error)")
                    } else {
                        self.previousLeaderboard = operation.previousLeaderboard
                        self.previousMeta = operation.previousMeta
                    }
                    continuation.resume()
                }
            }
        }
    }

    private func checkLeagueStatusLocally() {
        // Use UTC to match backend month calculations
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let now = Date()
        let currentMonthKey = String(format: "%04d-%02d",
                                   calendar.component(.year, from: now),
                                   calendar.component(.month, from: now))

        let lastLeagueMonth = UserDefaults.standard.string(forKey: UserDefaultsKey.lastLeagueMonth.rawValue)
        // isInLeague is now computed from store state

        print("Local league status check: lastLeagueMonth=\(lastLeagueMonth ?? "nil"), currentMonth=\(currentMonthKey), isInLeague=\(isInLeague)")
    }

    private func joinLeague() async {
        isLoading = true

        let operation = JoinMonthlyLeagueOperation(
            userProfile: profileManager.currentProfile,
            animalsHelpedThisMonth: store.state.animalsHelpedThisMonth,
            city: store.state.city,
            state: store.state.state
        )
        let queue = OperationQueue()
        queue.addOperation(operation)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            operation.completionBlock = {
                Task { @MainActor in
                    if let error = operation.error {
                        print("Failed to join league: \(error)")
                    } else if operation.success {
                        // isInLeague is now computed from store state
                        // Refresh leaderboard to show user's entry
                        await self.fetchLeaderboard()
                    }
                    self.isLoading = false
                    continuation.resume()
                }
            }
        }
    }

    private func getCurrentMonthKey() -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let now = Date()
        return String(format: "%04d-%02d",
                     calendar.component(.year, from: now),
                     calendar.component(.month, from: now))
    }
}

// Extension to check if profile has required info
extension UserProfile {
    var hasRequiredInfo: Bool {
        return (firstName?.isEmpty == false || nickname?.isEmpty == false) &&
               (email?.isEmpty == false)
    }

    var hasLeagueRequiredInfo: Bool {
        // For leagues, we specifically require nickname (not just firstName)
        return (nickname?.isEmpty == false) &&
               (email?.isEmpty == false)
    }
}

#Preview {
    MonthlyLeagueView()
        .environmentObject(Store(state: AppState()))
}