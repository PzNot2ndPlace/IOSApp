import Foundation

struct NoteAPIResponse: Decodable {
    let noteDto: NoteData?
    let status: String?
    let message: String?
}

class NoteService {
    static let shared = NoteService()
    private init() {}

    private let baseURL = "http://45.141.78.50:5678"

    func processText(_ text: String, completion: @escaping (Result<NoteData, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/webhook/note") else {
            completion(.failure(NoteError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = AuthService.shared.getCurrentToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            completion(.failure(NoteError.noAuthToken))
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let currentTimeString = dateFormatter.string(from: Date())
        
        let body: [String: String] = [
            "user_text": text,
            "current_time": currentTimeString
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NoteError.invalidResponse))
                return
            }

            if (200...299).contains(httpResponse.statusCode) {
                if let data = data, !data.isEmpty {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("[NoteService] Raw Response JSON: \(jsonString)")
                    }
                    do {
                        let apiResponse = try JSONDecoder().decode(NoteAPIResponse.self, from: data)
                        
                        print("[NoteService] Decoded API Response:")
                        print("  Status: \(apiResponse.status ?? "nil")")
                        print("  Message: \(apiResponse.message ?? "nil")")

                        if apiResponse.status == "error", let errorMessage = apiResponse.message {
                            completion(.failure(NoteError.server(errorMessage)))
                        } else if let noteDto = apiResponse.noteDto {
                            completion(.success(noteDto))
                        } else {
                            completion(.failure(NoteError.invalidResponse))
                        }
                    } catch {
                        print("[NoteService] Decoding Error: \(error.localizedDescription)")
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("[NoteService] Raw Response JSON: \(jsonString)")
                        }
                        completion(.failure(error))
                    }
                } else {
                    print("[NoteService] No data received or data is empty for successful response.")
                    completion(.failure(NoteError.noData))
                }
            } else {
                let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown server error"
                completion(.failure(NoteError.server(message)))
            }
        }.resume()
    }

    func updateNote(noteId: UUID, categoryType: String, text: String, triggerId: UUID, triggerValue: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/note/\(noteId)/update") else {
            completion(.failure(NoteError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.getCurrentToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            completion(.failure(NoteError.noAuthToken))
            return
        }
        let body: [String: Any] = [
            "categoryType": categoryType,
            "text": text,
            "triggerId": triggerId.uuidString,
            "triggerValue": triggerValue
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NoteError.invalidResponse))
                return
            }
            if (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown server error"
                completion(.failure(NoteError.server(message)))
            }
        }.resume()
    }

    enum NoteError: LocalizedError {
        case invalidURL
        case invalidResponse
        case noAuthToken
        case noData
        case server(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Некорректный URL запроса."
            case .invalidResponse: return "Некорректный ответ сервера."
            case .noAuthToken: return "Отсутствует токен авторизации. Пожалуйста, войдите в систему."
            case .noData: return "Ответ сервера не содержит данных."
            case .server(let message): return "Ошибка сервера: \(message)"
            }
        }
    }
} 
