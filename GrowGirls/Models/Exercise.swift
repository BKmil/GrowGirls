import Foundation

struct ExerciseResponse: Codable {
    let items: [Exercise]
    let total: Int?
    let page: Int?
    let totalPages: Int?
}

struct Exercise: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let muscleGroup: String
    let instructions: String
    let mediaUrl: String?
    let mediaType: String?
    var isFavorite: Bool?
}

struct ExercisePersonalBest: Codable, Hashable {
    let weightKg: Double
    let reps: Int
    let achievedAt: Date?
    
    var formattedSummary: String {
        let weightStr = weightKg.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weightKg)
            : String(format: "%.1f", weightKg)
        return "\(weightStr) kg × \(reps) reps"
    }
}