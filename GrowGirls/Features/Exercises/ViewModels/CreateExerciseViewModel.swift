import SwiftUI

enum ExerciseMediaType: String, CaseIterable, Identifiable {
    case photo = "Photo"
    case gif = "GIF"
    case video = "Video"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .photo: return "photo"
        case .gif: return "sparkles.rectangle.stack"
        case .video: return "video.fill"
        }
    }
    
    var apiValue: String {
        rawValue.lowercased()
    }
}

@Observable
final class CreateExerciseViewModel {
    var name: String = ""
    var selectedMuscleGroup: String = "Glutes"
    var instructions: String = ""
    var selectedMediaType: ExerciseMediaType = .photo
    var mediaUrl: String = ""
    
    var availableMuscleGroups: [String] = [
        "Glutes", "Legs", "Core", "Shoulders", "Back", "Chest", "Arms"
    ]
    
    var isSubmitting: Bool = false
    var errorMessage: String?
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    @MainActor
    func loadMuscleGroups() async {
        do {
            let fetched = try await ExerciseService.shared.fetchMuscleGroups()
            if !fetched.isEmpty {
                self.availableMuscleGroups = fetched.map { $0.capitalized }
                if !availableMuscleGroups.contains(selectedMuscleGroup), let first = availableMuscleGroups.first {
                    selectedMuscleGroup = first
                }
            }
        } catch {
            // keep default muscle groups fallback
        }
    }
    
    @MainActor
    func submit() async -> Exercise? {
        guard isFormValid else { return nil }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        
        do {
            return try await ExerciseService.shared.createExercise(
                name: name,
                muscleGroup: selectedMuscleGroup,
                instructions: instructions,
                mediaUrl: mediaUrl.isEmpty ? nil : mediaUrl,
                mediaType: selectedMediaType.apiValue
            )
        } catch {
            errorMessage = "Failed to save exercise. Please check your connection and try again."
            return nil
        }
    }
}