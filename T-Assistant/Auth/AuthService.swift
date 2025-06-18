import Foundation

class AuthService {
    static let shared = AuthService()
    private init() {}
    
    private let baseURL = "http://45.141.78.50:8080"
    
    func getCurrentToken() -> String? {
        return UserDefaults.standard.string(forKey: "authToken3")
    }
    
    func login(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/auth/login") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        let bodyData = try? JSONSerialization.data(withJSONObject: body)
        request.httpBody = bodyData
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AuthError.invalidResponse))
                return
            }
            let responseText = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<empty>"
            if (200...299).contains(httpResponse.statusCode) {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    completion(.success(token))
                } else {
                    completion(.failure(AuthError.invalidResponse))
                }
            } else {
                completion(.failure(AuthError.server(responseText)))
            }
        }.resume()
    }
    
    func register(email: String, fullName: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/auth/registration") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "email": email,
            "fullName": fullName,
            "password": password
        ]
        let bodyData = try? JSONSerialization.data(withJSONObject: body)
        request.httpBody = bodyData
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AuthError.invalidResponse))
                return
            }
            let responseText = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<empty>"
            if (200...299).contains(httpResponse.statusCode) {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    completion(.success(token))
                } else {
                    completion(.failure(AuthError.invalidResponse))
                }
            } else {
                completion(.failure(AuthError.server(responseText)))
            }
        }.resume()
    }
    
    enum AuthError: LocalizedError {
        case invalidURL
        case invalidResponse
        case server(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Некорректный URL"
            case .invalidResponse:
                return "Некорректный ответ сервера"
            case .server(let message):
                return message
            }
        }
    }
}
