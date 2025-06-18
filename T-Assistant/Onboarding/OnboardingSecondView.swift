//
//  OnboardingSecondView.swift
//  T-Assistant
//
//  Created by Богдан Тарченко on 16.06.2025.
//

import SwiftUI

struct OnboardingSecondView: View {
    @StateObject var viewModel: OnboardingViewModel
    
    var body: some View {
        Spacer()
        
        VStack(spacing: 56) {
            Image("LogoSec")
                .accessibilityLabel("Иллюстрация функции чтения речи")
            
            VStack(spacing: 16) {
                Text("Интегрируйте напоминания с календарем")
                    .onboardTitleStyle()
                    .multilineTextAlignment(.center)
                Text("Добавьте напоминания в календарь, чтобы точно не пропустить что-то важное.")
                    .textBodyStyle()
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
        
        Spacer()
        
        VStack(spacing: 0) {
            OnboardingContinueButton(action: {
                viewModel.didTapSecondContinueButton()
            }, title: "Далее")
            
            OnboardingSkipButton(action: {
                viewModel.didTapSkipButton()
            })
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    OnboardingSecondView(viewModel: OnboardingViewModel())
}
