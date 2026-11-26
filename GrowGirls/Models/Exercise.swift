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