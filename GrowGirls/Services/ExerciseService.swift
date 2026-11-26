import Foundation

final class ExerciseService {
    static let shared = ExerciseService()
    private let baseURL = "http://localhost:3000"
    
    // temp token, in real app this will be loaded from keychain
    var authToken: String = ""
    
    private init() {}
    
    func fetchMuscleGroups() async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/exercises/muscle-groups") else { return [] }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([String].self, from: data)
    }
    
    func fetchExercises(
        search: String = "",
        muscleGroup: String? = nil,
        favoritesOnly: Bool = false
    ) async throws -> [Exercise] {
        var components = URLComponents(string: "\(baseURL)/exercises")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "50")
        ]
        
        if !search.trimmingCharacters(in: .whitespaces).isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        if let muscleGroup, muscleGroup != "All" {
            queryItems.append(URLQueryItem(name: "muscleGroup", value: muscleGroup.lowercased()))
        }
        if favoritesOnly {
            queryItems.append(URLQueryItem(name: "favoritesOnly", value: "true"))
        }
        
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(ExerciseResponse.self, from: data)
        return decoded.items
    }
    
    func toggleFavorite(exerciseId: String, isCurrentlyFavorite: Bool) async throws {
        guard let url = URL(string: "\(baseURL)/exercises/\(exerciseId)/favorite") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = isCurrentlyFavorite ? "DELETE" : "PUT"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }

    func fetchExerciseDetail(id: String) async throws -> Exercise {
    guard let url = URL(string: "\(baseURL)/exercises/\(id)") else {
        throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(Exercise.self, from: data)
}
}