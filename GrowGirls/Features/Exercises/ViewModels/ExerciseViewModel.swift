import SwiftUI

@Observable
final class ExerciseViewModel {
    var exercises: [Exercise] = []
    var muscleGroups: [String] = ["All", "Glutes", "Legs", "Core", "Shoulders", "Back", "Chest", "Arms"]
    
    var searchText: String = ""
    var selectedMuscleGroup: String = "All"
    var isLoading: Bool = false
    var errorMessage: String?
    
    // selection mode
    var selectedExerciseIDs: Set<String> = []
    
    @MainActor
    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let groupsTask = ExerciseService.shared.fetchMuscleGroups()
            async let exercisesTask = ExerciseService.shared.fetchExercises()
            
            let (fetchedGroups, fetchedExercises) = try await (groupsTask, exercisesTask)
            if !fetchedGroups.isEmpty {
                self.muscleGroups = ["All"] + fetchedGroups.map { $0.capitalized }
            }
            self.exercises = fetchedExercises
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func filterExercises() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.exercises = try await ExerciseService.shared.fetchExercises(
                search: searchText,
                muscleGroup: selectedMuscleGroup
            )
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func toggleFavorite(for exercise: Exercise) async {
        guard let index = exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        let currentStatus = exercises[index].isFavorite ?? false
        
        // UI update
        exercises[index].isFavorite = !currentStatus
        
        do {
            try await ExerciseService.shared.toggleFavorite(
                exerciseId: exercise.id,
                isCurrentlyFavorite: currentStatus
            )
        } catch {
            // go back to previous state if error occurs
            exercises[index].isFavorite = currentStatus
        }
    }
    
    func toggleSelection(for exercise: Exercise) {
        if selectedExerciseIDs.contains(exercise.id) {
            selectedExerciseIDs.remove(exercise.id)
        } else {
            selectedExerciseIDs.insert(exercise.id)
        }
    }
}