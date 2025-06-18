//
//  OnboardingAction.swift
//  T-Assistant
//
//  Created by Богдан Тарченко on 16.06.2025.
//

import Foundation
import SwiftUI
import Combine

enum OnboardingAction {
    case didTapFirstContinue
    case didTapSecondContinue
    case didTapStart
    case didTapSkip
}

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var requestedAction: OnboardingAction?

    func didTapFirstContinueButton() {
        requestedAction = .didTapFirstContinue
    }

    func didTapSecondContinueButton() {
        requestedAction = .didTapSecondContinue
    }

    func didTapStartButton() {
        requestedAction = .didTapStart
    }

    func didTapSkipButton() {
        requestedAction = .didTapSkip
    }
}
