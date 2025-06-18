import Foundation

class NotificationService {
    static let shared = NotificationService()
    private init() {}
    
    private let baseURL = "http://45.141.78.50:8080"
    
    func saveFCMToken(_ token: String, completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let url = URL(string: baseURL + "/notification/token/save") else {
            completion?(.failure(NotificationError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let authToken = AuthService.shared.getCurrentToken() {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: String] = ["token": token]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion?(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion?(.failure(NotificationError.invalidResponse))
                return
            }
            if (200...299).contains(httpResponse.statusCode) {
                completion?(.success(()))
            } else {
                let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown server error"
                completion?(.failure(NotificationError.server(message)))
            }
        }.resume()
    }
    
    enum NotificationError: LocalizedError {
        case invalidURL
        case invalidResponse
        case server(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Некорректный URL запроса."
            case .invalidResponse: return "Некорректный ответ сервера."
            case .server(let message): return "Ошибка сервера: \(message)"
            }
        }
    }
} 