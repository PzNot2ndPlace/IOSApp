//
//  PhrasesGridView.swift
//  T-Assistant
//
//  Created by Богдан Тарченко on 17.06.2025.
//


import SwiftUI

struct PhrasesGridView: View {
    let phrases: [String]
    let onPhraseTap: (String) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var content: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(phrases, id: \ .self) { phrase in
                phraseCard(text: phrase)
            }
        }
    }
    
    @ViewBuilder
    private func phraseCard(text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .onTapGesture {
                onPhraseTap(text)
            }
            .accessibilityLabel(text)
            .accessibilityAddTraits(.isButton)
    }
}

struct PhrasesGridView_Previews: PreviewProvider {
    static var previews: some View {
        PhrasesGridView(
            phrases: [
                "Привет!",
                "Как дела?",
                "Спасибо!",
                "Отправить отчет",
                "Позвонить позже",
                "Я занят, напишу позже"
            ],
            onPhraseTap: { phrase in print(phrase) }
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
