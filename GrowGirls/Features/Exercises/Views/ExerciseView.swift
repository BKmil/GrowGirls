import SwiftUI

enum ExerciseListMode {
    case browsing
    case selection(onConfirm: ([Exercise]) -> Void)
}

struct ExerciseListView: View {
    @State private var viewModel = ExerciseViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var mode: ExerciseListMode = .browsing
    var onAddNewExercise: (() -> Void)? = nil
    
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 16) {
                headerView
                searchBar
                muscleGroupPills
                
                if viewModel.isLoading && viewModel.exercises.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(.brandPink)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.exercises) { exercise in
                                ExerciseCardView(
                                    exercise: exercise,
                                    isSelectionMode: isSelectionMode,
                                    isSelected: viewModel.selectedExerciseIDs.contains(exercise.id),
                                    onFavoriteTap: {
                                        Task { await viewModel.toggleFavorite(for: exercise) }
                                    }
                                )
                                .onTapGesture {
                                    if isSelectionMode {
                                        viewModel.toggleSelection(for: exercise)
                                    } else {
                                        // ExerciseDataView navigation should be here
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, isSelectionMode ? 90 : 24)
                    }
                }
            }
            
            // accept button in selection mode
            if case .selection(let onConfirm) = mode, !viewModel.selectedExerciseIDs.isEmpty {
                Button {
                    let chosen = viewModel.exercises.filter { viewModel.selectedExerciseIDs.contains($0.id) }
                    onConfirm(chosen)
                    dismiss()
                } label: {
                    Text("Add \(viewModel.selectedExerciseIDs.count) exercises")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.brandPink)
                        .clipShape(Capsule())
                        .shadow(color: Color.brandPink.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadInitialData()
        }
        .onChange(of: viewModel.searchText) {
            Task { await viewModel.filterExercises() }
        }
        .onChange(of: viewModel.selectedMuscleGroup) {
            Task { await viewModel.filterExercises() }
        }
    }
    
    private var isSelectionMode: Bool {
        if case .selection = mode { return true }
        return false
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
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
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            }
            
            Text(isSelectionMode ? "Select exercises" : "Exercises")
                .font(.title2.bold())
                .padding(.leading, 8)
            
            Spacer()
            
            if !isSelectionMode {
                Button {
                    onAddNewExercise?()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.brandPink)
                        .clipShape(Circle())
                        .shadow(color: Color.brandPink.opacity(0.3), radius: 6, y: 3)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search exercises", text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
        .padding(.horizontal, 20)
    }
    
    private var muscleGroupPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.muscleGroups, id: \.self) { group in
                    let isSelected = viewModel.selectedMuscleGroup == group
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewModel.selectedMuscleGroup = group
                        }
                    } label: {
                        Text(group)
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? .white : .primary.opacity(0.75))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(isSelected ? Color.brandPink : Color.white)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.15), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// single exercise card view

struct ExerciseCardView: View {
    let exercise: Exercise
    let isSelectionMode: Bool
    let isSelected: Bool
    let onFavoriteTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // exercise image or placeholder
                Group {
                    if let urlString = exercise.mediaUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            placeholderImage
                        }
                    } else {
                        placeholderImage
                    }
                }
                .frame(height: 135)
                .frame(maxWidth: .infinity)
                .clipped()
                
                // top right corner
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .brandPink : .white)
                        .background(Circle().fill(isSelected ? Color.white : Color.black.opacity(0.3)))
                        .padding(10)
                } else {
                    Button(action: onFavoriteTap) {
                        Image(systemName: (exercise.isFavorite ?? false) ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor((exercise.isFavorite ?? false) ? .brandPink : .gray)
                            .frame(width: 32, height: 32)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                    .padding(10)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(exercise.muscleGroup.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected && isSelectionMode ? Color.brandPink : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }
    
    private var placeholderImage: some View {
        ZStack {
            Color.gray.opacity(0.12)
            Image(systemName: "dumbbell.fill")
                .font(.title2)
                .foregroundColor(.gray.opacity(0.4))
        }
    }
}