//
//  ChatViewModel.swift
//  T-Assistant
//
//  Created by Богдан Тарченко on 17.06.2025.
//

import Foundation
import SwiftUI
import Combine
import Speech
import AVFoundation

struct Message: Identifiable {
    let id = UUID()
    let timestamp: Date
    let isUser: Bool
    var senderName: String?
    var text: String?
    var noteData: NoteData?

    init(text: String, isUser: Bool, timestamp: Date, senderName: String? = nil) {
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
        self.senderName = senderName
        self.noteData = nil
    }

    init(noteData: NoteData, isUser: Bool, timestamp: Date, senderName: String? = nil) {
        self.noteData = noteData
        self.isUser = isUser
        self.timestamp = timestamp
        self.senderName = senderName
        self.text = nil
    }
}

struct NoteData: Identifiable, Decodable {
    let id: UUID
    let text: String
    let categoryType: String
    let triggers: [Trigger]

    struct Trigger: Identifiable, Decodable {
        let id: UUID
        let triggerType: String
        let isReady: Bool
        let time: Date?
        let location: String?

        enum CodingKeys: String, CodingKey {
            case id, triggerType, isReady, time, location
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let idString = try container.decode(String.self, forKey: .id)
            guard let uuid = UUID(uuidString: idString) else {
                throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid UUID string for Trigger.")
            }
            self.id = uuid
            self.triggerType = try container.decode(String.self, forKey: .triggerType)
            self.isReady = try container.decode(Bool.self, forKey: .isReady)
            
            let dateFormatter = ISO8601DateFormatter()
            if let timeString = try container.decodeIfPresent(String.self, forKey: .time) {
                if let date = dateFormatter.date(from: timeString) {
                    self.time = date
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .time, in: container, debugDescription: "Invalid date format for Trigger time.")
                }
            } else {
                self.time = nil
            }
            
            self.location = try container.decodeIfPresent(String.self, forKey: .location)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, text, categoryType, triggers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idString = try container.decode(String.self, forKey: .id)
        guard let uuid = UUID(uuidString: idString) else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid UUID string for NoteData.")
        }
        self.id = uuid
        self.text = try container.decode(String.self, forKey: .text)
        self.categoryType = try container.decode(String.self, forKey: .categoryType)
        self.triggers = try container.decode([Trigger].self, forKey: .triggers)
    }
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var message: String = ""
    @Published var messages: [Message] = []
    
    @Published var isMicrophoneEnabled: Bool = false
    
    @Published var quickPhrases: [String] = [
        "Напомни мне о задаче позже",
        "Составь список дел на сегодня",
        "Покажи мои встречи на сегодня",
        "Добавь событие в календарь",
        "Расскажи интересный факт",
        "Поставь будильник на 8:00",
        "Сделай заметку: Позвонить клиенту",
        "Какая сейчас погода?",
        "Включи расслабляющую музыку",
        "Сгенерируй идею для поста",
        "Помоги с переводом текста",
        "Напомни выпить воды",
        "Что нового в мире технологий?",
        "Сделай расчет расходов за месяц"
    ]
    
    // MARK: - Speech Recognition Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    init() {
        requestSpeechAuthorization()
    }

    // MARK: - Speech Recognition Methods

    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("User denied speech recognition permission")
                case .restricted:
                    print("Speech recognition restricted on this device")
                case .notDetermined:
                    print("Speech recognition not yet authorized")
                @unknown default:
                    fatalError("Unknown authorization status for speech recognition")
                }
            }
        }
    }

    func startRecording() {
        guard speechRecognizer?.isAvailable ?? false else {
            print("Speech recognizer not available.")
            return
        }

        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error setting up audio session: \(error.localizedDescription)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false

            if let result = result {
                self.message = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isMicrophoneEnabled = false
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            self.isMicrophoneEnabled = true
            self.message = ""
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
            self.isMicrophoneEnabled = false
        }
    }

    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        self.isMicrophoneEnabled = false
    }
    
    func sendMessage() {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let userMessageText = message
        let newMessage = Message(text: userMessageText, isUser: true, timestamp: Date())
        messages.append(newMessage)
        message = ""
        
        NoteService.shared.processText(userMessageText) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let noteData):
                    let aiMessage = Message(noteData: noteData, isUser: false, timestamp: Date(), senderName: "AI")
                    self.messages.append(aiMessage)
                case .failure(let error):
                    let errorMessage = Message(text: error.localizedDescription, isUser: false, timestamp: Date(), senderName: "AI")
                    self.messages.append(errorMessage)
                    print("Error processing text: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func insertQuickPhraseText(_ text: String) {
        message = text
    }
}
