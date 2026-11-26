import SwiftUI

struct CreateExerciseView: View {
    @State private var viewModel = CreateExerciseViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // callback triggered after successful creation so the parent list can append or refresh
    var onExerciseCreated: ((Exercise) -> Void)?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        exerciseNameSection
                        muscleGroupSection
                        mediaTypeSection
                        techniqueCuesSection
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            
            saveButton
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadMuscleGroups()
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            }
            
            Text("New exercise")
                .font(.title2.bold())
                .padding(.leading, 8)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
    
    private var exerciseNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exercise name")
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            
            TextField("e.g. Bulgarian Split Squat", text: $viewModel.name)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
        }
    }
    
    private var muscleGroupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Muscle group")
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.availableMuscleGroups, id: \.self) { group in
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
                                .padding(.vertical, 10)
                                .background(isSelected ? Color.brandPink : Color.white)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.15), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }
    
    private var mediaTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Media type")
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ForEach(ExerciseMediaType.allCases) { type in
                    let isSelected = viewModel.selectedMediaType == type
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewModel.selectedMediaType = type
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: type.iconName)
                                .font(.system(size: 20, weight: .semibold))
                            Text(type.rawValue)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(isSelected ? .white : .primary.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isSelected ? Color.brandPink : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color.clear : Color.gray.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: isSelected ? Color.brandPink.opacity(0.25) : .black.opacity(0.03), radius: 6, y: 2)
                    }
                }
            }
            
            TextField("Optional \(viewModel.selectedMediaType.rawValue.lowercased()) URL", text: $viewModel.mediaUrl)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
                .padding(.top, 4)
        }
    }
    
    private var techniqueCuesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Technique cues")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("One step per line")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ZStack(alignment: .topLeading) {
                if viewModel.instructions.isEmpty {
                    Text("1. Set your front foot flat on the floor...\n2. Lower your hips slowly while keeping your chest up...")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                }
                
                TextEditor(text: $viewModel.instructions)
                    .font(.subheadline)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
        }
    }
    
    private var saveButton: some View {
        Button {
            Task {
                if let created = await viewModel.submit() {
                    onExerciseCreated?(created)
                    dismiss()
                }
            }
        } label: {
            Group {
                if viewModel.isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Save exercise")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.isFormValid ? Color.brandPink : Color.gray.opacity(0.35))
            .clipShape(Capsule())
            .shadow(color: viewModel.isFormValid ? Color.brandPink.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}