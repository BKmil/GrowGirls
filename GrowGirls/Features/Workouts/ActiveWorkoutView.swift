struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Current workout").font(.title2.bold())
                Button("Finish workout") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandPink)
            }
        }
    }
}