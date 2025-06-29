//
//  FontModificators.swift
//  T-Assistant
//
//  Created by Богдан Тарченко on 16.06.2025.
//

import SwiftUI

extension Font {

    static let onboardTitle = Font.system(size: 32, weight: .black)
    static let textBody = Font.system(size: 20, weight: .regular)
    static let bodyMedium = Font.system(size: 20, weight: .medium)
}

extension View {
    func onboardTitleStyle() -> some View {
        self.font(.onboardTitle)
            .minimumScaleFactor(0.7)
    }
    
    func textBodyStyle() -> some View {
        self.font(.textBody)
            .minimumScaleFactor(0.75)
    }
    
    func bodyMediumStyle() -> some View {
        self.font(.bodyMedium)
            .minimumScaleFactor(0.7)
    }
}
