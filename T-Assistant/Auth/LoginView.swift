//
//  LoginView.swift
//  T-Assistant
//
//  Created by Богдан Тарченко on 17.06.2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showRegistration = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Вход")
                .font(.largeTitle)
                .bold()
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            SecureField("Пароль", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            Button(action: login) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Войти")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("action"))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
            }
            .disabled(isLoading)
            Button("Нет аккаунта? Зарегистрироваться") {
                showRegistration = true
            }
            .padding(.top)
        }
        .padding()
        .sheet(isPresented: $showRegistration) {
            RegistrationView()
                .environmentObject(authViewModel)
        }
    }
    
    private func login() {
        errorMessage = nil
        isLoading = true
        AuthService.shared.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let token):
                    authViewModel.setToken(token)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
