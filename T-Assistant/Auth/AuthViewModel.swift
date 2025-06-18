import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var token: String? = nil
    
    init() {
        if let savedToken = UserDefaults.standard.string(forKey: "authToken3") {
            self.token = savedToken
            self.isAuthorized = true
        } else {
            self.isAuthorized = false
        }
    }
    
    func setToken(_ token: String) {
        self.token = token
        UserDefaults.standard.set(token, forKey: "authToken3")
        isAuthorized = true
    }
    
    func logout() {
        self.token = nil
        UserDefaults.standard.removeObject(forKey: "authToken3")
        isAuthorized = false
    }
} 
