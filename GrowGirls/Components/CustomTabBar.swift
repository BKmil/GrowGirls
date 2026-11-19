import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    var onStartTapped: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                tabButton(for: .home)
                tabButton(for: .plans)
                
                VStack(spacing: 4) {
                    Spacer()
                        .frame(height: 22)
                    Text("Start")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.brandPink)
                }
                .frame(maxWidth: .infinity)
                
                tabButton(for: .calendar)
                tabButton(for: .profile)
            }
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .padding(.bottom, 24)
            .background(
                Color.white
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -4)
            )
            
            Button(action: onStartTapped) {
                ZStack {
                    Circle()
                        .fill(Color.brandPink)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(color: Color.brandPink.opacity(0.35), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: 2)
                }
            }
            .offset(y: -22)
        }
    }
    
    @ViewBuilder
    private func tabButton(for tab: TabItem) -> some View {
        let isSelected = selectedTab == tab
        
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .frame(height: 22)
                
                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .medium : .regular))
            }
            .foregroundColor(isSelected ? .brandPink : Color.gray.opacity(0.8))
            .frame(maxWidth: .infinity)
        }
    }
}