import SwiftUI

struct RootTabView: View {
    @State private var selectedTab: TabItem = .home
    @State private var isWorkoutActive: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {

            Group {
                switch selectedTab {
                case .home:
                    NavigationStack {
                        HomeView(onStartWorkout: { isWorkoutActive = true })
                    }
                case .plans:
                    NavigationStack {
                        PlansListView()
                    }
                case .calendar:
                    NavigationStack {
                        CalendarView()
                    }
                case .profile:
                    NavigationStack {
                        ProfileView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 75)
            }
            
            CustomTabBar(selectedTab: $selectedTab) {
                isWorkoutActive = true
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .ignoresSafeArea(edges: .bottom)
        .fullScreenCover(isPresented: $isWorkoutActive) {
            ActiveWorkoutView()
        }
    }
}