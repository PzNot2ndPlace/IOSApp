//
//  OnboardingFirstView.swift
//  T-Assistant
//
//  Created by Богдан Тарченко on 16.06.2025.
//

import SwiftUI

struct OnboardingFirstView: View {
    @StateObject var viewModel: OnboardingViewModel
    
    var body: some View {
        Spacer()
        
        VStack(spacing: 56) {
            Image("logoFirst")
                .accessibilityLabel("Логотип приложения T-Assistant")
            
            VStack(spacing: 16) {
                Text("Создавайте напоминания с помощью голоса")
                    .onboardTitleStyle()
                    .multilineTextAlignment(.center)
                Text("Управляйте приложением с помощью голоса или текста. Ассистент автоматически сгенерирует подходящее напоминание.")
                    .textBodyStyle()
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
        
        Spacer()
        
        VStack(spacing: 0) {
            OnboardingContinueButton(action: {
                viewModel.didTapFirstContinueButton()
            }, title: "Далее")
            
            OnboardingSkipButton(action: {
                viewModel.didTapSkipButton()
            })
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    OnboardingFirstView(viewModel: OnboardingViewModel())
}
