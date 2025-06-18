import Foundation

struct UserLocation: Identifiable, Codable {
    let id: String
    let name: String
    let coords: String
}

class LocationService {
    static let shared = LocationService()
    private init() {}

    private let baseURL = "http://45.141.78.50:8080"

    func fetchLocations(completion: @escaping (Result<[UserLocation], Error>) -> Void) {
        guard let url = URL(string: baseURL + "/location") else {
            completion(.failure(LocationError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = AuthService.shared.getCurrentToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            completion(.failure(LocationError.noAuthToken))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(LocationError.invalidResponse))
                return
            }

            if (200...299).contains(httpResponse.statusCode) {
                if let data = data, !data.isEmpty {
                    do {
                        let locations = try JSONDecoder().decode([UserLocation].self, from: data)
                        completion(.success(locations))
                    } catch {
                        print("[LocationService] Decoding Error: \(error.localizedDescription)")
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("[LocationService] Raw Response JSON: \(jsonString)")
                        }
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(LocationError.noData))
                }
            } else {
                let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown server error"
                completion(.failure(LocationError.server(message)))
            }
        }.resume()
    }

    func saveLocation(name: String, coords: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/location") else {
            completion(.failure(LocationError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.getCurrentToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            completion(.failure(LocationError.noAuthToken))
            return
        }

        let body: [String: String] = ["name": name, "coords": coords]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(LocationError.invalidResponse))
                return
            }

            if (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown server error"
                completion(.failure(LocationError.server(message)))
            }
        }.resume()
    }

    enum LocationError: LocalizedError {
        case invalidURL
        case invalidResponse
        case noAuthToken
        case noData
        case server(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Некорректный URL запроса."
            case .invalidResponse: return "Некорректный ответ сервера."
            case .noAuthToken: return "Отсутствует токен авторизации."
            case .noData: return "Ответ сервера не содержит данных."
            case .server(let message): return "Ошибка сервера: \(message)"
            }
        }
    }
} 
