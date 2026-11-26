import SwiftUI

struct ExerciseDetailView: View {
    @State private var viewModel: ExerciseDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    /// favourite change callback, useful for updating the list view when the user toggles favorite status in the detail view
    var onFavoriteChanged: ((Bool) -> Void)?
    
    init(
        exercise: Exercise,
        personalBest: ExercisePersonalBest? = nil,
        onFavoriteChanged: ((Bool) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: ExerciseDetailViewModel(
            exercise: exercise,
            personalBest: personalBest
        ))
        self.onFavoriteChanged = onFavoriteChanged
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    mediaPreviewSection
                    
                    VStack(alignment: .leading, spacing: 20) {
                        titleAndTagsSection
                        personalBestCard
                        howToPerformSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            topNavigationOverlay
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.refreshDetail()
        }
    }
    
    // subviews
    
    private var topNavigationOverlay: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            }
            
            Spacer()
            
            Button {
                Task {
                    await viewModel.toggleFavorite()
                    onFavoriteChanged?(viewModel.exercise.isFavorite ?? false)
                }
            } label: {
                Image(systemName: (viewModel.exercise.isFavorite ?? false) ? "heart.fill" : "heart")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor((viewModel.exercise.isFavorite ?? false) ? .brandPink : .gray)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    private var mediaPreviewSection: some View {
        ZStack(alignment: .bottom) {
            if let urlString = viewModel.exercise.mediaUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    mediaPlaceholder
                }
            } else {
                mediaPlaceholder
            }
            
            // gradient overlay, may be cool
            LinearGradient(
                colors: [.clear, Color.appBackground.opacity(0.85), Color.appBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 44)
        }
        .frame(height: 290)
        .frame(maxWidth: .infinity)
        .clipped()
    }
    
    private var mediaPlaceholder: some View {
        ZStack {
            Color.white
            VStack(spacing: 10) {
                Image(systemName: viewModel.exercise.mediaType == "video" ? "play.circle.fill" : "dumbbell.fill")
                    .font(.system(size: 42))
                    .foregroundColor(.brandPink.opacity(0.45))
                Text("No media preview")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var titleAndTagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.exercise.name)
                .font(.title.bold())
                .foregroundColor(.primary)
            
            HStack(spacing: 8) {
                Text(viewModel.exercise.muscleGroup.capitalized)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.brandPink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.brandPink.opacity(0.12))
                    .clipShape(Capsule())
                
                if let mediaType = viewModel.exercise.mediaType {
                    Text(mediaType.capitalized)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    private var personalBestCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.brandPink.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.brandPink)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Personal Best (PR)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                
                if let pr = viewModel.personalBest {
                    Text(pr.formattedSummary)
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                    
                    if let date = pr.achievedAt {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No PR recorded yet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary.opacity(0.75))
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }
    
    private var howToPerformSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How to perform")
                .font(.headline.bold())
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 14) {
                if viewModel.instructionSteps.isEmpty {
                    Text("No technique instructions provided.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(viewModel.instructionSteps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.brandPink)
                                .clipShape(Circle())
                            
                            Text(step)
                                .font(.subheadline)
                                .foregroundColor(.primary.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
        }
    }
}