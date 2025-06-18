//
//  RegistrationView.swift
//  T-Assistant
//
//  Created by Богдан Тарченко on 17.06.2025.
//

import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var fullName = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Регистрация")
                .font(.largeTitle)
                .bold()
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            TextField("Имя и фамилия", text: $fullName)
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
            Button(action: register) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Зарегистрироваться")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("action"))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
            }
            .disabled(isLoading)
            Button("Уже есть аккаунт? Войти") {
                dismiss()
            }
            .padding(.top)
        }
        .padding()
    }
    
    private func register() {
        errorMessage = nil
        isLoading = true
        AuthService.shared.register(email: email, fullName: fullName, password: password) { result in
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
    RegistrationView()
}
