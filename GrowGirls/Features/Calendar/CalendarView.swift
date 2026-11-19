import SwiftUI

struct CalendarView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("Calendar").font(.title2.bold())
        }
    }
}
