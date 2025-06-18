//
//  ChatViewScreen.swift
//  T-Assistant
//
//  Created by Богдан Тарченко on 16.06.2025.
//

import SwiftUI

struct ChatViewScreen: View {
    @StateObject private var viewModel = ChatViewModel()
    
    @State private var showPhrasesTable = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Color(red: 230/255, green: 235/255, blue: 241/255)
                    .ignoresSafeArea(edges: .bottom)
                ChatMessagesView(messages: viewModel.messages)
            }
            bottomInputBar
            if showPhrasesTable {
                PhrasesGridView(
                    phrases: viewModel.quickPhrases,
                    onPhraseTap: { tappedText in
                        viewModel.insertQuickPhraseText(tappedText)
                        showPhrasesTable = false
                    }
                )
            }
        }
    }
}

extension ChatViewScreen {
    private var bottomInputBar: some View {
        HStack(spacing: 8) {
            Button(action: {
                showPhrasesTable.toggle()
            }) {
                Image("list")
                    .padding(.leading, 12)
            }

            
            TextField("Сообщение...", text: $viewModel.message)
                .accessibilityLabel("Поле ввода сообщения")
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .font(.system(size: 20, weight: .regular))
                .background(Color("bgminor"))
                .clipShape(RoundedRectangle(cornerRadius: 48))
            
            Group {
                if viewModel.message.isEmpty || viewModel.isMicrophoneEnabled {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(Color("action")))
                            .clipShape(Circle())
                            .scaleEffect(viewModel.isMicrophoneEnabled ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isMicrophoneEnabled)
                    }
                    .buttonStyle(.plain)
                    .onLongPressGesture(minimumDuration: 0, pressing: { isPressing in
                        viewModel.isMicrophoneEnabled = isPressing
                        if isPressing {
                            viewModel.startRecording()
                        } else {
                            viewModel.stopRecording()
                        }
                    }, perform: {})
                } else {
                    Button(action: {
                        viewModel.sendMessage()
                    }) {
                        Image("sendIcon")
                            .padding(12)
                            .background(Color("action"))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

#Preview {
    ChatViewScreen()
}
