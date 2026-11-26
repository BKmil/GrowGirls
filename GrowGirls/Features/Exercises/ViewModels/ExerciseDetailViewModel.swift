import SwiftUI

@Observable
final class ExerciseDetailViewModel {
    var exercise: Exercise
    var personalBest: ExercisePersonalBest?
    var isLoading: Bool = false
    var errorMessage: String?
    
    init(exercise: Exercise, personalBest: ExercisePersonalBest? = nil) {
        self.exercise = exercise
        self.personalBest = personalBest
    }
    
    // making instruction steps more readable by splitting them into an array of strings
    var instructionSteps: [String] {
        exercise.instructions
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    @MainActor
    func refreshDetail() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let updated = try await ExerciseService.shared.fetchExerciseDetail(id: exercise.id)
            self.exercise = updated
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func toggleFavorite() async {
        let currentStatus = exercise.isFavorite ?? false
        exercise.isFavorite = !currentStatus
        
        do {
            try await ExerciseService.shared.toggleFavorite(
                exerciseId: exercise.id,
                isCurrentlyFavorite: currentStatus
            )
        } catch {
            exercise.isFavorite = currentStatus
        }
    }
}