import Foundation

class ReminderService {
    static let shared = ReminderService()
    private init() {}
    
    private let baseURL = "http://45.141.78.50:8080"
    
    func fetchMyNotes(completion: @escaping (Result<[NoteData], Error>) -> Void) {
        guard let url = URL(string: baseURL + "/note/my") else {
            completion(.failure(ReminderError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = AuthService.shared.getCurrentToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            completion(.failure(ReminderError.noAuthToken))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(ReminderError.invalidResponse))
                return
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                if let data = data, !data.isEmpty {
                    do {
                        let notes = try JSONDecoder().decode([NoteData].self, from: data)
                        completion(.success(notes))
                    } catch {
                        print("[ReminderService] Decoding Error: \(error.localizedDescription)")
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("[ReminderService] Raw Response JSON: \(jsonString)")
                        }
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(ReminderError.noData))
                }
            } else {
                let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown server error"
                completion(.failure(ReminderError.server(message)))
            }
        }.resume()
    }
    
    enum ReminderError: LocalizedError {
        case invalidURL
        case invalidResponse
        case noAuthToken
        case noData
        case server(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Некорректный URL запроса."
            case .invalidResponse:
                return "Некорректный ответ сервера."
            case .noAuthToken:
                return "Отсутствует токен авторизации. Пожалуйста, войдите в систему."
            case .noData:
                return "Ответ сервера не содержит данных."
            case .server(let message):
                return "Ошибка сервера: \(message)"
            }
        }
    }
} 
